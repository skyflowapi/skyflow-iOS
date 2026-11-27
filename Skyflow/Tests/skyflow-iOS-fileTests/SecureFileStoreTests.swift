/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow

final class SecureFileStoreTests: XCTestCase {
    private var base: URL!
    private var outside: URL!
    private var store: SecureFileStore!

    override func setUp() {
        base = FileTestSupport.makeDirectory()
        outside = FileTestSupport.makeDirectory()
        store = SecureFileStore(baseDirectory: base)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: base)
        try? FileManager.default.removeItem(at: outside)
    }

    func testImportByMoveLeavesNoSourceCopy() throws {
        let source = FileTestSupport.writeFile(named: "scan.pdf", bytes: 10, in: outside)

        let stored = try store.importFile(from: source, move: true)

        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: stored.path))
        XCTAssertTrue(store.contains(stored))
        XCTAssertEqual(stored.pathExtension, "pdf")
        // Stored under a random name so the original (personal) name never hits the disk path.
        XCTAssertNotEqual(stored.deletingPathExtension().lastPathComponent, "scan")
    }

    func testImportByCopyKeepsSource() throws {
        let source = FileTestSupport.writeFile(named: "photo.jpg", bytes: 10, in: outside)

        let stored = try store.importFile(from: source, move: false)

        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertEqual(try Data(contentsOf: stored), try Data(contentsOf: source))
    }

    func testImportMissingFileThrows() {
        XCTAssertThrowsError(try store.importFile(from: outside.appendingPathComponent("missing.pdf"), move: true))
    }

    func testFileSize() throws {
        let stored = try store.importFile(from: FileTestSupport.writeFile(named: "a.bin", bytes: 1234, in: outside), move: true)

        XCTAssertEqual(try store.fileSize(of: stored), 1234)
    }

    func testMakeEmptyFile() throws {
        let url = try store.makeEmptyFile(pathExtension: "multipart")

        XCTAssertTrue(store.contains(url))
        XCTAssertEqual(try store.fileSize(of: url), 0)
        XCTAssertEqual(url.pathExtension, "multipart")
    }

    func testRemoveDeletesOnlyStoreFiles() throws {
        let stored = try store.importFile(from: FileTestSupport.writeFile(named: "a.pdf", bytes: 1, in: outside), move: true)
        let foreign = FileTestSupport.writeFile(named: "keep.pdf", bytes: 1, in: outside)

        store.remove(stored)
        store.remove(foreign)

        XCTAssertFalse(FileManager.default.fileExists(atPath: stored.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: foreign.path))
    }

    func testContainsRejectsPrefixLookalikesAndTraversal() {
        XCTAssertFalse(store.contains(URL(fileURLWithPath: store.directory.path + "-evil/a.pdf")))
        XCTAssertFalse(store.contains(store.directory.appendingPathComponent("../a.pdf")))
        XCTAssertFalse(store.contains(store.directory))
    }

    func testRemoveAll() throws {
        let first = try store.importFile(from: FileTestSupport.writeFile(named: "a.pdf", bytes: 1, in: outside), move: true)
        let second = try store.importFile(from: FileTestSupport.writeFile(named: "b.pdf", bytes: 1, in: outside), move: true)

        store.removeAll()

        XCTAssertFalse(FileManager.default.fileExists(atPath: first.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: second.path))
    }

    func testInitClearsFilesLeftByPreviousProcess() throws {
        let leftover = try store.importFile(from: FileTestSupport.writeFile(named: "a.pdf", bytes: 1, in: outside), move: true)

        _ = SecureFileStore(baseDirectory: base)

        XCTAssertFalse(FileManager.default.fileExists(atPath: leftover.path))
    }

    func testWriteCreatesNewFileInsideStore() throws {
        let data = Data("photo".utf8)

        let first = try store.write(data, pathExtension: "jpg")
        let second = try store.write(data, pathExtension: "jpg")

        XCTAssertTrue(store.contains(first))
        XCTAssertEqual(first.pathExtension, "jpg")
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(try Data(contentsOf: first), data)
        XCTAssertEqual(try store.fileSize(of: first), data.count)
    }
}
