/*
 * Copyright (c) 2022 Skyflow
*/

// A file the user picked: a copy in the SDK-owned SecureFileStore, the user's original document
// opened in place (Files), or (when the app already has full photo access) only a Photos library
// identifier. Never exposed publicly: the app must not be able to read the bytes, URL or
// original name.

import Foundation

internal struct PickedFile: Equatable {
    let id: UUID
    // For an original opened in place or a library photo there is no copy: this points outside
    // the store, so removing it is a no-op and never touches the user's file.
    let url: URL
    let name: String
    let size: Int
    let typeIdentifier: String?
    let photoAssetID: String?
    // Set for a document opened in place. Access ends when the last copy of this value is
    // released (removed, replaced, uploaded, or the element goes away).
    let access: SecurityScopedAccess?

    static let noLocalCopy = URL(fileURLWithPath: "/dev/null")

    init(id: UUID = UUID(), url: URL, name: String, size: Int, typeIdentifier: String? = nil,
         photoAssetID: String? = nil, access: SecurityScopedAccess? = nil) {
        self.id = id
        self.url = url
        self.name = name
        self.size = size
        self.typeIdentifier = typeIdentifier ?? FileTypeResolver.typeIdentifier(forExtension: (name as NSString).pathExtension)
        self.photoAssetID = photoAssetID
        self.access = access
    }

    var isOpenInPlace: Bool {
        access != nil
    }

    static func libraryPhoto(assetID: String, info: PhotoAssetInfo) -> PickedFile {
        PickedFile(url: noLocalCopy, name: info.name, size: info.size, typeIdentifier: info.typeIdentifier,
                   photoAssetID: assetID)
    }

    var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    var mimeType: String? {
        guard let typeIdentifier = typeIdentifier, FileTypeResolver.isDynamic(typeIdentifier) == false else { return nil }
        return FileTypeResolver.mimeType(forTypeIdentifier: typeIdentifier)?.lowercased()
    }
}
