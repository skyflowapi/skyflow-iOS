/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow

final class FileTypeRulesTests: XCTestCase {
    private func picked(_ name: String, size: Int = 1_000) -> PickedFile {
        FileTestSupport.picked(name, size: size)
    }

    func testEntryParsingNormalizesInput() {
        XCTAssertEqual(FileTypeRules.Entry(".PDF"), .fileExtension("pdf"))
        XCTAssertEqual(FileTypeRules.Entry("pdf"), .fileExtension("pdf"))
        XCTAssertEqual(FileTypeRules.Entry("  .png \n"), .fileExtension("png"))
        XCTAssertEqual(FileTypeRules.Entry("Application/PDF"), .mime("application/pdf"))
        XCTAssertEqual(FileTypeRules.Entry("image/*"), .wildcard(prefix: "image/"))
    }

    func testNilAllowsEverythingNotBlocked() {
        let rules = FileTypeRules(allowedFileTypes: nil)

        XCTAssertTrue(rules.isAllowed(picked("a.pdf")))
        XCTAssertTrue(rules.isAllowed(picked("no-extension")))
        XCTAssertTrue(rules.allowsImages)
        XCTAssertEqual(rules.pickerTypeIdentifiers, ["public.item"])
    }

    func testBlockedTypes() {
        let rules = FileTypeRules(allowedFileTypes: nil)

        for name in ["a.zip", "a.ZIP", "a.rar", "a.deb", "a.exe", "a.ipa"] {
            XCTAssertTrue(rules.isBlocked(picked(name)), name)
        }
        // Office documents are zip containers but must not be blocked.
        for name in ["a.docx", "a.xlsx", "a.pdf", "a.png"] {
            XCTAssertFalse(rules.isBlocked(picked(name)), name)
        }
    }

    func testExtensionEntriesMatchSameTypeAliases() {
        let rules = FileTypeRules(allowedFileTypes: [".jpg"])

        XCTAssertTrue(rules.isAllowed(picked("a.jpg")))
        XCTAssertTrue(rules.isAllowed(picked("a.JPEG")))
        XCTAssertFalse(rules.isAllowed(picked("a.png")))
    }

    func testExtensionEntriesDoNotMatchSubtypes() {
        // Conformance would let ".txt" accept CSV; skyflow-js rejects it, so must we.
        let rules = FileTypeRules(allowedFileTypes: [".txt"])

        XCTAssertTrue(rules.isAllowed(picked("notes.txt")))
        XCTAssertFalse(rules.isAllowed(picked("data.csv")))
    }

    func testMIMEEntries() {
        let rules = FileTypeRules(allowedFileTypes: ["application/pdf"])

        XCTAssertTrue(rules.isAllowed(picked("a.pdf")))
        XCTAssertFalse(rules.isAllowed(picked("a.png")))
    }

    func testWildcardEntriesUseConformance() {
        let rules = FileTypeRules(allowedFileTypes: ["image/*"])

        XCTAssertTrue(rules.isAllowed(picked("a.png")))
        XCTAssertTrue(rules.isAllowed(picked("a.heic")))
        XCTAssertTrue(rules.isAllowed(picked("a.jpg")))
        XCTAssertFalse(rules.isAllowed(picked("a.pdf")))
        XCTAssertEqual(rules.pickerTypeIdentifiers, ["public.image"])
    }

    func testUnknownExtensionMatchesByNameAndOpensPickerToAllItems() {
        let rules = FileTypeRules(allowedFileTypes: [".skyx"])

        XCTAssertTrue(rules.isAllowed(picked("export.skyx")))
        XCTAssertFalse(rules.isAllowed(picked("export.pdf")))
        XCTAssertEqual(rules.pickerTypeIdentifiers, ["public.item"])
        XCTAssertFalse(rules.allowsImages)
    }

    func testPickerTypesAreDeduplicated() {
        let rules = FileTypeRules(allowedFileTypes: [".jpg", ".jpeg", "image/jpeg", ".pdf"])

        XCTAssertEqual(rules.pickerTypeIdentifiers, ["public.jpeg", "com.adobe.pdf"])
    }

    func testAllowsImages() {
        XCTAssertTrue(FileTypeRules(allowedFileTypes: [".png"]).allowsImages)
        XCTAssertTrue(FileTypeRules(allowedFileTypes: ["image/heic"]).allowsImages)
        XCTAssertFalse(FileTypeRules(allowedFileTypes: [".pdf", "text/*"]).allowsImages)
    }

    func testPhotoTypePrefersAllowedRepresentation() {
        let rules = FileTypeRules(allowedFileTypes: [".png", ".jpg"])

        XCTAssertEqual(rules.photoTypeIdentifier(registered: ["public.heic", "public.jpeg"]), "public.jpeg")
    }

    func testPhotoTypeRequestsJPEGTranscodeWhenOnlyHEICAvailable() {
        let rules = FileTypeRules(allowedFileTypes: [".jpg"])

        XCTAssertEqual(rules.photoTypeIdentifier(registered: ["public.heic"]), "public.jpeg")
    }

    func testPhotoTypeFallsBackToFirstImageSoValidatorCanReport() {
        let rules = FileTypeRules(allowedFileTypes: [".pdf"])

        XCTAssertEqual(rules.photoTypeIdentifier(registered: ["public.heic", "public.png"]), "public.heic")
    }

    func testPhotoTypeWithoutRestrictionsUsesOriginal() {
        let rules = FileTypeRules(allowedFileTypes: nil)

        XCTAssertEqual(rules.photoTypeIdentifier(registered: ["com.apple.private.photos.thumbnail", "public.heic"]), "public.heic")
        XCTAssertNil(rules.photoTypeIdentifier(registered: []))
    }

    func testPickedFileDerivesTypeFromName() {
        let file = picked("Scan.PDF")

        XCTAssertEqual(file.fileExtension, "pdf")
        XCTAssertEqual(file.typeIdentifier, "com.adobe.pdf")
        XCTAssertEqual(file.mimeType, "application/pdf")
        XCTAssertNil(picked("unknown.skyx").mimeType)
        XCTAssertEqual(picked("noextension").fileExtension, "")
    }

    func testCameraPhotosNeedJPEG() {
        XCTAssertTrue(FileTypeRules(allowedFileTypes: nil).allowsCameraPhotos)
        XCTAssertTrue(FileTypeRules(allowedFileTypes: ["image/*"]).allowsCameraPhotos)
        XCTAssertTrue(FileTypeRules(allowedFileTypes: [".jpg"]).allowsCameraPhotos)
        XCTAssertTrue(FileTypeRules(allowedFileTypes: ["image/jpeg"]).allowsCameraPhotos)
        XCTAssertFalse(FileTypeRules(allowedFileTypes: ["image/png"]).allowsCameraPhotos)
        XCTAssertFalse(FileTypeRules(allowedFileTypes: [".pdf"]).allowsCameraPhotos)
    }
}
