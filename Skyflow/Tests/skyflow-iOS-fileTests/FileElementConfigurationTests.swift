/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class FileElementConfigurationTests: XCTestCase {
    private func make(_ input: FileElementInput, _ options: FileElementOptions = FileElementOptions()) -> Result<FileElementConfiguration, FileErrorCode> {
        FileElementConfiguration.make(input: input, options: options)
    }

    private func error(_ input: FileElementInput, _ options: FileElementOptions = FileElementOptions()) -> FileErrorCode? {
        if case .failure(let error) = make(input, options) { return error }
        return nil
    }

    func testSingleFileDefaults() {
        let configuration = FileTestSupport.configuration()

        XCTAssertEqual(configuration.type, .FILE_INPUT)
        XCTAssertFalse(configuration.required)
        XCTAssertFalse(configuration.blockEmptyFiles)
        XCTAssertTrue(configuration.preserveFileName)
        XCTAssertFalse(configuration.returnFileMetadata)
        XCTAssertEqual(configuration.maxFileSize, 32_000_000)
        XCTAssertEqual(configuration.maxFileCount, 1)
        XCTAssertEqual(configuration.sources, [.FILES, .PHOTOS, .CAMERA])
        XCTAssertNil(configuration.skyflowID)
    }

    func testMultiFileDefaults() {
        let configuration = FileTestSupport.configuration(type: .MULTI_FILE_INPUT)

        XCTAssertEqual(configuration.maxFileSize, 32_000_000)
        XCTAssertEqual(configuration.maxFileCount, 4)
    }

    func testMultiFileUsesProvidedLimits() {
        let configuration = FileTestSupport.configuration(type: .MULTI_FILE_INPUT,
                                                          options: FileElementOptions(maxFileSize: 10, maxFileCount: 2))

        XCTAssertEqual(configuration.maxFileSize, 10)
        XCTAssertEqual(configuration.maxFileCount, 2)
    }

    func testSingleFileIgnoresSizeAndCountOptions() {
        // Matches skyflow-js: FILE_INPUT drops maxFileSize/maxFileCount, even invalid values.
        let configuration = FileTestSupport.configuration(options: FileElementOptions(maxFileSize: -5, maxFileCount: 0))

        XCTAssertEqual(configuration.maxFileSize, 32_000_000)
        XCTAssertEqual(configuration.maxFileCount, 1)
    }

    func testTableAndColumnAreTrimmedAndRequired() {
        XCTAssertEqual(error(FileElementInput(table: "", column: "file", type: .FILE_INPUT)), .emptyTable)
        XCTAssertEqual(error(FileElementInput(table: "   ", column: "file", type: .FILE_INPUT)), .emptyTable)
        XCTAssertEqual(error(FileElementInput(table: "docs", column: "", type: .FILE_INPUT)), .emptyColumn)
        XCTAssertEqual(error(FileElementInput(table: "docs", column: "\n", type: .FILE_INPUT)), .emptyColumn)

        let configuration = FileTestSupport.configuration(table: " docs ", column: " file ")
        XCTAssertEqual(configuration.table, "docs")
        XCTAssertEqual(configuration.column, "file")
    }

    func testAllowedFileTypeValidation() {
        let input = FileElementInput(table: "docs", column: "file", type: .FILE_INPUT)

        XCTAssertEqual(error(input, FileElementOptions(allowedFileType: [])), .emptyAllowedFileTypes)
        XCTAssertEqual(error(input, FileElementOptions(allowedFileType: [".pdf", " "])), .invalidAllowedFileTypeEntry)
        XCTAssertNil(error(input, FileElementOptions(allowedFileType: [".pdf"])))
    }

    func testNonPositiveLimitsRejectedForMultiFile() {
        let input = FileElementInput(table: "docs", column: "file", type: .MULTI_FILE_INPUT)

        XCTAssertEqual(error(input, FileElementOptions(maxFileSize: 0)), .nonPositiveOption(name: "maxFileSize"))
        XCTAssertEqual(error(input, FileElementOptions(maxFileSize: -1)), .nonPositiveOption(name: "maxFileSize"))
        XCTAssertEqual(error(input, FileElementOptions(maxFileCount: 0)), .nonPositiveOption(name: "maxFileCount"))
    }

    func testSkyflowIDOnlySupportedForSingleFile() {
        XCTAssertEqual(error(FileElementInput(table: "docs", column: "file", type: .MULTI_FILE_INPUT, skyflowID: "id-1")),
                       .skyflowIDNotSupportedForMultiFile)
        XCTAssertEqual(FileTestSupport.configuration(skyflowID: "id-1").skyflowID, "id-1")
    }

    func testEmptySkyflowIDMeansNewRecord() {
        XCTAssertNil(FileTestSupport.configuration(skyflowID: "").skyflowID)
        // An empty ID must not trip the MULTI_FILE_INPUT restriction either.
        XCTAssertNil(error(FileElementInput(table: "docs", column: "file", type: .MULTI_FILE_INPUT, skyflowID: "")))
    }

    func testPhotosDroppedWhenNoImageTypeAllowed() {
        let configuration = FileTestSupport.configuration(options: FileElementOptions(allowedFileType: [".pdf"]))

        XCTAssertEqual(configuration.sources, [.FILES])
    }

    func testPhotosKeptWhenImagesAllowed() {
        for allowed in [["image/*"], [".jpg"], ["image/png"], [".pdf", ".heic"]] {
            let configuration = FileTestSupport.configuration(options: FileElementOptions(allowedFileType: allowed))
            XCTAssertTrue(configuration.sources.contains(.PHOTOS), "allowed: \(allowed)")
        }
    }

    func testCameraKeptOnlyWhenJPEGAllowed() {
        // Camera photos are uploaded as JPEG, so other image types are not enough.
        for allowed in [["image/*"], [".jpg"], [".JPEG"], ["image/jpeg"], [".pdf", "image/*"]] {
            let configuration = FileTestSupport.configuration(options: FileElementOptions(allowedFileType: allowed))
            XCTAssertEqual(configuration.sources, [.FILES, .PHOTOS, .CAMERA], "allowed: \(allowed)")
        }
        for allowed in [[".pdf"], ["image/png"], [".heic"], ["application/pdf", ".png"]] {
            let configuration = FileTestSupport.configuration(options: FileElementOptions(allowedFileType: allowed))
            XCTAssertFalse(configuration.sources.contains(.CAMERA), "allowed: \(allowed)")
        }
    }

    func testCameraOnlySourceKeepsItsPosition() {
        let configuration = FileTestSupport.configuration(options: FileElementOptions(sources: [.CAMERA, .FILES]))

        XCTAssertEqual(configuration.sources, [.CAMERA, .FILES])
    }

    func testSourcesAreDeduplicatedInOrder() {
        let configuration = FileTestSupport.configuration(options: FileElementOptions(sources: [.PHOTOS, .FILES, .PHOTOS]))

        XCTAssertEqual(configuration.sources, [.PHOTOS, .FILES])
    }

    func testNoUsableSourceIsAnError() {
        let input = FileElementInput(table: "docs", column: "file", type: .FILE_INPUT)

        XCTAssertEqual(error(input, FileElementOptions(sources: [])), .emptySources)
        XCTAssertEqual(error(input, FileElementOptions(allowedFileType: [".pdf"], sources: [.PHOTOS])), .emptySources)
        XCTAssertEqual(error(input, FileElementOptions(allowedFileType: ["image/png"], sources: [.CAMERA])), .emptySources)
    }

    func testErrorMessagesCarrySDKVersionPrefix() {
        let errors: [FileErrorCode] = [.emptyTable, .emptyColumn, .emptyAllowedFileTypes, .invalidAllowedFileTypeEntry,
                                       .nonPositiveOption(name: "maxFileSize"), .emptySources,
                                       .skyflowIDNotSupportedForMultiFile, .noFileElements, .uploadInProgress]
        for error in errors {
            XCTAssertTrue(error.message.hasPrefix(LangAndVersion), error.message)
            XCTAssertEqual(error.code, 400)
        }
        XCTAssertTrue(FileErrorCode.nonPositiveOption(name: "maxFileCount").message.contains("maxFileCount"))
    }

    func testErrorObjectIsSkyflowError() {
        let error = FileErrorCode.emptyTable.getErrorObject(contextOptions: ContextOptions())

        XCTAssertEqual(error.code, 400)
        XCTAssertEqual(error.localizedDescription, FileErrorCode.emptyTable.message)
    }
}
