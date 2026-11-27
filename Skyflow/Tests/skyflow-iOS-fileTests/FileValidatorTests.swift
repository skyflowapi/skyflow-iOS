/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow

final class FileValidatorTests: XCTestCase {
    private func picked(_ name: String, size: Int = 1_000) -> PickedFile {
        FileTestSupport.picked(name, size: size)
    }

    private func validate(_ files: [PickedFile], type: FileElementType = .FILE_INPUT,
                          _ options: FileElementOptions = FileElementOptions()) -> FileValidationError? {
        FileValidator.validate(files, configuration: FileTestSupport.configuration(type: type, options: options))
    }

    // MARK: - Empty selection

    func testEmptyOptionalElementIsValid() {
        XCTAssertNil(validate([]))
        XCTAssertNil(validate([], type: .MULTI_FILE_INPUT))
    }

    func testEmptyRequiredElementReportsNoFileSelected() {
        XCTAssertEqual(validate([], FileElementOptions(required: true)), .noFileSelected)
        XCTAssertEqual(validate([], type: .MULTI_FILE_INPUT, FileElementOptions(required: true)), .noFileSelected)
    }

    // MARK: - FILE_INPUT

    func testValidSingleFile() {
        XCTAssertNil(validate([picked("scan.pdf")]))
    }

    func testBlockedTypeRejectedEvenWhenAllowed() {
        XCTAssertEqual(validate([picked("a.zip")], FileElementOptions(allowedFileType: [".zip"])), .invalidFileType)
    }

    func testDisallowedTypeRejected() {
        XCTAssertEqual(validate([picked("a.png")], FileElementOptions(allowedFileType: [".pdf"])), .invalidFileType)
    }

    func testSingleFileSizeLimitIsFixedAt32MB() {
        XCTAssertNil(validate([picked("a.pdf", size: 32_000_000)]))
        XCTAssertEqual(validate([picked("a.pdf", size: 32_000_001)]), .invalidFileSize)
        // maxFileSize is ignored for FILE_INPUT.
        XCTAssertNil(validate([picked("a.pdf", size: 20)], FileElementOptions(maxFileSize: 10)))
    }

    func testEmptyFiles() {
        XCTAssertNil(validate([picked("a.pdf", size: 0)]))
        XCTAssertEqual(validate([picked("a.pdf", size: 0)], FileElementOptions(blockEmptyFiles: true)), .invalidFileSize)
    }

    func testFileNameCheckedOnlyWhenPreserved() {
        XCTAssertEqual(validate([picked("my scan.pdf")]), .invalidFileName)
        XCTAssertNil(validate([picked("my scan.pdf")], FileElementOptions(preserveFileName: false)))
    }

    func testTypeErrorTakesPrecedenceOverNameError() {
        XCTAssertEqual(validate([picked("bad name.zip")]), .invalidFileType)
    }

    // MARK: - MULTI_FILE_INPUT

    func testValidMultipleFiles() {
        XCTAssertNil(validate([picked("a.pdf"), picked("b.pdf")], type: .MULTI_FILE_INPUT))
    }

    func testCountAtLimitIsValid() {
        let files = (1...4).map { picked("f\($0).pdf") }
        XCTAssertNil(validate(files, type: .MULTI_FILE_INPUT))
    }

    func testCountExceeded() {
        let files = (1...3).map { picked("f\($0).pdf") }
        XCTAssertEqual(validate(files, type: .MULTI_FILE_INPUT, FileElementOptions(maxFileCount: 2)), .fileCountExceeded(maxCount: 2))
    }

    func testCountAndSizeExceeded() {
        let files = [picked("a.pdf", size: 5), picked("b.pdf", size: 50), picked("c.pdf", size: 5)]
        XCTAssertEqual(validate(files, type: .MULTI_FILE_INPUT, FileElementOptions(maxFileSize: 10, maxFileCount: 2)),
                       .fileCountAndSizeExceeded(maxCount: 2, maxSize: 10))
    }

    func testOversizedFilesAreNamed() {
        let files = [picked("a.pdf", size: 50), picked("b.pdf", size: 5), picked("c.pdf", size: 50)]
        XCTAssertEqual(validate(files, type: .MULTI_FILE_INPUT, FileElementOptions(maxFileSize: 10)),
                       .fileSizeExceeded(maxSize: 10, fileNames: ["a.pdf", "c.pdf"]))
    }

    func testSizeTakesPrecedenceOverTypeInMultiFile() {
        let files = [picked("a.png", size: 5), picked("b.pdf", size: 50)]
        XCTAssertEqual(validate(files, type: .MULTI_FILE_INPUT, FileElementOptions(allowedFileType: [".pdf"], maxFileSize: 10)),
                       .fileSizeExceeded(maxSize: 10, fileNames: ["b.pdf"]))
    }

    func testFirstPerFileErrorReported() {
        let files = [picked("ok.pdf"), picked("bad name.pdf"), picked("a.zip")]
        XCTAssertEqual(validate(files, type: .MULTI_FILE_INPUT), .invalidFileName)
    }

    func testEmptyFileInMultiFile() {
        let files = [picked("a.pdf"), picked("b.pdf", size: 0)]
        XCTAssertEqual(validate(files, type: .MULTI_FILE_INPUT, FileElementOptions(blockEmptyFiles: true)), .invalidFileSize)
    }

    // MARK: - Messages

    func testMessagesMatchSkyflowJS() {
        XCTAssertEqual(FileValidationError.noFileSelected.reportMessage, "No File Selected")
        XCTAssertEqual(FileValidationError.invalidFileType.reportMessage, "Invalid File Type.")
        XCTAssertEqual(FileValidationError.invalidFileSize.reportMessage, "Invalid File Size")
        XCTAssertEqual(FileValidationError.invalidFileName.reportMessage,
                       "Invalid File Name. Only alphanumeric characters and !-_.*() are allowed.")
        XCTAssertEqual(FileValidationError.fileCountExceeded(maxCount: 4).reportMessage,
                       "You can upload up to 4 files. Remove file(s) to add more")
        XCTAssertEqual(FileValidationError.fileCountAndSizeExceeded(maxCount: 4, maxSize: 32_000_000).reportMessage,
                       "You can upload up to 4 files, each under 32 MB")
        XCTAssertEqual(FileValidationError.fileSizeExceeded(maxSize: 10_000_000, fileNames: ["a.pdf"]).displayMessage,
                       "File exceeds the 10 MB size limit. Choose a smaller file")
        XCTAssertEqual(FileValidationError.fileSizeExceeded(maxSize: 10_000_000, fileNames: ["a.pdf", "b.pdf"]).displayMessage,
                       "a.pdf, b.pdf exceeds the 10 MB size limit. Remove it or choose a smaller file")
    }

    func testReportedMessagesNeverContainFileNames() {
        let error = FileValidationError.fileSizeExceeded(maxSize: 10, fileNames: ["passport-jane.pdf", "id.pdf"])

        XCTAssertFalse(error.reportMessage.contains("passport-jane"))
        XCTAssertTrue(error.displayMessage.contains("passport-jane"))
    }

    func testSizeLabelRounding() {
        XCTAssertEqual(FileValidationError.sizeLabel(32_000_000), "32 MB")
        XCTAssertEqual(FileValidationError.sizeLabel(1_500_000), "2 MB")
        XCTAssertEqual(FileValidationError.sizeLabel(400_000), "0 MB")
    }

    func testFileNamePattern() {
        for name in ["scan.pdf", "A-b_c.(1)!*.png", "x"] {
            XCTAssertTrue(FileValidator.isValidFileName(name), name)
        }
        for name in ["", "my scan.pdf", "../etc/passwd", "a/b.pdf", "résumé.pdf", "a\"b.pdf", "a\nb.pdf"] {
            XCTAssertFalse(FileValidator.isValidFileName(name), name)
        }
    }
}
