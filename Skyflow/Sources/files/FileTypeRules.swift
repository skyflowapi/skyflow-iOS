/*
 * Copyright (c) 2022 Skyflow
*/

// Allowed and always-blocked file types, and the type identifiers handed to the pickers.
//
// Extension and MIME entries match by exact type, not UTType conformance: conformance would
// let ".txt" accept CSV or source files, which skyflow-js (exact MIME matching) rejects.
// Only MIME wildcards such as "image/*" use conformance, so they cover HEIC, PNG and so on.

import Foundation

internal struct FileTypeRules {
    // Mirrors skyflow-js DANGEROUS_FILE_TYPE, plus the matching extensions so a file whose
    // MIME type cannot be resolved is still caught. Matched exactly: conformance to
    // public.zip-archive would also block .docx/.xlsx, which are zip containers.
    static let blockedExtensions: Set<String> = ["zip", "rar", "deb", "exe", "ipa"]
    static let blockedMIMETypes: Set<String> = [
        "application/zip",
        "application/vnd.debian.binary-package",
        "application/vnd.microsoft.portable-executable",
        "application/vnd.rar",
    ]

    private static let wildcardTypeIdentifiers: [String: String] = [
        "image/": "public.image",
        "video/": "public.movie",
        "audio/": "public.audio",
        "text/": "public.text",
    ]

    enum Entry: Equatable {
        case wildcard(prefix: String)
        case mime(String)
        case fileExtension(String)

        init(_ raw: String) {
            let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if value.hasSuffix("/*") {
                self = .wildcard(prefix: String(value.dropLast()))
            } else if value.contains("/") {
                self = .mime(value)
            } else {
                self = .fileExtension(value.hasPrefix(".") ? String(value.dropFirst()) : value)
            }
        }

        var typeIdentifier: String? {
            let identifier: String?
            switch self {
            case .wildcard(let prefix): identifier = FileTypeRules.wildcardTypeIdentifiers[prefix]
            case .mime(let mime): identifier = FileTypeResolver.typeIdentifier(forMIMEType: mime)
            case .fileExtension(let ext): identifier = FileTypeResolver.typeIdentifier(forExtension: ext)
            }
            guard let resolved = identifier, FileTypeResolver.isDynamic(resolved) == false else { return nil }
            return resolved
        }

        func matches(_ file: PickedFile) -> Bool {
            switch self {
            case .wildcard(let prefix):
                if file.mimeType?.hasPrefix(prefix) == true { return true }
                guard let parent = typeIdentifier, let fileType = file.typeIdentifier else { return false }
                return FileTypeResolver.conforms(fileType, to: parent)
            case .mime(let mime):
                return file.mimeType == mime || sameType(as: file)
            case .fileExtension(let ext):
                return file.fileExtension == ext || sameType(as: file)
            }
        }

        private func sameType(as file: PickedFile) -> Bool {
            guard let identifier = typeIdentifier else { return false }
            return file.typeIdentifier == identifier
        }
    }

    let entries: [Entry]?

    init(allowedFileTypes: [String]?) {
        self.entries = allowedFileTypes?.map(Entry.init)
    }

    func isBlocked(_ file: PickedFile) -> Bool {
        if Self.blockedExtensions.contains(file.fileExtension) { return true }
        if let mime = file.mimeType, Self.blockedMIMETypes.contains(mime) { return true }
        return false
    }

    func isAllowed(_ file: PickedFile) -> Bool {
        guard let entries = entries else { return true }
        return entries.contains { $0.matches(file) }
    }

    func accepts(_ file: PickedFile) -> Bool {
        isAllowed(file) && isBlocked(file) == false
    }

    var allowsImages: Bool {
        guard let entries = entries else { return true }
        return entries.contains { entry in
            if case .wildcard(let prefix) = entry { return prefix == "image/" }
            guard let identifier = entry.typeIdentifier else { return false }
            return FileTypeResolver.conforms(identifier, to: FileTypeResolver.image)
        }
    }

    // Camera photos are always uploaded as JPEG.
    var allowsCameraPhotos: Bool {
        let photo = Self.probe(typeIdentifier: FileTypeResolver.jpeg)
        return isAllowed(photo) && isBlocked(photo) == false
    }

    // An entry the system cannot resolve (an unknown extension, say) cannot be expressed as a
    // picker filter, so the picker falls back to showing everything and the validator decides.
    var pickerTypeIdentifiers: [String] {
        guard let entries = entries else { return [FileTypeResolver.anyItem] }
        var identifiers: [String] = []
        for entry in entries {
            let identifier = entry.typeIdentifier ?? FileTypeResolver.anyItem
            if identifiers.contains(identifier) == false {
                identifiers.append(identifier)
            }
        }
        return identifiers
    }

    // Chooses which representation to load from a photo. Prefers one the rules already
    // accept; otherwise asks for JPEG when that is allowed, which makes the system transcode
    // HEIC photos. Falls back to the first representation so the validator can report it.
    func photoTypeIdentifier(registered: [String]) -> String? {
        let images = registered.filter { FileTypeResolver.conforms($0, to: FileTypeResolver.image) }
        let candidates = images.isEmpty ? registered : images
        if let accepted = candidates.first(where: { isAllowed(Self.probe(typeIdentifier: $0)) && isBlocked(Self.probe(typeIdentifier: $0)) == false }) {
            return accepted
        }
        if images.isEmpty == false, isAllowed(Self.probe(typeIdentifier: FileTypeResolver.jpeg)) {
            return FileTypeResolver.jpeg
        }
        return candidates.first
    }

    private static func probe(typeIdentifier: String) -> PickedFile {
        let ext = FileTypeResolver.preferredExtension(forTypeIdentifier: typeIdentifier) ?? ""
        return PickedFile(url: URL(fileURLWithPath: "/dev/null"), name: "probe.\(ext)", size: 0, typeIdentifier: typeIdentifier)
    }
}
