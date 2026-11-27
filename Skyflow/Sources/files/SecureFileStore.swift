/*
 * Copyright (c) 2022 Skyflow
*/

// SDK-owned folder for picked files and multipart bodies. Files are created with complete
// data protection (unreadable while the device is locked). tmp/ is never backed up. Each
// copy is deleted when it is uploaded, removed, or its element goes away; the folder is
// emptied once per process to clear anything left behind by a crash.

import Foundation

internal final class SecureFileStore {
    static let shared = SecureFileStore(baseDirectory: FileManager.default.temporaryDirectory)

    let directory: URL
    private let fileManager: FileManager

    init(baseDirectory: URL, fileManager: FileManager = .default) {
        self.directory = baseDirectory.appendingPathComponent("com.skyflow.files", isDirectory: true)
        self.fileManager = fileManager
        removeAll()
    }

    /// Takes ownership of `source`. `move` is for files the app already owns (document picker
    /// imports), so no second plaintext copy is left behind; system-owned temporary files
    /// (photo picker) must be copied because the system deletes them itself.
    func importFile(from source: URL, move: Bool) throws -> URL {
        try createDirectoryIfNeeded()
        let destination = makeURL(pathExtension: source.pathExtension)
        if move {
            try fileManager.moveItem(at: source, to: destination)
        } else {
            try fileManager.copyItem(at: source, to: destination)
        }
        try protect(destination)
        return destination
    }

    /// Writes `data` to a new protected file (used for camera photos, which exist only in memory).
    func write(_ data: Data, pathExtension: String) throws -> URL {
        try createDirectoryIfNeeded()
        let url = makeURL(pathExtension: pathExtension)
        // Not .atomic: that writes through a temporary file outside this protected folder.
        try data.write(to: url, options: [.withoutOverwriting, .completeFileProtection])
        return url
    }

    /// A new, empty, protected file for writing (used for multipart bodies).
    func makeEmptyFile(pathExtension: String = "") throws -> URL {
        try createDirectoryIfNeeded()
        let url = makeURL(pathExtension: pathExtension)
        guard fileManager.createFile(atPath: url.path, contents: nil, attributes: [.protectionKey: FileProtectionType.complete]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return url
    }

    func contains(_ url: URL) -> Bool {
        url.standardizedFileURL.path.hasPrefix(directory.standardizedFileURL.path + "/")
    }

    func remove(_ url: URL) {
        guard contains(url) else { return }
        try? fileManager.removeItem(at: url)
    }

    func removeAll() {
        try? fileManager.removeItem(at: directory)
    }

    // Size from resource values, not attributesOfItem: the latter also returns dates, which
    // App Store review treats as a "required reason" API.
    func fileSize(of url: URL) throws -> Int {
        try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }

    private func makeURL(pathExtension: String) -> URL {
        let url = directory.appendingPathComponent(UUID().uuidString)
        return pathExtension.isEmpty ? url : url.appendingPathExtension(pathExtension)
    }

    private func createDirectoryIfNeeded() throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true,
                                        attributes: [.protectionKey: FileProtectionType.complete])
    }

    private func protect(_ url: URL) throws {
        try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
    }
}
