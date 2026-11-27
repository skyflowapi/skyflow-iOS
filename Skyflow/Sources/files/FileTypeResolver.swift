/*
 * Copyright (c) 2022 Skyflow
*/

// Maps between file extensions, MIME types and Uniform Type Identifiers. UTType needs
// iOS 14; the CoreServices functions cover iOS 13 (they are deprecated only from iOS 15,
// so they compile without warnings at the iOS 13 deployment target).

import Foundation
import MobileCoreServices
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

internal enum FileTypeResolver {
    static let anyItem = "public.item"
    static let image = "public.image"
    static let jpeg = "public.jpeg"

    static func typeIdentifier(forExtension fileExtension: String) -> String? {
        guard fileExtension.isEmpty == false else { return nil }
        if #available(iOS 14.0, *) {
            return UTType(filenameExtension: fileExtension)?.identifier
        }
        return UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?
            .takeRetainedValue() as String?
    }

    static func typeIdentifier(forMIMEType mimeType: String) -> String? {
        guard mimeType.isEmpty == false else { return nil }
        if #available(iOS 14.0, *) {
            return UTType(mimeType: mimeType)?.identifier
        }
        return UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?
            .takeRetainedValue() as String?
    }

    static func mimeType(forTypeIdentifier identifier: String) -> String? {
        if #available(iOS 14.0, *) {
            return UTType(identifier)?.preferredMIMEType
        }
        return UTTypeCopyPreferredTagWithClass(identifier as CFString, kUTTagClassMIMEType)?
            .takeRetainedValue() as String?
    }

    static func preferredExtension(forTypeIdentifier identifier: String) -> String? {
        if #available(iOS 14.0, *) {
            return UTType(identifier)?.preferredFilenameExtension
        }
        return UTTypeCopyPreferredTagWithClass(identifier as CFString, kUTTagClassFilenameExtension)?
            .takeRetainedValue() as String?
    }

    static func conforms(_ identifier: String, to parent: String) -> Bool {
        if #available(iOS 14.0, *) {
            guard let type = UTType(identifier), let parentType = UTType(parent) else { return false }
            return type.conforms(to: parentType)
        }
        return UTTypeConformsTo(identifier as CFString, parent as CFString)
    }

    // Dynamic identifiers ("dyn.…") are what the system invents for an unknown extension or
    // MIME type. They conform to nothing useful, so they are treated as unresolved.
    static func isDynamic(_ identifier: String) -> Bool {
        identifier.hasPrefix("dyn.")
    }
}
