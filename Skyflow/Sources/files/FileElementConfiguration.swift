/*
 * Copyright (c) 2022 Skyflow
*/

// Validated, normalized settings for one file element, built from the public input and
// options. Invalid settings are reported when uploadFiles() runs, because create() cannot fail.

import Foundation

internal struct FileElementConfiguration {
    static let defaultMaxFileSize = 32_000_000
    static let defaultMaxFileCount = 4

    let type: FileElementType
    let table: String
    let column: String
    let skyflowID: String?
    let required: Bool
    let blockEmptyFiles: Bool
    let preserveFileName: Bool
    let returnFileMetadata: Bool
    let maxFileSize: Int
    let maxFileCount: Int
    let typeRules: FileTypeRules
    let sources: [FileSource]

    static func make(input: FileElementInput, options: FileElementOptions) -> Result<FileElementConfiguration, FileErrorCode> {
        guard input.isNotFileType == false else { return .failure(.notFileElementType) }
        let table = input.table.trimmingCharacters(in: .whitespacesAndNewlines)
        let column = input.column.trimmingCharacters(in: .whitespacesAndNewlines)
        guard table.isEmpty == false else { return .failure(.emptyTable) }
        guard column.isEmpty == false else { return .failure(.emptyColumn) }

        if let allowed = options.allowedFileType {
            guard allowed.isEmpty == false else { return .failure(.emptyAllowedFileTypes) }
            let hasBlankEntry = allowed.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            guard hasBlankEntry == false else { return .failure(.invalidAllowedFileTypeEntry) }
        }

        let isMulti = input.type == .MULTI_FILE_INPUT
        if isMulti {
            if let size = options.maxFileSize, size <= 0 { return .failure(.nonPositiveOption(name: "maxFileSize")) }
            if let count = options.maxFileCount, count <= 0 { return .failure(.nonPositiveOption(name: "maxFileCount")) }
        }

        let skyflowID = input.skyflowID.flatMap { $0.isEmpty ? nil : $0 }
        if isMulti, skyflowID != nil {
            return .failure(.skyflowIDNotSupportedForMultiFile)
        }

        let typeRules = FileTypeRules(allowedFileTypes: options.allowedFileType)
        var sources: [FileSource] = []
        for source in options.sources where sources.contains(source) == false {
            if source == .PHOTOS, typeRules.allowsImages == false { continue }
            if source == .CAMERA, typeRules.allowsCameraPhotos == false { continue }
            sources.append(source)
        }
        guard sources.isEmpty == false else { return .failure(.emptySources) }

        return .success(FileElementConfiguration(
            type: input.type,
            table: table,
            column: column,
            skyflowID: skyflowID,
            required: options.required,
            blockEmptyFiles: options.blockEmptyFiles,
            preserveFileName: options.preserveFileName,
            returnFileMetadata: options.returnFileMetadata,
            maxFileSize: isMulti ? (options.maxFileSize ?? defaultMaxFileSize) : defaultMaxFileSize,
            maxFileCount: isMulti ? (options.maxFileCount ?? defaultMaxFileCount) : 1,
            typeRules: typeRules,
            sources: sources
        ))
    }
}
