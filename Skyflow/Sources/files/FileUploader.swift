/*
 * Copyright (c) 2022 Skyflow
*/

// Uploads picked files to POST {vaultURL}/v2/vaults/{vaultID}/files/upload, one multipart
// request per file (same wire contract as skyflow-js).
//
// All state is confined to the main queue: URLSession and token callbacks hop back to it
// before touching anything, so APIClient.token is never written from two threads.

import Foundation

internal struct FileUploadJob {
    let file: PickedFile
    let table: String
    let column: String
    let skyflowID: String?
    let preserveFileName: Bool
    let returnFileMetadata: Bool

    // Random name keeps the original (often personal) name out of the vault; the extension is
    // kept so the server can still infer the type.
    var uploadFileName: String {
        if preserveFileName { return file.name }
        let ext = file.fileExtension
        return ext.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(ext)"
    }

    var formFields: [(name: String, value: String)] {
        var fields: [(name: String, value: String)] = [("tableName", table), ("columnName", column)]
        if let skyflowID = skyflowID { fields.append(("skyflowID", skyflowID)) }
        if returnFileMetadata { fields.append(("returnFileMetadata", "true")) }
        return fields
    }
}

internal enum FileUploadOutcome {
    case success([String: Any])
    case failure([String: Any])
}

internal final class FileUploader {
    static let maxConcurrentUploads = 3

    private let apiClient: APIClient
    private let session: URLSession
    private let store: SecureFileStore
    private let contextOptions: ContextOptions
    private let photoLibrary: PhotoAssetLibrary
    private var pendingTokenRequests: [(Result<String, AnyError>) -> Void] = []

    struct AnyError: Error {
        let value: Any
    }

    init(apiClient: APIClient, session: URLSession, store: SecureFileStore, contextOptions: ContextOptions,
         photoLibrary: PhotoAssetLibrary = SystemPhotoAssetLibrary()) {
        self.apiClient = apiClient
        self.session = session
        self.store = store
        self.contextOptions = contextOptions
        self.photoLibrary = photoLibrary
    }

    /// Uploads every job, at most `maxConcurrentUploads` at a time, and reports outcomes in job
    /// order. If the first bearer token cannot be obtained nothing is sent and `onTokenFailure`
    /// receives the token provider's error unchanged. Must be called on the main queue.
    func upload(_ jobs: [FileUploadJob],
                onTokenFailure: @escaping (Any) -> Void,
                completion: @escaping ([FileUploadOutcome]) -> Void) {
        guard jobs.isEmpty == false else {
            completion([])
            return
        }
        requestToken { [self] result in
            switch result {
            case .failure(let error):
                onTokenFailure(error.value)
            case .success:
                run(jobs, completion: completion)
            }
        }
    }

    private func run(_ jobs: [FileUploadJob], completion: @escaping ([FileUploadOutcome]) -> Void) {
        var outcomes = [FileUploadOutcome?](repeating: nil, count: jobs.count)
        var nextIndex = 0
        var finished = 0

        func startNext() {
            guard nextIndex < jobs.count else { return }
            let index = nextIndex
            nextIndex += 1
            uploadOne(jobs[index]) { outcome in
                outcomes[index] = outcome
                finished += 1
                if finished == jobs.count {
                    completion(outcomes.compactMap { $0 })
                } else {
                    startNext()
                }
            }
        }

        for _ in 0..<min(Self.maxConcurrentUploads, jobs.count) {
            startNext()
        }
    }

    private func uploadOne(_ job: FileUploadJob, completion: @escaping (FileUploadOutcome) -> Void) {
        guard let url = URL(string: apiClient.vaultURL + "v2/vaults/" + apiClient.vaultID + "/files/upload") else {
            completion(.failure(Self.errorEntry(code: 400, message: ErrorCodes.INVALID_URL().description)))
            return
        }
        let writer = MultipartFormWriter()
        makeBody(for: job, writer: writer) { [self] result in
            switch result {
            case .failure:
                completion(.failure(Self.errorEntry(code: 400, message: "Failed to read the selected file.")))
            case .success(let body):
                send(body: body, url: url, contentType: writer.contentType, retryOnUnauthorized: true) { [store] outcome in
                    store.remove(body)
                    completion(outcome)
                }
            }
        }
    }

    // Writes the request body to a store file and calls back on the main queue. A library photo
    // is streamed from Photos into the body, so it exists on disk only while it is uploaded.
    private func makeBody(for job: FileUploadJob, writer: MultipartFormWriter,
                          completion: @escaping (Result<URL, Error>) -> Void) {
        let mimeType = job.file.mimeType ?? "application/octet-stream"
        let body: URL
        do {
            body = try store.makeEmptyFile(pathExtension: "multipart")
        } catch {
            completion(.failure(error))
            return
        }
        guard let assetID = job.file.photoAssetID else {
            do {
                try Self.readSource(of: job.file) { source in
                    try writer.write(fields: job.formFields,
                                     file: .init(fieldName: "file", fileName: job.uploadFileName, mimeType: mimeType,
                                                 source: source),
                                     to: body)
                }
                completion(.success(body))
            } catch {
                store.remove(body)
                completion(.failure(error))
            }
            return
        }

        let handle: FileHandle
        do {
            handle = try FileHandle(forWritingTo: body)
            try writer.writeHead(fields: job.formFields, fieldName: "file", fileName: job.uploadFileName,
                                 mimeType: mimeType, to: handle)
        } catch {
            store.remove(body)
            completion(.failure(error))
            return
        }
        photoLibrary.streamData(forAssetID: assetID, onChunk: { chunk in
            try MultipartFormWriter.append(chunk, to: handle)
        }, completion: { [store] error in
            let result: Result<URL, Error>
            do {
                if let error = error { throw error }
                try writer.writeTail(to: handle)
                result = .success(body)
            } catch {
                result = .failure(error)
            }
            try? handle.close()
            DispatchQueue.main.async {
                if case .failure = result { store.remove(body) }
                completion(result)
            }
        })
    }

    // A document opened in place can be edited, replaced or deleted between pick and upload. It
    // was validated at its picked size, so any other size fails that file instead of uploading
    // content that was never checked.
    static func readSource(of file: PickedFile, _ body: (URL) throws -> Void) throws {
        guard file.isOpenInPlace else {
            try body(file.url)
            return
        }
        try SecurityScopedAccess.coordinatedRead(file.url) { source in
            var current = source
            current.removeAllCachedResourceValues()
            guard try current.resourceValues(forKeys: [.fileSizeKey]).fileSize == file.size else {
                throw CocoaError(.fileReadCorruptFile)
            }
            try body(source)
        }
    }

    private func send(body: URL, url: URL, contentType: String, retryOnUnauthorized: Bool,
                      completion: @escaping (FileUploadOutcome) -> Void) {
        let usedToken = apiClient.token
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer " + usedToken, forHTTPHeaderField: "Authorization")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(FetchMetrices().buildMetadataHeaderValue(sdkName: contextOptions.sdkName), forHTTPHeaderField: "sky-metadata")

        let task = session.uploadTask(with: request, fromFile: body) { data, response, error in
            DispatchQueue.main.async { [self] in
                let status = (response as? HTTPURLResponse)?.statusCode
                guard status == 401, retryOnUnauthorized else {
                    completion(Self.outcome(data: data, response: response, error: error))
                    return
                }
                refreshToken(replacing: usedToken) { result in
                    guard case .success = result else {
                        completion(Self.outcome(data: data, response: response, error: error))
                        return
                    }
                    self.send(body: body, url: url, contentType: contentType, retryOnUnauthorized: false, completion: completion)
                }
            }
        }
        task.resume()
    }

    // Called after a 401. Several uploads can be rejected with the same expired token; only the
    // first starts a refresh. A request that was sent before a refresh finished retries with the
    // already-refreshed token instead of refreshing again.
    private func refreshToken(replacing staleToken: String, completion: @escaping (Result<String, AnyError>) -> Void) {
        if pendingTokenRequests.isEmpty {
            if apiClient.token != staleToken, apiClient.isTokenValid() {
                completion(.success(apiClient.token))
                return
            }
            apiClient.token = ""
        }
        requestToken(completion)
    }

    // Coalesces concurrent requests into one call to the token provider.
    private func requestToken(_ completion: @escaping (Result<String, AnyError>) -> Void) {
        pendingTokenRequests.append(completion)
        guard pendingTokenRequests.count == 1 else { return }
        apiClient.getAccessToken(callback: TokenCallback { [self] result in
            DispatchQueue.main.async {
                let waiters = self.pendingTokenRequests
                self.pendingTokenRequests.removeAll()
                waiters.forEach { $0(result) }
            }
        }, contextOptions: contextOptions)
    }

    static func outcome(data: Data?, response: URLResponse?, error: Error?) -> FileUploadOutcome {
        if let error = error {
            return .failure(errorEntry(code: (error as NSError).code, message: error.localizedDescription))
        }
        guard let http = response as? HTTPURLResponse else {
            return .failure(errorEntry(code: 500, message: "Unknown error"))
        }
        let json = data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
        if (200...299).contains(http.statusCode), let json = json {
            return .success(json)
        }
        var message = (json?["error"] as? [String: Any])?["message"] as? String
            ?? "File upload failed with status code \(http.statusCode)"
        if let requestID = http.value(forHTTPHeaderField: "x-request-id") {
            message += " - request-id: \(requestID)"
        }
        return .failure(errorEntry(code: http.statusCode, message: message))
    }

    static func errorEntry(code: Int, message: String) -> [String: Any] {
        ["error": ["code": code, "message": message]]
    }
}

private final class TokenCallback: Callback {
    private let completion: (Result<String, FileUploader.AnyError>) -> Void

    init(_ completion: @escaping (Result<String, FileUploader.AnyError>) -> Void) {
        self.completion = completion
    }

    func onSuccess(_ responseBody: Any) {
        if let token = responseBody as? String {
            completion(.success(token))
        } else {
            completion(.failure(.init(value: responseBody)))
        }
    }

    func onFailure(_ error: Any) {
        completion(.failure(.init(value: error)))
    }
}
