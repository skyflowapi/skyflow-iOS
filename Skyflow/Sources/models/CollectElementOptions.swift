/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes Options parameter for SkyflowInputField.
// Contract-identical in both SDKs today; declared per SDK so either product
// can add or remove options independently in the future.

import Foundation
#if os(iOS)
import UIKit
#endif

public struct CollectElementOptions {
    package var data: BaseCollectElementOptions
    // Read only by file elements; ignored by text fields.
    internal var fileOptions: FileElementOptions

    /// The file options (`allowedFileType` to `sources`) apply only to file elements, as in skyflow-js.
    ///
    /// - Parameters:
    ///   - allowedFileType: Extensions (`".pdf"`), MIME types (`"application/pdf"`) or MIME
    ///     wildcards (`"image/*"`). `nil` allows any type except the always-blocked archive
    ///     and executable types.
    ///   - blockEmptyFiles: Reject 0-byte files.
    ///   - preserveFileName: Upload with the original name, which must then match
    ///     `^[a-zA-Z0-9!\-_.*()]+$`. When `false`, a random name with the original extension is sent.
    ///   - returnFileMetadata: Include `fileMetadata` in each upload response entry.
    ///   - maxFileSize: Per-file limit in bytes for `.MULTI_FILE_INPUT` (default 32,000,000).
    ///     Ignored for `.FILE_INPUT`, whose limit is fixed at 32,000,000.
    ///   - maxFileCount: Maximum files for `.MULTI_FILE_INPUT` (default 4). Ignored for `.FILE_INPUT`.
    ///   - sources: Pickers offered to the user, in menu order. A source that does not apply
    ///     (Photos or Camera when images are not allowed, Camera on a device without one or in
    ///     an app without `NSCameraUsageDescription`) is left out of the menu.
    public init(required: Bool? = false, enableCardIcon: Bool = true, format: String = "mm/yy", translation: [ Character: String ]? = nil, enableCopy: Bool = false, cardMetaData: [ String: Any]? = nil,
                allowedFileType: [String]? = nil, blockEmptyFiles: Bool = false, preserveFileName: Bool = true,
                returnFileMetadata: Bool = false, maxFileSize: Int? = nil, maxFileCount: Int? = nil,
                sources: [FileSource] = [.FILES, .PHOTOS, .CAMERA]) {
        self.data = BaseCollectElementOptions(required: required ?? false, enableCardIcon: enableCardIcon, format: format, translation: translation, enableCopy: enableCopy, cardMetaData: cardMetaData)
        self.fileOptions = FileElementOptions(required: required ?? false, allowedFileType: allowedFileType,
                                              blockEmptyFiles: blockEmptyFiles, preserveFileName: preserveFileName,
                                              returnFileMetadata: returnFileMetadata, maxFileSize: maxFileSize,
                                              maxFileCount: maxFileCount, sources: sources)
    }
}

public extension TextField {
    func update(updateOptions: CollectElementOptions) {
        self.update(optionsData: updateOptions.data)
    }
}
