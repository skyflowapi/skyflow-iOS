/*
 * Copyright (c) 2022 Skyflow
*/

// File element types. Deliberately separate from the shared `ElementType`: that enum is
// re-exported by both SDKs, and FlowDB has no file API. Keeping these here also avoids
// adding cases to `ElementType`, which would break apps that switch over it exhaustively.

import Foundation

public enum FileElementType: String, CaseIterable {
    /// Collects a single file.
    case FILE_INPUT
    /// Collects up to `maxFileCount` files, each uploaded as its own record.
    case MULTI_FILE_INPUT
}

/// Where a file element lets the user pick files from.
public enum FileSource: CaseIterable {
    /// The Files app document picker. Runs out of process; needs no permission.
    case FILES
    /// The photo library picker. Runs out of process; needs no permission. Shown only when
    /// the allowed file types include images.
    case PHOTOS
    /// Takes a photo with the camera and uploads it as a JPEG, like the "Take Photo" option
    /// mobile browsers add to skyflow-js file inputs. Shown only when the allowed file types
    /// include JPEG, the device has a camera, and the app's Info.plist has
    /// `NSCameraUsageDescription`. The system asks the user for camera access on first use;
    /// if access is denied, the element shows an error instead of opening the camera.
    case CAMERA
}
