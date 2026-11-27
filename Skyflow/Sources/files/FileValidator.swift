/*
 * Copyright (c) 2022 Skyflow
*/

// Client-side file checks. Order and messages mirror skyflow-js (iframe-form validator) so
// both SDKs show the same errors. The server must enforce the same rules; these only give
// the user early feedback.

import Foundation

internal enum FileValidationError: Equatable {
    case noFileSelected
    case invalidFileType
    case invalidFileSize
    case invalidFileName
    case fileCountExceeded(maxCount: Int)
    case fileCountAndSizeExceeded(maxCount: Int, maxSize: Int)
    case fileSizeExceeded(maxSize: Int, fileNames: [String])

    // Shown inside the element. May contain file names: the SDK draws it, the app never reads it.
    var displayMessage: String {
        switch self {
        case .fileSizeExceeded(let maxSize, let fileNames) where fileNames.count > 1:
            return "\(fileNames.joined(separator: ", ")) exceeds the \(Self.sizeLabel(maxSize)) size limit. Remove it or choose a smaller file"
        default:
            return reportMessage
        }
    }

    // Returned to the app through uploadFiles(). Never contains file names.
    var reportMessage: String {
        switch self {
        case .noFileSelected: return "No File Selected"
        case .invalidFileType: return "Invalid File Type."
        case .invalidFileSize: return "Invalid File Size"
        case .invalidFileName: return "Invalid File Name. Only alphanumeric characters and !-_.*() are allowed."
        case .fileCountExceeded(let maxCount):
            return "You can upload up to \(maxCount) files. Remove file(s) to add more"
        case .fileCountAndSizeExceeded(let maxCount, let maxSize):
            return "You can upload up to \(maxCount) files, each under \(Self.sizeLabel(maxSize))"
        case .fileSizeExceeded(let maxSize, _):
            return "File exceeds the \(Self.sizeLabel(maxSize)) size limit. Choose a smaller file"
        }
    }

    static func sizeLabel(_ bytes: Int) -> String {
        "\(Int((Double(bytes) / 1_000_000).rounded())) MB"
    }
}

internal enum FileValidator {
    // Same pattern as skyflow-js ALLOWED_NAME_FOR_FILE.
    private static let allowedNamePattern = try! NSRegularExpression(pattern: "^[a-zA-Z0-9!\\-_.*()]+$")

    static func isValidFileName(_ name: String) -> Bool {
        let range = NSRange(name.startIndex..., in: name)
        return allowedNamePattern.firstMatch(in: name, range: range) != nil
    }

    static func validate(_ files: [PickedFile], configuration: FileElementConfiguration) -> FileValidationError? {
        if files.isEmpty {
            return configuration.required ? .noFileSelected : nil
        }
        switch configuration.type {
        case .FILE_INPUT:
            return validateSingle(files, configuration: configuration)
        case .MULTI_FILE_INPUT:
            return validateMultiple(files, configuration: configuration)
        }
    }

    private static func validateSingle(_ files: [PickedFile], configuration: FileElementConfiguration) -> FileValidationError? {
        let file = files[0]
        if let error = contentError(file, configuration: configuration) {
            return error
        }
        if file.size > configuration.maxFileSize {
            return .invalidFileSize
        }
        return nameError(file, configuration: configuration)
    }

    private static func validateMultiple(_ files: [PickedFile], configuration: FileElementConfiguration) -> FileValidationError? {
        let countExceeded = files.count > configuration.maxFileCount
        let oversized = files.filter { $0.size > configuration.maxFileSize }
        if countExceeded {
            return oversized.isEmpty
                ? .fileCountExceeded(maxCount: configuration.maxFileCount)
                : .fileCountAndSizeExceeded(maxCount: configuration.maxFileCount, maxSize: configuration.maxFileSize)
        }
        if oversized.isEmpty == false {
            return .fileSizeExceeded(maxSize: configuration.maxFileSize, fileNames: oversized.map(\.name))
        }
        for file in files {
            if let error = contentError(file, configuration: configuration) ?? nameError(file, configuration: configuration) {
                return error
            }
        }
        return nil
    }

    private static func contentError(_ file: PickedFile, configuration: FileElementConfiguration) -> FileValidationError? {
        let rules = configuration.typeRules
        if rules.isBlocked(file) || rules.isAllowed(file) == false {
            return .invalidFileType
        }
        if configuration.blockEmptyFiles, file.size == 0 {
            return .invalidFileSize
        }
        return nil
    }

    private static func nameError(_ file: PickedFile, configuration: FileElementConfiguration) -> FileValidationError? {
        guard configuration.preserveFileName, isValidFileName(file.name) == false else { return nil }
        return .invalidFileName
    }
}
