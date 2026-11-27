/*
 * Copyright (c) 2022 Skyflow
*/

import UIKit
import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class FileUploadOperationsTests: XCTestCase {
    private var window: UIWindow!
    private var outside: URL!
    private var bodyStore: SecureFileStore!
    private var bodyBase: URL!

    override func setUp() {
        MockUploadURLProtocol.reset()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        outside = FileTestSupport.makeDirectory()
        bodyBase = FileTestSupport.makeDirectory()
        bodyStore = SecureFileStore(baseDirectory: bodyBase)
    }

    override func tearDown() {
        MockUploadURLProtocol.reset()
        SecureFileStore.shared.removeAll()
        try? FileManager.default.removeItem(at: outside)
        try? FileManager.default.removeItem(at: bodyBase)
        window = nil
    }

    // MARK: - Helpers

    private func makeContainer(_ client: Client = FileTestSupport.makeClient()) -> Container<CollectContainer> {
        client.container(type: ContainerType.COLLECT)!
    }

    @discardableResult
    private func addElement(to container: Container<CollectContainer>, column: String = "file",
                            type: FileElementType = .FILE_INPUT, options: CollectElementOptions = CollectElementOptions(),
                            files names: [String] = [], mounted: Bool = true) -> FileInputElement {
        let element = container.create(fileInput: CollectElementInput(table: "docs", column: column, type: type), options: options)
        if mounted { window.addSubview(element) }
        let files = names.map { name -> PickedFile in
            let url = try! SecureFileStore.shared.importFile(from: FileTestSupport.writeFile(named: name, bytes: 16, in: outside), move: true)
            return PickedFile(url: url, name: name, size: 16)
        }
        if files.isEmpty == false {
            element.handle(FilePickResult(files: files))
        }
        return element
    }

    private func upload(_ container: Container<CollectContainer>, timeout: TimeInterval = 5) -> SpyCallback {
        let expectation = expectation(description: "uploadFiles")
        let callback = SpyCallback(expectation)
        container.uploadFiles(callback: callback, session: FileTestSupport.makeSession(), store: bodyStore)
        wait(for: [expectation], timeout: timeout)
        return callback
    }

    private func bodyText(_ index: Int) -> String {
        String(data: MockUploadURLProtocol.bodies[index], encoding: .utf8) ?? ""
    }

    /// Answers each upload with a skyflow_id derived from the uploaded file name.
    private func respondWithIDsFromFileName(failing: Set<String> = [], status: Int = 500) {
        MockUploadURLProtocol.handler = { _, bodyData in
            let body = String(data: bodyData, encoding: .utf8) ?? ""
            let name = body.components(separatedBy: "filename=\"").dropFirst().first?.components(separatedBy: "\"").first ?? "?"
            if failing.contains(name) {
                return FileTestSupport.jsonResponse(status, ["error": ["message": "failed \(name)"]])
            }
            return FileTestSupport.jsonResponse(200, ["skyflow_id": "id-\(name)"])
        }
    }

    // MARK: - create()

    func testCreateRegistersFileElementWithoutAffectingCollect() {
        let container = makeContainer()

        let element = container.create(fileInput: CollectElementInput(table: "docs", column: "file", type: .FILE_INPUT))

        XCTAssertEqual(container.fileElements.count, 1)
        XCTAssertTrue(container.fileElements.first === element)
        XCTAssertTrue(container.elements.isEmpty)
    }

    func testAppearanceDefaultsToFieldAndCustomIsPassedThrough() {
        let container = makeContainer()

        let field = container.create(fileInput: CollectElementInput(table: "docs", column: "file", type: .FILE_INPUT))
        let custom = container.create(fileInput: CollectElementInput(table: "docs", column: "file", type: .FILE_INPUT,
                                                                     appearance: .CUSTOM))

        XCTAssertEqual(field.input.appearance, .FIELD)
        XCTAssertTrue(field.fieldView.isDescendant(of: field))
        XCTAssertEqual(custom.input.appearance, .CUSTOM)
        XCTAssertFalse(custom.fieldView.isDescendant(of: custom))
        XCTAssertTrue(custom.fileListStack.isDescendant(of: custom))
    }

    func testCollectElementOptionsCarryFileOptions() {
        let options = CollectElementOptions(required: true, allowedFileType: [".pdf"], blockEmptyFiles: true,
                                            preserveFileName: false, returnFileMetadata: true, maxFileSize: 10,
                                            maxFileCount: 2, sources: [.FILES])

        XCTAssertEqual(options.fileOptions.required, true)
        XCTAssertEqual(options.fileOptions.allowedFileType, [".pdf"])
        XCTAssertEqual(options.fileOptions.blockEmptyFiles, true)
        XCTAssertEqual(options.fileOptions.preserveFileName, false)
        XCTAssertEqual(options.fileOptions.returnFileMetadata, true)
        XCTAssertEqual(options.fileOptions.maxFileSize, 10)
        XCTAssertEqual(options.fileOptions.maxFileCount, 2)
        XCTAssertEqual(options.fileOptions.sources, [.FILES])
    }

    func testTextFieldInputPassedToCreateFileInputFailsAtUpload() {
        let container = makeContainer()
        let element = container.create(fileInput: CollectElementInput(table: "docs", column: "file", type: .CARD_NUMBER))
        window.addSubview(element)

        let callback = upload(container)

        XCTAssertEqual(callback.failureMessage, FileErrorCode.notFileElementType.message)
        XCTAssertTrue(MockUploadURLProtocol.requests.isEmpty)
    }

    // MARK: - Pre-flight failures (nothing sent)

    func testEmptyVaultURLFails() {
        let container = makeContainer(FileTestSupport.makeClient(vaultURL: ""))
        addElement(to: container, files: ["a.pdf"])

        let callback = upload(container)

        XCTAssertEqual(callback.failureMessage, ErrorCodes.EMPTY_VAULT_URL().description)
        XCTAssertTrue(MockUploadURLProtocol.requests.isEmpty)
    }

    func testNoFileElementsFails() {
        let callback = upload(makeContainer())

        XCTAssertEqual(callback.failureMessage, FileErrorCode.noFileElements.message)
    }

    func testInvalidConfigurationFails() {
        let container = makeContainer()
        addElement(to: container, type: .MULTI_FILE_INPUT, options: CollectElementOptions(maxFileCount: 0))

        let callback = upload(container)

        XCTAssertEqual(callback.failureMessage, FileErrorCode.nonPositiveOption(name: "maxFileCount").message)
    }

    func testUnmountedElementFails() {
        let container = makeContainer()
        addElement(to: container, column: "passport", files: ["a.pdf"], mounted: false)

        let callback = upload(container)

        XCTAssertEqual(callback.failureMessage, ErrorCodes.UNMOUNTED_COLLECT_ELEMENT(value: "passport").description)
        XCTAssertTrue(MockUploadURLProtocol.requests.isEmpty)
    }

    func testInvalidElementsAreAllReportedWithoutFileNames() {
        let container = makeContainer()
        let first = addElement(to: container, column: "passport", options: CollectElementOptions(required: true))
        let second = addElement(to: container, column: "license", options: CollectElementOptions(allowedFileType: [".pdf"]),
                                files: ["jane-license.png"])

        let callback = upload(container)

        let message = callback.failureMessage ?? ""
        XCTAssertTrue(message.contains("for passport No File Selected"), message)
        XCTAssertTrue(message.contains("for license Invalid File Type."), message)
        XCTAssertFalse(message.contains("jane"))
        XCTAssertFalse(first.errorLabel.isHidden)
        XCTAssertFalse(second.errorLabel.isHidden)
        XCTAssertTrue(MockUploadURLProtocol.requests.isEmpty)
    }

    func testOptionalEmptyElementsSucceedWithNothingSent() {
        let container = makeContainer()
        addElement(to: container)

        let callback = upload(container)

        let entries = (callback.success as? [String: Any])?["fileUploadResponse"] as? [[String: Any]]
        XCTAssertEqual(entries?.count, 0)
        XCTAssertTrue(MockUploadURLProtocol.requests.isEmpty)
    }

    // MARK: - Uploads

    func testSuccessfulUpload() {
        let token = FileTestSupport.validToken("first")
        let tokenProvider = StaticTokenProvider(tokens: [token])
        let container = makeContainer(FileTestSupport.makeClient(tokenProvider: tokenProvider))
        let single = addElement(to: container, column: "passport", options: CollectElementOptions(returnFileMetadata: true), files: ["p.pdf"])
        let multi = addElement(to: container, column: "attachments", type: .MULTI_FILE_INPUT, files: ["a.pdf", "b.pdf"])
        let copies = (single.files + multi.files).map(\.url)
        respondWithIDsFromFileName()
        var changes = 0
        single.on(eventName: .CHANGE) { _ in changes += 1 }

        let callback = upload(container)

        let entries = (callback.success as? [String: Any])?["fileUploadResponse"] as? [[String: Any]]
        XCTAssertEqual(entries?.compactMap { $0["skyflow_id"] as? String }, ["id-p.pdf", "id-a.pdf", "id-b.pdf"])
        XCTAssertEqual(MockUploadURLProtocol.requests.count, 3)
        XCTAssertEqual(tokenProvider.calls, 1)

        let request = MockUploadURLProtocol.requests[0]
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://vault.example.org/v2/vaults/vault123/files/upload")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer " + token)
        XCTAssertTrue(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
        XCTAssertNotNil(request.value(forHTTPHeaderField: "sky-metadata"))

        let passportBody = (0..<3).map(bodyText).first { $0.contains("p.pdf") } ?? ""
        XCTAssertTrue(passportBody.contains("name=\"tableName\"\r\n\r\ndocs\r\n"))
        XCTAssertTrue(passportBody.contains("name=\"columnName\"\r\n\r\npassport\r\n"))
        XCTAssertTrue(passportBody.contains("name=\"returnFileMetadata\"\r\n\r\ntrue\r\n"))

        // Uploaded files leave their elements and the SDK's copies are deleted.
        XCTAssertTrue(single.files.isEmpty)
        XCTAssertTrue(multi.files.isEmpty)
        XCTAssertEqual(changes, 1)
        XCTAssertTrue(copies.allSatisfy { FileManager.default.fileExists(atPath: $0.path) == false })
        XCTAssertFalse(single.isUploading)
        // Multipart bodies are deleted too.
        let leftovers = (try? FileManager.default.contentsOfDirectory(atPath: bodyStore.directory.path)) ?? []
        XCTAssertTrue(leftovers.isEmpty, "\(leftovers)")
    }

    func testPartialFailureKeepsFailedFilesForRetry() {
        let container = makeContainer()
        let element = addElement(to: container, type: .MULTI_FILE_INPUT, files: ["a.pdf", "b.pdf"])
        respondWithIDsFromFileName(failing: ["b.pdf"])

        let callback = upload(container)

        let failure = callback.failure as? [String: Any]
        XCTAssertEqual((failure?["fileUploadResponse"] as? [[String: Any]])?.count, 1)
        let errors = failure?["errorResponse"] as? [[String: Any]]
        XCTAssertEqual(errors?.count, 1)
        XCTAssertEqual((errors?.first?["error"] as? [String: Any])?["code"] as? Int, 500)
        XCTAssertEqual(element.files.map(\.name), ["b.pdf"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: element.files[0].url.path))
    }

    func testAllFailedReturnsOnlyErrors() {
        let container = makeContainer()
        addElement(to: container, files: ["a.pdf"])
        respondWithIDsFromFileName(failing: ["a.pdf"], status: 400)

        let callback = upload(container)

        let failure = callback.failure as? [String: Any]
        XCTAssertNil(failure?["fileUploadResponse"])
        XCTAssertEqual((failure?["errorResponse"] as? [[String: Any]])?.count, 1)
    }

    func testTokenFailureSendsNothingAndKeepsFiles() {
        let tokenError = NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "token unavailable"])
        let container = makeContainer(FileTestSupport.makeClient(tokenProvider: StaticTokenProvider(failure: tokenError)))
        let element = addElement(to: container, files: ["a.pdf"])

        let callback = upload(container)

        XCTAssertEqual(callback.failureMessage, "token unavailable")
        XCTAssertTrue(MockUploadURLProtocol.requests.isEmpty)
        XCTAssertEqual(element.files.count, 1)
        XCTAssertFalse(element.isUploading)
    }

    func testUnauthorizedRetriesOnceWithFreshToken() {
        let newToken = FileTestSupport.validToken("new")
        let tokenProvider = StaticTokenProvider(tokens: [FileTestSupport.validToken("old"), newToken])
        let container = makeContainer(FileTestSupport.makeClient(tokenProvider: tokenProvider))
        addElement(to: container, files: ["a.pdf"])
        MockUploadURLProtocol.handler = { request, _ in
            request.value(forHTTPHeaderField: "Authorization")?.hasSuffix(newToken) == true
                ? FileTestSupport.jsonResponse(200, ["skyflow_id": "id-1"])
                : FileTestSupport.jsonResponse(401, ["error": ["message": "expired"]])
        }

        let callback = upload(container)

        XCTAssertNotNil(callback.success)
        XCTAssertEqual(tokenProvider.calls, 2)
        XCTAssertEqual(MockUploadURLProtocol.requests.count, 2)
    }

    func testUnauthorizedTwiceFailsWithoutLooping() {
        let tokenProvider = StaticTokenProvider()
        let container = makeContainer(FileTestSupport.makeClient(tokenProvider: tokenProvider))
        addElement(to: container, files: ["a.pdf"])
        MockUploadURLProtocol.handler = { _, _ in FileTestSupport.jsonResponse(401, ["error": ["message": "expired"]]) }

        let callback = upload(container)

        let errors = (callback.failure as? [String: Any])?["errorResponse"] as? [[String: Any]]
        XCTAssertEqual((errors?.first?["error"] as? [String: Any])?["code"] as? Int, 401)
        XCTAssertEqual(MockUploadURLProtocol.requests.count, 2)
        XCTAssertEqual(tokenProvider.calls, 2)
    }

    func testConcurrentUnauthorizedResponsesShareOneRefresh() {
        let newToken = FileTestSupport.validToken("new")
        let tokenProvider = StaticTokenProvider(tokens: [FileTestSupport.validToken("old"), newToken])
        let container = makeContainer(FileTestSupport.makeClient(tokenProvider: tokenProvider))
        addElement(to: container, type: .MULTI_FILE_INPUT, files: ["a.pdf", "b.pdf", "c.pdf"])
        MockUploadURLProtocol.handler = { request, _ in
            request.value(forHTTPHeaderField: "Authorization")?.hasSuffix(newToken) == true
                ? FileTestSupport.jsonResponse(200, ["skyflow_id": "ok"])
                : FileTestSupport.jsonResponse(401, [:])
        }

        let callback = upload(container)

        XCTAssertEqual(((callback.success as? [String: Any])?["fileUploadResponse"] as? [[String: Any]])?.count, 3)
        // One initial fetch plus exactly one refresh, however many uploads were rejected.
        XCTAssertEqual(tokenProvider.calls, 2)
    }

    func testAtMostThreeUploadsInFlight() {
        let container = makeContainer()
        addElement(to: container, type: .MULTI_FILE_INPUT, options: CollectElementOptions(maxFileCount: 6),
                   files: (1...6).map { "f\($0).pdf" })
        MockUploadURLProtocol.responseDelay = 0.2
        MockUploadURLProtocol.handler = { _, _ in FileTestSupport.jsonResponse(200, ["skyflow_id": "ok"]) }

        let callback = upload(container, timeout: 10)

        XCTAssertNotNil(callback.success)
        XCTAssertEqual(MockUploadURLProtocol.requests.count, 6)
        XCTAssertEqual(MockUploadURLProtocol.peakInFlight, FileUploader.maxConcurrentUploads)
    }

    func testSecondCallWhileUploadingIsRejected() {
        let container = makeContainer()
        addElement(to: container, files: ["a.pdf"])
        let release = DispatchSemaphore(value: 0)
        MockUploadURLProtocol.handler = { _, _ in
            release.wait()
            return FileTestSupport.jsonResponse(200, ["skyflow_id": "ok"])
        }
        let firstDone = expectation(description: "first upload")
        let first = SpyCallback(firstDone)
        container.uploadFiles(callback: first, session: FileTestSupport.makeSession(), store: bodyStore)

        let second = upload(container)
        release.signal()
        wait(for: [firstDone], timeout: 5)

        XCTAssertEqual(second.failureMessage, FileErrorCode.uploadInProgress.message)
        XCTAssertNotNil(first.success)
    }

    func testPublicUploadFromBackgroundThreadCompletesOnMain() {
        let container = makeContainer()
        let done = expectation(description: "callback")
        var calledOnMain = false
        final class ThreadCheckingCallback: Callback {
            let onCall: () -> Void
            init(_ onCall: @escaping () -> Void) { self.onCall = onCall }
            func onSuccess(_ responseBody: Any) { onCall() }
            func onFailure(_ error: Any) { onCall() }
        }
        let callback = ThreadCheckingCallback {
            calledOnMain = Thread.isMainThread
            done.fulfill()
        }

        DispatchQueue.global().async {
            container.uploadFiles(callback: callback)
        }

        wait(for: [done], timeout: 5)
        XCTAssertTrue(calledOnMain)
    }
}
