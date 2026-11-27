/*
 * Copyright (c) 2022 Skyflow
*/

import UIKit
import XCTest
@testable import Skyflow

final class SystemFilePickerTests: XCTestCase {
    private var base: URL!
    private var outside: URL!
    private var store: SecureFileStore!
    private var picker: SystemFilePicker!
    private var results: [FilePickResult] = []

    override func setUp() {
        base = FileTestSupport.makeDirectory()
        outside = FileTestSupport.makeDirectory()
        store = SecureFileStore(baseDirectory: base)
        picker = SystemFilePicker(store: store)
        results = []
        picker.completion = { [unowned self] in results.append($0) }
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: base)
        try? FileManager.default.removeItem(at: outside)
    }

    private var documentPicker: UIDocumentPickerViewController {
        UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
    }

    func testOffScreenPresenterCancelsImmediately() {
        var received: FilePickResult?
        picker.pick(from: .FILES, presenter: UIViewController(), configuration: FileTestSupport.configuration(),
                    selectionLimit: 1) { received = $0 }

        XCTAssertNotNil(received)
        XCTAssertEqual(received?.files.isEmpty, true)
        XCTAssertEqual(received?.unreadableCount, 0)
    }

    private func pickDocuments(_ urls: [URL]) -> FilePickResult? {
        let done = expectation(description: "pick")
        picker.completion = { [unowned self] in
            results.append($0)
            done.fulfill()
        }
        picker.documentPicker(documentPicker, didPickDocumentsAt: urls)
        wait(for: [done], timeout: 5)
        return results.first
    }

    func testPickedDocumentsAreOpenedInPlace() {
        let source = FileTestSupport.writeFile(named: "scan.pdf", bytes: 42, in: outside)

        let file = pickDocuments([source])?.files.first

        XCTAssertEqual(file?.name, "scan.pdf")
        XCTAssertEqual(file?.size, 42)
        XCTAssertEqual(file?.typeIdentifier, "com.adobe.pdf")
        XCTAssertEqual(file?.url, source)
        XCTAssertEqual(file?.isOpenInPlace, true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path), "the original stays where it is")
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.directory.path), "no copy is made")
    }

    func testRemovingADocumentOpenedInPlaceKeepsTheOriginal() {
        let source = FileTestSupport.writeFile(named: "scan.pdf", bytes: 42, in: outside)
        let file = pickDocuments([source])?.files.first

        store.remove(file!.url)

        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    func testUnreadableDocumentsAreCounted() {
        let good = FileTestSupport.writeFile(named: "a.pdf", bytes: 1, in: outside)
        let missing = outside.appendingPathComponent("gone.pdf")

        let result = pickDocuments([good, missing])

        XCTAssertEqual(result?.files.map(\.name), ["a.pdf"])
        XCTAssertEqual(result?.unreadableCount, 1)
    }

    func testDocumentPickerCancel() {
        picker.documentPickerWasCancelled(documentPicker)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.files.isEmpty, true)
    }

    func testSwipeDismissReportsCancelExactlyOnce() {
        let controller = documentPicker
        let presentation = UIPresentationController(presentedViewController: controller, presenting: nil)

        picker.presentationControllerDidDismiss(presentation)
        picker.documentPickerWasCancelled(controller)

        XCTAssertEqual(results.count, 1)
    }

    // MARK: - Camera

    private func makeCameraPicker(_ camera: FakeCameraAccess) -> SystemFilePicker {
        let picker = SystemFilePicker(store: store, camera: camera)
        picker.completion = { [unowned self] in results.append($0) }
        return picker
    }

    private func pickFromCamera(_ picker: SystemFilePicker, presenter: UIViewController = UIViewController()) -> FilePickResult? {
        let done = expectation(description: "camera pick finished")
        var received: FilePickResult?
        picker.pick(from: .CAMERA, presenter: presenter, configuration: FileTestSupport.configuration(),
                    selectionLimit: 1) {
            XCTAssertTrue(Thread.isMainThread)
            received = $0
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
        return received
    }

    func testFilesAndPhotosAreAlwaysAvailable() {
        let camera = FakeCameraAccess()
        camera.hasUsageDescription = false
        camera.isCameraAvailable = false
        let picker = makeCameraPicker(camera)

        XCTAssertTrue(picker.isAvailable(.FILES))
        XCTAssertTrue(picker.isAvailable(.PHOTOS))
        XCTAssertFalse(picker.isAvailable(.CAMERA))
    }

    func testCameraNeedsUsageDescriptionAndHardware() {
        let camera = FakeCameraAccess()
        let picker = makeCameraPicker(camera)
        XCTAssertTrue(picker.isAvailable(.CAMERA))

        camera.hasUsageDescription = false
        XCTAssertFalse(picker.isAvailable(.CAMERA), "opening the camera without the key would crash the app")

        camera.hasUsageDescription = true
        camera.isCameraAvailable = false
        XCTAssertFalse(picker.isAvailable(.CAMERA))
    }

    func testUnavailableCameraFailsWithoutAskingForAccess() {
        let camera = FakeCameraAccess()
        camera.hasUsageDescription = false
        camera.authorization = .notDetermined

        let result = pickFromCamera(makeCameraPicker(camera))

        XCTAssertEqual(result?.failure, .cameraUnavailable)
        XCTAssertEqual(camera.accessRequests, 0)
    }

    func testDeniedOrRestrictedCameraFailsWithoutAskingAgain() {
        for authorization in [CameraAuthorization.denied, .restricted] {
            let camera = FakeCameraAccess()
            camera.authorization = authorization

            let result = pickFromCamera(makeCameraPicker(camera))

            XCTAssertEqual(result?.failure, .cameraAccessDenied, "\(authorization)")
            XCTAssertEqual(camera.accessRequests, 0, "iOS only prompts once; \(authorization)")
        }
    }

    func testUndecidedCameraAsksAndReportsRefusal() {
        let camera = FakeCameraAccess()
        camera.authorization = .notDetermined
        camera.grantOnRequest = false

        let result = pickFromCamera(makeCameraPicker(camera))

        XCTAssertEqual(camera.accessRequests, 1)
        XCTAssertEqual(result?.failure, .cameraAccessDenied)
    }

    func testUndecidedCameraAsksAndOpensOnGrant() {
        let camera = FakeCameraAccess()
        camera.authorization = .notDetermined

        // Off screen, so the grant leads to the presenter check rather than a real camera.
        let result = pickFromCamera(makeCameraPicker(camera))

        XCTAssertEqual(camera.accessRequests, 1)
        XCTAssertNil(result?.failure)
        XCTAssertEqual(result?.files.isEmpty, true)
    }

    func testAuthorizedCameraDoesNotAsk() {
        let camera = FakeCameraAccess()

        let result = pickFromCamera(makeCameraPicker(camera))

        XCTAssertEqual(camera.accessRequests, 0)
        XCTAssertNil(result?.failure)
    }

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 40, height: 30), format: format).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
        }
    }

    func testCapturedPhotoIsStoredAsJPEG() throws {
        var components = DateComponents()
        (components.year, components.month, components.day) = (2026, 11, 19)
        (components.hour, components.minute, components.second) = (9, 5, 7)
        let date = try XCTUnwrap(Calendar(identifier: .gregorian).date(from: components))

        let file = try XCTUnwrap(picker.storeCapturedPhoto(makeImage(), takenAt: date))

        XCTAssertEqual(file.name, "photo_20261119_090507.jpg")
        XCTAssertEqual(file.typeIdentifier, "public.jpeg")
        XCTAssertEqual(file.mimeType, "image/jpeg")
        XCTAssertTrue(store.contains(file.url))
        let data = try Data(contentsOf: file.url)
        XCTAssertEqual(file.size, data.count)
        XCTAssertEqual(Array(data.prefix(2)), [0xFF, 0xD8], "JPEG start-of-image marker")
    }

    func testCapturedPhotoPassesStrictValidation() throws {
        let file = try XCTUnwrap(picker.storeCapturedPhoto(makeImage()))
        let configuration = FileTestSupport.configuration(options: FileElementOptions(
            allowedFileType: ["image/jpeg"], blockEmptyFiles: true, preserveFileName: true))

        XCTAssertNil(FileValidator.validate([file], configuration: configuration))
    }

    func testCapturedPhotoCompletesOnMainQueue() {
        let done = expectation(description: "capture finished")
        picker.completion = { result in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(result.files.count, 1)
            XCTAssertEqual(result.unreadableCount, 0)
            done.fulfill()
        }

        picker.handleCapturedPhoto(info: [.originalImage: makeImage()])

        wait(for: [done], timeout: 2)
    }

    func testCaptureWithoutImageIsUnreadable() {
        picker.handleCapturedPhoto(info: [:])

        XCTAssertEqual(results.first?.unreadableCount, 1)
        XCTAssertEqual(results.first?.files.isEmpty, true)
    }
}
