/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class OpenInPlaceUploadTests: XCTestCase {
    private var base: URL!
    private var outside: URL!
    private var store: SecureFileStore!

    override func setUp() {
        MockUploadURLProtocol.reset()
        base = FileTestSupport.makeDirectory()
        outside = FileTestSupport.makeDirectory()
        store = SecureFileStore(baseDirectory: base)
    }

    override func tearDown() {
        MockUploadURLProtocol.reset()
        try? FileManager.default.removeItem(at: base)
        try? FileManager.default.removeItem(at: outside)
    }

    private func storedFiles() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: store.directory, includingPropertiesForKeys: nil)) ?? []
    }

    private func run(_ files: [PickedFile]) -> [FileUploadOutcome] {
        let apiClient = APIClient(vaultID: "vault123", vaultURL: "https://vault.example.org/",
                                  tokenProvider: StaticTokenProvider())
        let uploader = FileUploader(apiClient: apiClient, session: FileTestSupport.makeSession(), store: store,
                                    contextOptions: ContextOptions())
        let jobs = files.map {
            FileUploadJob(file: $0, table: "docs", column: "file", skyflowID: nil,
                          preserveFileName: true, returnFileMetadata: false)
        }
        let done = expectation(description: "upload")
        var outcomes: [FileUploadOutcome] = []
        uploader.upload(jobs, onTokenFailure: { _ in XCTFail("token") }, completion: {
            outcomes = $0
            done.fulfill()
        })
        wait(for: [done], timeout: 5)
        return outcomes
    }

    func testUploadReadsTheOriginalAndLeavesItInPlace() {
        MockUploadURLProtocol.handler = { _, _ in FileTestSupport.jsonResponse(200, ["skyflow_id": "id-1"]) }
        let source = outside.appendingPathComponent("scan.pdf")
        try! Data("original-bytes".utf8).write(to: source)
        let file = SystemFilePicker.openInPlace(source)!

        let outcomes = run([file])

        guard case .success = outcomes.first else { return XCTFail("expected success") }
        let body = String(decoding: MockUploadURLProtocol.bodies[0], as: UTF8.self)
        XCTAssertTrue(body.contains("filename=\"scan.pdf\""))
        XCTAssertTrue(body.contains("\r\n\r\noriginal-bytes\r\n--"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path), "the user's file is never deleted")
        XCTAssertTrue(storedFiles().isEmpty, "request body removed after upload")
    }

    func testChangedOrDeletedOriginalFailsOnlyThatFile() {
        MockUploadURLProtocol.handler = { _, _ in FileTestSupport.jsonResponse(200, ["skyflow_id": "id-2"]) }
        let changed = FileTestSupport.writeFile(named: "changed.pdf", bytes: 10, in: outside)
        let deleted = FileTestSupport.writeFile(named: "deleted.pdf", bytes: 10, in: outside)
        let kept = FileTestSupport.writeFile(named: "kept.pdf", bytes: 10, in: outside)
        let files = [changed, deleted, kept].compactMap(SystemFilePicker.openInPlace)
        try! Data(count: 99).write(to: changed)
        try! FileManager.default.removeItem(at: deleted)

        let outcomes = run(files)

        guard case .failure = outcomes[0], case .failure = outcomes[1], case .success = outcomes[2] else {
            return XCTFail("expected failure, failure, success")
        }
        XCTAssertEqual(MockUploadURLProtocol.requests.count, 1)
        XCTAssertTrue(storedFiles().isEmpty)
    }
}
