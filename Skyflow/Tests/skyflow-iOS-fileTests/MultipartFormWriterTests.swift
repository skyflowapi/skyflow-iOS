/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow

final class MultipartFormWriterTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        directory = FileTestSupport.makeDirectory()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
    }

    private func write(fields: [(name: String, value: String)], fileName: String, source: URL) throws -> Data {
        let destination = directory.appendingPathComponent("body")
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        try MultipartFormWriter(boundary: "BOUNDARY").write(
            fields: fields,
            file: .init(fieldName: "file", fileName: fileName, mimeType: "application/pdf", source: source),
            to: destination)
        return try Data(contentsOf: destination)
    }

    func testBodyLayout() throws {
        let source = directory.appendingPathComponent("src")
        FileManager.default.createFile(atPath: source.path, contents: Data("PDF".utf8))

        let body = try write(fields: [("tableName", "docs"), ("columnName", "file")], fileName: "scan.pdf", source: source)

        let expected = """
        --BOUNDARY\r
        Content-Disposition: form-data; name="tableName"\r
        \r
        docs\r
        --BOUNDARY\r
        Content-Disposition: form-data; name="columnName"\r
        \r
        file\r
        --BOUNDARY\r
        Content-Disposition: form-data; name="file"; filename="scan.pdf"\r
        Content-Type: application/pdf\r
        \r
        PDF\r
        --BOUNDARY--\r

        """
        XCTAssertEqual(String(data: body, encoding: .utf8), expected)
    }

    func testContentType() {
        XCTAssertEqual(MultipartFormWriter(boundary: "B").contentType, "multipart/form-data; boundary=B")
        XCTAssertTrue(MultipartFormWriter().boundary.hasPrefix("skyflow-"))
        XCTAssertNotEqual(MultipartFormWriter().boundary, MultipartFormWriter().boundary)
    }

    func testFileNameCannotInjectHeaders() throws {
        let source = directory.appendingPathComponent("src")
        FileManager.default.createFile(atPath: source.path, contents: Data())

        let body = try write(fields: [], fileName: "a\"\r\nX-Injected: 1.pdf", source: source)
        let text = String(data: body, encoding: .utf8) ?? ""

        XCTAssertTrue(text.contains("filename=\"a%22%0D%0AX-Injected: 1.pdf\""))
        XCTAssertFalse(text.contains("\r\nX-Injected"))
    }

    func testLargeFileIsCopiedExactlyAcrossChunks() throws {
        let size = MultipartFormWriter.chunkSize * 3 + 17
        let source = FileTestSupport.writeFile(named: "big.bin", bytes: size, in: directory)

        let body = try write(fields: [], fileName: "big.bin", source: source)

        let original = try Data(contentsOf: source)
        XCTAssertNotNil(body.range(of: original))
        XCTAssertGreaterThan(body.count, size)
    }

    func testMissingSourceThrows() {
        XCTAssertThrowsError(try write(fields: [], fileName: "a.pdf", source: directory.appendingPathComponent("missing")))
    }
}
