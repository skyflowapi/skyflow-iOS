/*
 * Copyright (c) 2022 Skyflow
*/

// Writes a multipart/form-data body to disk, streaming the file in chunks so memory use does
// not grow with file size. The result is sent with URLSession.uploadTask(with:fromFile:).

import Foundation

internal struct MultipartFormWriter {
    struct FilePart {
        let fieldName: String
        let fileName: String
        let mimeType: String
        let source: URL
    }

    static let chunkSize = 64 * 1024

    let boundary: String

    init(boundary: String = "skyflow-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    func write(fields: [(name: String, value: String)], file: FilePart, to destination: URL) throws {
        let handle = try FileHandle(forWritingTo: destination)
        defer { try? handle.close() }
        try writeHead(fields: fields, fieldName: file.fieldName, fileName: file.fileName, mimeType: file.mimeType, to: handle)
        try copyContents(of: file.source, to: handle)
        try writeTail(to: handle)
    }

    // Head and tail are separate so the file contents can come from somewhere other than a
    // file URL (a Photos library stream).
    func writeHead(fields: [(name: String, value: String)], fieldName: String, fileName: String, mimeType: String,
                   to handle: FileHandle) throws {
        for field in fields {
            try Self.append("--\(boundary)\r\n", to: handle)
            try Self.append("Content-Disposition: form-data; name=\"\(Self.escape(field.name))\"\r\n\r\n", to: handle)
            try Self.append("\(field.value)\r\n", to: handle)
        }

        try Self.append("--\(boundary)\r\n", to: handle)
        try Self.append("Content-Disposition: form-data; name=\"\(Self.escape(fieldName))\"; filename=\"\(Self.escape(fileName))\"\r\n", to: handle)
        try Self.append("Content-Type: \(mimeType)\r\n\r\n", to: handle)
    }

    func writeTail(to handle: FileHandle) throws {
        try Self.append("\r\n--\(boundary)--\r\n", to: handle)
    }

    // Percent-encodes the three characters that could break out of a quoted header value,
    // as the WHATWG multipart/form-data encoding does.
    static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "%22")
            .replacingOccurrences(of: "\r", with: "%0D")
            .replacingOccurrences(of: "\n", with: "%0A")
    }

    private func copyContents(of source: URL, to handle: FileHandle) throws {
        guard let input = InputStream(url: source) else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        input.open()
        defer { input.close() }
        var buffer = [UInt8](repeating: 0, count: Self.chunkSize)
        while true {
            let read = input.read(&buffer, maxLength: buffer.count)
            if read < 0 {
                throw input.streamError ?? CocoaError(.fileReadUnknown)
            }
            if read == 0 { break }
            try Self.append(Data(buffer[0..<read]), to: handle)
        }
    }

    private static func append(_ text: String, to handle: FileHandle) throws {
        try append(Data(text.utf8), to: handle)
    }

    // The non-throwing FileHandle.write(_:) raises an Objective-C exception on failure (for
    // example a full disk), which Swift cannot catch and would crash the host app.
    static func append(_ data: Data, to handle: FileHandle) throws {
        if #available(iOS 13.4, *) {
            try handle.write(contentsOf: data)
        } else {
            handle.write(data)
        }
    }
}
