/*
 * Copyright (c) 2022 Skyflow
*/

// The camera is the only file source that needs a privacy permission. The SDK never adds
// Info.plist keys: the camera is offered only when the app already declares
// NSCameraUsageDescription (opening it without the key would crash the app), and access is
// requested only when the user chooses the camera. Wrapped in a protocol so every branch
// can be tested without camera hardware.

import AVFoundation
import Foundation
import UIKit

internal enum CameraAuthorization: Equatable {
    case authorized
    case notDetermined
    case denied
    case restricted
}

internal protocol CameraAccess {
    /// The app's Info.plist declares NSCameraUsageDescription.
    var hasUsageDescription: Bool { get }
    /// The device has a camera that can take photos.
    var isCameraAvailable: Bool { get }
    var authorization: CameraAuthorization { get }
    /// Shows the system prompt. The completion may run on any queue.
    func requestAccess(_ completion: @escaping (Bool) -> Void)
}

internal extension CameraAccess {
    var canOfferCamera: Bool {
        hasUsageDescription && isCameraAvailable
    }
}

internal struct SystemCameraAccess: CameraAccess {
    static let usageDescriptionKey = "NSCameraUsageDescription"

    var hasUsageDescription: Bool {
        let description = Bundle.main.object(forInfoDictionaryKey: Self.usageDescriptionKey) as? String
        return description?.isEmpty == false
    }

    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var authorization: CameraAuthorization {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        @unknown default: return .denied
        }
    }

    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }
}
