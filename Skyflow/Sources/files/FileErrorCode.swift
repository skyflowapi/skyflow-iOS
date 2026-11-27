/*
 * Copyright (c) 2022 Skyflow
*/

// Errors returned to the app by file element configuration and uploadFiles(). Kept out of the
// shared ErrorCodes enum because they are Skyflow-only. Messages never contain file names.

import Foundation

internal enum FileErrorCode: Error, Equatable {
    case notFileElementType
    case emptyTable
    case emptyColumn
    case emptyAllowedFileTypes
    case invalidAllowedFileTypeEntry
    case nonPositiveOption(name: String)
    case emptySources
    case skyflowIDNotSupportedForMultiFile
    case noFileElements
    case uploadInProgress
    case invalidElements(details: String)

    var code: Int { 400 }

    var message: String {
        switch self {
        case .notFileElementType:
            return "\(LangAndVersion) Validation error. Invalid type in file element input. Use CollectElementInput with type FILE_INPUT or MULTI_FILE_INPUT for create(fileInput:)."
        case .emptyTable:
            return "\(LangAndVersion) Validation error. 'table' key cannot be empty in file element. Specify a non-empty value instead."
        case .emptyColumn:
            return "\(LangAndVersion) Validation error. 'column' key cannot be empty in file element. Specify a non-empty value instead."
        case .emptyAllowedFileTypes:
            return "\(LangAndVersion) Validation error. Invalid options value, allowedFileType array is empty."
        case .invalidAllowedFileTypeEntry:
            return "\(LangAndVersion) Validation error. Invalid options value, allowedFileType array must contain only non-empty strings."
        case .nonPositiveOption(let name):
            return "\(LangAndVersion) Validation error. Invalid \(name) found in file element options. Specify a positive number instead."
        case .emptySources:
            return "\(LangAndVersion) Validation error. Invalid options value, sources array is empty or has no source that can pick the allowed file types."
        case .skyflowIDNotSupportedForMultiFile:
            return "\(LangAndVersion) Validation error. 'skyflowID' is not supported for MULTI_FILE_INPUT because each file is stored in its own record. Remove 'skyflowID' or use FILE_INPUT."
        case .noFileElements:
            return "\(LangAndVersion) Validation error. No file elements found in collect container. Create a file element before calling uploadFiles."
        case .uploadInProgress:
            return "\(LangAndVersion) Upload failed. An upload is already in progress for this container."
        case .invalidElements(let details):
            return details
        }
    }

    func getErrorObject(contextOptions: ContextOptions) -> SkyflowError {
        Log.error(message: message, contextOptions: contextOptions)
        return SkyflowError(domain: "", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
