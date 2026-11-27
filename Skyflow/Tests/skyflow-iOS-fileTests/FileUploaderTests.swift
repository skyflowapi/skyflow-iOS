/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class FileUploaderTests: XCTestCase {
    private let url = URL(string: "https://vault.example.org")!

    private func http(_ status: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: headers)!
    }

    private func failureEntry(_ outcome: FileUploadOutcome) -> [String: Any]? {
        if case .failure(let entry) = outcome { return entry["error"] as? [String: Any] }
        return nil
    }

    // MARK: - Response parsing

    func testSuccessReturnsVaultResponse() {
        let data = try! JSONSerialization.data(withJSONObject: ["skyflow_id": "id-1", "fileMetadata": ["fileSize": 3]])

        guard case .success(let entry) = FileUploader.outcome(data: data, response: http(200), error: nil) else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(entry["skyflow_id"] as? String, "id-1")
        XCTAssertNotNil(entry["fileMetadata"])
    }

    func testApiErrorUsesMessageAndRequestID() {
        let data = try! JSONSerialization.data(withJSONObject: ["error": ["message": "Column not found", "http_code": 404]])

        let error = failureEntry(FileUploader.outcome(data: data, response: http(404, headers: ["x-request-id": "req-9"]), error: nil))

        XCTAssertEqual(error?["code"] as? Int, 404)
        XCTAssertEqual(error?["message"] as? String, "Column not found - request-id: req-9")
    }

    func testApiErrorWithoutJSONBody() {
        let error = failureEntry(FileUploader.outcome(data: Data("<html>".utf8), response: http(502), error: nil))

        XCTAssertEqual(error?["code"] as? Int, 502)
        XCTAssertEqual(error?["message"] as? String, "File upload failed with status code 502")
    }

    func testSuccessStatusWithUnreadableBodyIsFailure() {
        let error = failureEntry(FileUploader.outcome(data: Data("ok".utf8), response: http(200), error: nil))

        XCTAssertEqual(error?["code"] as? Int, 200)
    }

    func testNetworkError() {
        let error = failureEntry(FileUploader.outcome(data: nil, response: nil, error: URLError(.notConnectedToInternet)))

        XCTAssertEqual(error?["code"] as? Int, URLError.notConnectedToInternet.rawValue)
    }

    func testMissingResponse() {
        XCTAssertEqual(failureEntry(FileUploader.outcome(data: nil, response: nil, error: nil))?["code"] as? Int, 500)
    }

    // MARK: - Jobs

    private func job(name: String, preserve: Bool, skyflowID: String? = nil, metadata: Bool = false) -> FileUploadJob {
        FileUploadJob(file: FileTestSupport.picked(name), table: "docs", column: "file",
                      skyflowID: skyflowID, preserveFileName: preserve, returnFileMetadata: metadata)
    }

    func testUploadFileNamePreserved() {
        XCTAssertEqual(job(name: "scan.pdf", preserve: true).uploadFileName, "scan.pdf")
    }

    func testGeneratedUploadFileNameKeepsOnlyExtension() {
        let name = job(name: "jane-passport.PDF", preserve: false).uploadFileName

        XCTAssertFalse(name.contains("jane"))
        XCTAssertTrue(name.hasSuffix(".pdf"))
        XCTAssertNotNil(UUID(uuidString: String(name.dropLast(4))))
    }

    func testGeneratedUploadFileNameWithoutExtension() {
        XCTAssertNotNil(UUID(uuidString: job(name: "README", preserve: false).uploadFileName))
    }

    func testFormFields() {
        XCTAssertEqual(job(name: "a.pdf", preserve: true).formFields.map { "\($0.name)=\($0.value)" },
                       ["tableName=docs", "columnName=file"])
        XCTAssertEqual(job(name: "a.pdf", preserve: true, skyflowID: "id-1", metadata: true).formFields.map { "\($0.name)=\($0.value)" },
                       ["tableName=docs", "columnName=file", "skyflowID=id-1", "returnFileMetadata=true"])
    }
}
