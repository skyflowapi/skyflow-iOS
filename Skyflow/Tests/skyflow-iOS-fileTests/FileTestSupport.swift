/*
 * Copyright (c) 2022 Skyflow
*/

import UIKit
import XCTest
@testable import Skyflow
@testable import SkyflowCore

enum FileTestSupport {
    static func makeDirectory(_ name: String = UUID().uuidString) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("skyflow-file-tests", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func writeFile(named name: String, bytes: Int, in directory: URL) -> URL {
        let url = directory.appendingPathComponent(name)
        let data = Data((0..<bytes).map { UInt8(truncatingIfNeeded: $0) })
        FileManager.default.createFile(atPath: url.path, contents: data)
        return url
    }

    /// A PickedFile whose URL does not need to exist (validation only looks at metadata).
    static func picked(_ name: String, size: Int = 1_000) -> PickedFile {
        PickedFile(url: URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString)"), name: name, size: size)
    }

    static func configuration(type: FileElementType = .FILE_INPUT,
                              table: String = "documents",
                              column: String = "file",
                              skyflowID: String? = nil,
                              options: FileElementOptions = FileElementOptions()) -> FileElementConfiguration {
        let input = FileElementInput(table: table, column: column, type: type, skyflowID: skyflowID)
        switch FileElementConfiguration.make(input: input, options: options) {
        case .success(let configuration): return configuration
        case .failure(let error): fatalError("Invalid test configuration: \(error)")
        }
    }

    /// A JWT whose payload has an `exp` one hour ahead, so APIClient accepts it.
    static func validToken(_ marker: String = "a") -> String {
        let payload = "{\"exp\":\(Int(Date().timeIntervalSince1970) + 3600),\"m\":\"\(marker)\"}"
        let encoded = Data(payload.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        return "eyJhbGciOiJub25lIn0.\(encoded).signature"
    }

    static func makeClient(vaultURL: String = "https://vault.example.org", tokenProvider: TokenProvider = StaticTokenProvider()) -> Client {
        Client(Configuration(vaultID: "vault123", vaultURL: vaultURL, tokenProvider: tokenProvider, options: Options(logLevel: .ERROR)))
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockUploadURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func jsonResponse(_ status: Int, _ body: Any, headers: [String: String] = [:]) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(url: URL(string: "https://vault.example.org")!, statusCode: status, httpVersion: nil, headerFields: headers)!
        return (response, try! JSONSerialization.data(withJSONObject: body))
    }
}

final class StaticTokenProvider: TokenProvider {
    private(set) var calls = 0
    var tokens: [String]
    var failure: Any?

    init(tokens: [String] = [FileTestSupport.validToken()], failure: Any? = nil) {
        self.tokens = tokens
        self.failure = failure
    }

    func getBearerToken(_ apiCallback: Callback) {
        calls += 1
        if let failure = failure {
            apiCallback.onFailure(failure)
            return
        }
        apiCallback.onSuccess(tokens[min(calls - 1, tokens.count - 1)])
    }
}

final class SpyCallback: Callback {
    private let expectation: XCTestExpectation
    private(set) var success: Any?
    private(set) var failure: Any?

    init(_ expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func onSuccess(_ responseBody: Any) {
        success = responseBody
        expectation.fulfill()
    }

    func onFailure(_ error: Any) {
        failure = error
        expectation.fulfill()
    }

    var failureMessage: String? {
        (failure as? NSError)?.localizedDescription
    }
}

final class FakePicker: FilePicking {
    private(set) var requests: [(source: FileSource, selectionLimit: Int)] = []
    private var pending: ((FilePickResult) -> Void)?
    var unavailableSources: Set<FileSource> = []

    func isAvailable(_ source: FileSource) -> Bool {
        unavailableSources.contains(source) == false
    }

    func pick(from source: FileSource, presenter: UIViewController, configuration: FileElementConfiguration,
              selectionLimit: Int, completion: @escaping (FilePickResult) -> Void) {
        requests.append((source, selectionLimit))
        pending = completion
    }

    func complete(_ result: FilePickResult) {
        pending?(result)
        pending = nil
    }
}

/// Records every request and answers from `handler`. Upload tasks reach URLProtocol with
/// their body as `httpBodyStream`, which is collected into `bodies`.
final class MockUploadURLProtocol: URLProtocol {
    static var handler: ((URLRequest, Data) throws -> (HTTPURLResponse, Data))?
    /// Answer asynchronously after this delay, so several requests can be in flight at once.
    static var responseDelay: TimeInterval = 0
    private static let lock = NSLock()
    private static var inFlight = 0
    private static var _peakInFlight = 0
    private static var _requests: [URLRequest] = []
    private static var _bodies: [Data] = []

    static var requests: [URLRequest] { lock.lock(); defer { lock.unlock() }; return _requests }
    static var bodies: [Data] { lock.lock(); defer { lock.unlock() }; return _bodies }
    static var peakInFlight: Int { lock.lock(); defer { lock.unlock() }; return _peakInFlight }

    static func reset() {
        lock.lock()
        _requests = []
        _bodies = []
        inFlight = 0
        _peakInFlight = 0
        handler = nil
        responseDelay = 0
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = Self.readBody(request)
        Self.lock.lock()
        Self._requests.append(request)
        Self._bodies.append(body)
        Self.inFlight += 1
        Self._peakInFlight = max(Self._peakInFlight, Self.inFlight)
        Self.lock.unlock()
        guard Self.responseDelay > 0 else {
            respond(body: body)
            return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + Self.responseDelay) { self.respond(body: body) }
    }

    private func respond(body: Data) {
        defer {
            Self.lock.lock()
            Self.inFlight -= 1
            Self.lock.unlock()
        }
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request, body)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func readBody(_ request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}

final class FakeCameraAccess: CameraAccess {
    var hasUsageDescription = true
    var isCameraAvailable = true
    var authorization: CameraAuthorization = .authorized
    /// Answer given to requestAccess; nil leaves the request pending.
    var grantOnRequest: Bool? = true
    private(set) var accessRequests = 0

    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        accessRequests += 1
        guard let grant = grantOnRequest else { return }
        // The system answers on a background queue.
        DispatchQueue.global().async { completion(grant) }
    }
}
