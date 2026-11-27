/*
 * Copyright (c) 2022 Skyflow
*/

// What a file element stores. Apps pass these options through `CollectElementOptions`, as in
// skyflow-js; this is their internal form.

import Foundation

internal struct FileElementOptions {
    internal var required: Bool
    internal var allowedFileType: [String]?
    internal var blockEmptyFiles: Bool
    internal var preserveFileName: Bool
    internal var returnFileMetadata: Bool
    internal var maxFileSize: Int?
    internal var maxFileCount: Int?
    internal var sources: [FileSource]

    /// - Parameters:
    ///   - required: Fail validation when no file is selected.
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
    init(required: Bool = false,
                allowedFileType: [String]? = nil,
                blockEmptyFiles: Bool = false,
                preserveFileName: Bool = true,
                returnFileMetadata: Bool = false,
                maxFileSize: Int? = nil,
                maxFileCount: Int? = nil,
                sources: [FileSource] = [.FILES, .PHOTOS, .CAMERA]) {
        self.required = required
        self.allowedFileType = allowedFileType
        self.blockEmptyFiles = blockEmptyFiles
        self.preserveFileName = preserveFileName
        self.returnFileMetadata = returnFileMetadata
        self.maxFileSize = maxFileSize
        self.maxFileCount = maxFileCount
        self.sources = sources
    }
}
