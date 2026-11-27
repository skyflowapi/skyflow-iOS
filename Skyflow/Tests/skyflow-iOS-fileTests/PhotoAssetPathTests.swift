/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow
@testable import SkyflowCore

/// Serves photos from memory, in small chunks on a background queue like PHAssetResourceManager.
final class FakePhotoAssetLibrary: PhotoAssetLibrary {
    var hasFullAccess = true
    var assets: [String: (info: PhotoAssetInfo, data: Data)] = [:]
    var streamError: Error?

    func info(forAssetID id: String) -> PhotoAssetInfo? {
        assets[id]?.info
    }

    func streamData(forAssetID id: String, onChunk: @escaping (Data) throws -> Void,
                    completion: @escaping (Error?) -> Void) {
        let data = assets[id]?.data
        let error = streamError
        DispatchQueue.global().async {
            guard let data = data, error == nil else {
                completion(error ?? PhotoAssetError.unavailable)
                return
            }
            do {
                for start in stride(from: 0, to: data.count, by: 4) {
                    try onChunk(data.subdata(in: start..<min(start + 4, data.count)))
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}

final class PhotoAssetPathTests: XCTestCase {
    private var base: URL!
    private var store: SecureFileStore!
    private var library: FakePhotoAssetLibrary!
    private let heic = PhotoAssetInfo(name: "IMG_1234.HEIC", size: 11, typeIdentifier: "public.heic")
    private let jpeg = PhotoAssetInfo(name: "IMG_5678.JPG", size: 11, typeIdentifier: "public.jpeg")

    override func setUp() {
        MockUploadURLProtocol.reset()
        base = FileTestSupport.makeDirectory()
        store = SecureFileStore(baseDirectory: base)
        library = FakePhotoAssetLibrary()
        library.assets = ["asset-1": (heic, Data("photo-bytes".utf8)), "asset-2": (jpeg, Data("jpeg-bytes!".utf8))]
    }

    override func tearDown() {
        MockUploadURLProtocol.reset()
        try? FileManager.default.removeItem(at: base)
    }

    private func picker() -> SystemFilePicker {
        SystemFilePicker(store: store, photoLibrary: library)
    }

    private func storedFiles() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil, options: [])
            .flatMap { try FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil) }) ?? []
    }

    // MARK: - Choosing the path at pick time

    func testFullAccessKeepsOnlyTheIdentifier() {
        let file = picker().libraryPhoto(assetID: "asset-1", configuration: FileTestSupport.configuration())

        XCTAssertEqual(file?.photoAssetID, "asset-1")
        XCTAssertEqual(file?.name, "IMG_1234.HEIC")
        XCTAssertEqual(file?.size, 11)
        XCTAssertEqual(file?.typeIdentifier, "public.heic")
        XCTAssertFalse(store.contains(file!.url))
        XCTAssertTrue(storedFiles().isEmpty, "no copy is written")
    }

    func testFallsBackWithoutFullAccess() {
        library.hasFullAccess = false

        XCTAssertNil(picker().libraryPhoto(assetID: "asset-1", configuration: FileTestSupport.configuration()))
    }

    func testFallsBackWithoutIdentifierOrUnreadableAsset() {
        XCTAssertNil(picker().libraryPhoto(assetID: nil, configuration: FileTestSupport.configuration()))
        XCTAssertNil(picker().libraryPhoto(assetID: "missing", configuration: FileTestSupport.configuration()))
    }

    // The copy path can convert HEIC to an allowed JPEG; the library path uploads the
    // original format, so it is used only when that format is allowed.
    func testFallsBackWhenOriginalFormatIsNotAllowed() {
        let jpegOnly = FileTestSupport.configuration(options: FileElementOptions(allowedFileType: ["image/jpeg"]))

        XCTAssertNil(picker().libraryPhoto(assetID: "asset-1", configuration: jpegOnly))
        XCTAssertEqual(picker().libraryPhoto(assetID: "asset-2", configuration: jpegOnly)?.photoAssetID, "asset-2")
    }

    func testRemovingALibraryPhotoDeletesNothing() {
        let outside = FileTestSupport.makeDirectory()
        defer { try? FileManager.default.removeItem(at: outside) }
        let kept = try! store.importFile(from: FileTestSupport.writeFile(named: "a.pdf", bytes: 4, in: outside), move: true)
        let file = picker().libraryPhoto(assetID: "asset-1", configuration: FileTestSupport.configuration())!

        store.remove(file.url)

        XCTAssertTrue(FileManager.default.fileExists(atPath: kept.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: "/dev/null"))
    }

    // MARK: - Upload

    private func uploader() -> FileUploader {
        let apiClient = APIClient(vaultID: "vault123", vaultURL: "https://vault.example.org/",
                                  tokenProvider: StaticTokenProvider())
        return FileUploader(apiClient: apiClient, session: FileTestSupport.makeSession(), store: store,
                            contextOptions: ContextOptions(), photoLibrary: library)
    }

    private func job(_ assetID: String) -> FileUploadJob {
        let file = PickedFile.libraryPhoto(assetID: assetID, info: library.assets[assetID]!.info)
        return FileUploadJob(file: file, table: "docs", column: "file", skyflowID: nil,
                             preserveFileName: true, returnFileMetadata: false)
    }

    private func run(_ jobs: [FileUploadJob]) -> [FileUploadOutcome] {
        let done = expectation(description: "upload")
        var outcomes: [FileUploadOutcome] = []
        let uploader = uploader()
        uploader.upload(jobs, onTokenFailure: { _ in XCTFail("token") }, completion: {
            outcomes = $0
            done.fulfill()
        })
        wait(for: [done], timeout: 5)
        return outcomes
    }

    func testUploadStreamsThePhotoFromTheLibrary() {
        MockUploadURLProtocol.handler = { _, _ in
            FileTestSupport.jsonResponse(200, ["skyflow_id": "id-1"])
        }

        let outcomes = run([job("asset-1")])

        guard case .success(let entry) = outcomes.first else { return XCTFail("expected success") }
        XCTAssertEqual(entry["skyflow_id"] as? String, "id-1")
        let body = String(decoding: MockUploadURLProtocol.bodies[0], as: UTF8.self)
        XCTAssertTrue(body.contains("filename=\"IMG_1234.HEIC\""))
        XCTAssertTrue(body.contains("Content-Type: image/heic"))
        XCTAssertTrue(body.contains("\r\n\r\nphoto-bytes\r\n--"))
        XCTAssertTrue(storedFiles().isEmpty, "request body removed after upload")
    }

    func testPhotoThatCannotBeReadFailsOnlyThatFile() {
        MockUploadURLProtocol.handler = { _, _ in
            FileTestSupport.jsonResponse(200, ["skyflow_id": "id-2"])
        }
        // Deleted from Photos between pick and upload.
        library.assets.removeValue(forKey: "asset-1")
        let deleted = FileUploadJob(file: PickedFile.libraryPhoto(assetID: "asset-1", info: heic), table: "docs",
                                    column: "file", skyflowID: nil, preserveFileName: true, returnFileMetadata: false)

        let outcomes = run([deleted, job("asset-2")])

        guard case .failure(let entry) = outcomes[0] else { return XCTFail("expected failure") }
        XCTAssertEqual((entry["error"] as? [String: Any])?["code"] as? Int, 400)
        guard case .success = outcomes[1] else { return XCTFail("expected success") }
        XCTAssertEqual(MockUploadURLProtocol.requests.count, 1)
        XCTAssertTrue(storedFiles().isEmpty)
    }
}
