/*
 * Copyright (c) 2022 Skyflow
*/

// Presents the system Files and Photos pickers and the camera. Files and Photos run out of
// process, so they need no privacy permission or Info.plist key. The camera needs both; see
// CameraAccess. Documents are opened in place: the SDK keeps a security-scoped link to the
// user's original and makes no copy. Library photos picked while the app already has full photo
// access keep only their identifier. Both are read at upload. Other photos and camera images are
// copied or written into SecureFileStore. The completion runs on the main queue.

import Foundation
import MobileCoreServices
import UIKit
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

internal enum FilePickFailure: Equatable {
    /// The user denied camera access, now or earlier, or it is restricted on the device.
    case cameraAccessDenied
    /// No camera, or the app does not declare NSCameraUsageDescription.
    case cameraUnavailable
}

internal struct FilePickResult {
    var files: [PickedFile] = []
    // Files the user picked that could not be read or copied (for example an iCloud file
    // that failed to download). Reported to the user, never silently dropped.
    var unreadableCount = 0
    // The source could not be opened at all.
    var failure: FilePickFailure?

    static let cancelled = FilePickResult()

    static func failed(_ failure: FilePickFailure) -> FilePickResult {
        FilePickResult(failure: failure)
    }
}

internal protocol FilePicking: AnyObject {
    /// Whether `source` can be offered on this device and in this app.
    func isAvailable(_ source: FileSource) -> Bool
    func pick(from source: FileSource, presenter: UIViewController, configuration: FileElementConfiguration,
              selectionLimit: Int, completion: @escaping (FilePickResult) -> Void)
}

internal final class SystemFilePicker: NSObject, FilePicking {
    private let store: SecureFileStore
    private let camera: CameraAccess
    private let photoLibrary: PhotoAssetLibrary
    internal var completion: ((FilePickResult) -> Void)?
    private var configuration: FileElementConfiguration?

    init(store: SecureFileStore, camera: CameraAccess = SystemCameraAccess(),
         photoLibrary: PhotoAssetLibrary = SystemPhotoAssetLibrary()) {
        self.store = store
        self.camera = camera
        self.photoLibrary = photoLibrary
    }

    func isAvailable(_ source: FileSource) -> Bool {
        switch source {
        case .FILES, .PHOTOS: return true
        case .CAMERA: return camera.canOfferCamera
        }
    }

    func pick(from source: FileSource, presenter: UIViewController, configuration: FileElementConfiguration,
              selectionLimit: Int, completion: @escaping (FilePickResult) -> Void) {
        self.completion = completion
        self.configuration = configuration
        switch source {
        case .FILES:
            present(makeDocumentPicker(configuration: configuration), from: presenter)
        case .PHOTOS:
            present(makePhotoPicker(selectionLimit: selectionLimit), from: presenter)
        case .CAMERA:
            openCamera(from: presenter)
        }
    }

    private func present(_ picker: UIViewController, from presenter: UIViewController) {
        // Presenting from a view controller that is not on screen silently does nothing, which
        // would leave the element waiting for a picker that never appeared.
        guard presenter.viewIfLoaded?.window != nil else {
            finish(.cancelled)
            return
        }
        // Swipe-to-dismiss does not call every picker's cancel callback (UIImagePickerController
        // never does), so dismissal is also observed here. finish() runs at most once.
        picker.presentationController?.delegate = self
        presenter.present(picker, animated: true)
    }

    // Checked again here, not only when building the menu: opening the camera without
    // NSCameraUsageDescription terminates the app, and on a device without a camera
    // UIImagePickerController throws.
    private func openCamera(from presenter: UIViewController) {
        guard camera.canOfferCamera else {
            finish(.failed(.cameraUnavailable))
            return
        }
        switch camera.authorization {
        case .authorized:
            present(makeCameraPicker(), from: presenter)
        case .notDetermined:
            camera.requestAccess { granted in
                DispatchQueue.main.async { [weak self, weak presenter] in
                    guard let self = self else { return }
                    guard granted else {
                        self.finish(.failed(.cameraAccessDenied))
                        return
                    }
                    guard let presenter = presenter else {
                        self.finish(.cancelled)
                        return
                    }
                    self.present(self.makeCameraPicker(), from: presenter)
                }
            }
        case .denied, .restricted:
            // iOS shows the prompt only once. Asking again does nothing, so the element
            // explains instead and the app can send the user to Settings.
            finish(.failed(.cameraAccessDenied))
        }
    }

    private func finish(_ result: FilePickResult) {
        let completion = self.completion
        self.completion = nil
        self.configuration = nil
        completion?(result)
    }

    private func makeDocumentPicker(configuration: FileElementConfiguration) -> UIViewController {
        let identifiers = configuration.typeRules.pickerTypeIdentifiers
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            let types = identifiers.compactMap(UTType.init)
            picker = UIDocumentPickerViewController(forOpeningContentTypes: types.isEmpty ? [.item] : types, asCopy: false)
        } else {
            picker = UIDocumentPickerViewController(documentTypes: identifiers, in: .open)
        }
        picker.allowsMultipleSelection = configuration.type == .MULTI_FILE_INPUT
        picker.delegate = self
        return picker
    }

    private func makeCameraPicker() -> UIViewController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        return picker
    }

    private func makePhotoPicker(selectionLimit: Int) -> UIViewController {
        if #available(iOS 14.0, *) {
            // Neither initializer asks for photo library access. With the shared library,
            // results carry asset identifiers, which are only usable with full access.
            var phConfiguration = photoLibrary.hasFullAccess
                ? PHPickerConfiguration(photoLibrary: .shared())
                : PHPickerConfiguration()
            phConfiguration.filter = .images
            phConfiguration.selectionLimit = max(selectionLimit, 1)
            let picker = PHPickerViewController(configuration: phConfiguration)
            picker.delegate = self
            return picker
        }
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String]
        picker.delegate = self
        return picker
    }

    // A library photo kept by identifier, with no copy, when the app has full photo access and
    // the photo's own format is allowed. Otherwise nil, and the photo is copied as before
    // (which may also convert it to an allowed format such as JPEG).
    internal func libraryPhoto(assetID: String?, configuration: FileElementConfiguration) -> PickedFile? {
        guard let assetID = assetID, photoLibrary.hasFullAccess,
              let info = photoLibrary.info(forAssetID: assetID) else {
            return nil
        }
        let file = PickedFile.libraryPhoto(assetID: assetID, info: info)
        return configuration.typeRules.accepts(file) ? file : nil
    }

    // Runs on the caller's queue. Must stay synchronous: photo picker temporary files are
    // deleted as soon as the system's completion handler returns.
    fileprivate func importFile(at url: URL, name: String, move: Bool) -> PickedFile? {
        guard let stored = try? store.importFile(from: url, move: move),
              let size = try? store.fileSize(of: stored) else {
            return nil
        }
        return PickedFile(url: stored, name: name, size: size)
    }

    // A camera photo exists only in memory. It is encoded as JPEG, which also leaves out
    // the capture metadata, and written straight into the store. It is never saved to the
    // user's photo library.
    internal func storeCapturedPhoto(_ image: UIImage, takenAt date: Date = Date()) -> PickedFile? {
        guard let data = image.jpegData(compressionQuality: Self.cameraJPEGQuality),
              let url = try? store.write(data, pathExtension: "jpg") else {
            return nil
        }
        return PickedFile(url: url, name: Self.cameraFileName(takenAt: date), size: data.count,
                          typeIdentifier: FileTypeResolver.jpeg)
    }

    // Encoding a full-resolution photo takes long enough to stall the UI, so it runs off
    // the main queue; the completion still runs on the main queue.
    internal func handleCapturedPhoto(info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else {
            finish(FilePickResult(files: [], unreadableCount: 1))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let file = self.storeCapturedPhoto(image)
            DispatchQueue.main.async {
                self.finish(file.map { FilePickResult(files: [$0]) } ?? FilePickResult(files: [], unreadableCount: 1))
            }
        }
    }

    static let cameraJPEGQuality: CGFloat = 0.9

    // Only characters allowed by the preserveFileName rule, so the photo uploads either way.
    static func cameraFileName(takenAt date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "photo_\(formatter.string(from: date)).jpg"
    }
}

extension SystemFilePicker: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish(.cancelled)
    }
}

extension SystemFilePicker: UIDocumentPickerDelegate {
    // Off the main queue: a coordinated read waits for an iCloud file to download.
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let files = urls.compactMap(Self.openInPlace)
            DispatchQueue.main.async {
                self.finish(FilePickResult(files: files, unreadableCount: urls.count - files.count))
            }
        }
    }

    // The original stays where the user keeps it; only its size is read now, for validation.
    static func openInPlace(_ url: URL) -> PickedFile? {
        let access = SecurityScopedAccess(url)
        guard let size = try? SecurityScopedAccess.coordinatedRead(url, {
            try $0.resourceValues(forKeys: [.fileSizeKey]).fileSize
        }) else {
            return nil
        }
        return PickedFile(url: url, name: url.lastPathComponent, size: size, access: access)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        finish(.cancelled)
    }
}

@available(iOS 14.0, *)
extension SystemFilePicker: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard results.isEmpty == false, let configuration = configuration else {
            finish(.cancelled)
            return
        }
        let group = DispatchGroup()
        let lock = NSLock()
        var picked = [PickedFile?](repeating: nil, count: results.count)

        for (index, result) in results.enumerated() {
            if let file = libraryPhoto(assetID: result.assetIdentifier, configuration: configuration) {
                picked[index] = file
                continue
            }
            let provider = result.itemProvider
            guard let typeIdentifier = configuration.typeRules.photoTypeIdentifier(registered: provider.registeredTypeIdentifiers) else {
                continue
            }
            group.enter()
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, _ in
                defer { group.leave() }
                guard let self = self, let url = url else { return }
                let baseName = provider.suggestedName ?? "photo"
                let ext = url.pathExtension.isEmpty
                    ? (FileTypeResolver.preferredExtension(forTypeIdentifier: typeIdentifier) ?? "")
                    : url.pathExtension
                let name = ext.isEmpty ? baseName : "\(baseName).\(ext)"
                let file = self.importFile(at: url, name: name, move: false)
                lock.lock()
                picked[index] = file
                lock.unlock()
            }
        }

        group.notify(queue: .main) { [weak self] in
            let files = picked.compactMap { $0 }
            self?.finish(FilePickResult(files: files, unreadableCount: results.count - files.count))
        }
    }
}

extension SystemFilePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if picker.sourceType == .camera {
            handleCapturedPhoto(info: info)
            return
        }
        guard let url = info[.imageURL] as? URL else {
            finish(FilePickResult(files: [], unreadableCount: 1))
            return
        }
        var result = FilePickResult()
        if let file = importFile(at: url, name: url.lastPathComponent, move: false) {
            result.files.append(file)
        } else {
            result.unreadableCount = 1
        }
        finish(result)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        finish(.cancelled)
    }
}
