/*
 * Copyright (c) 2022 Skyflow
*/

// Holds access to a document the user picked in the Files picker without a copy being made
// (open in place). The URL is kept only inside the SDK; access is released on deinit.

import Foundation

internal final class SecurityScopedAccess: Equatable {
    let url: URL
    private let started: Bool

    init(_ url: URL) {
        self.url = url
        // False for files the app can already read (its own container); nothing to release then.
        self.started = url.startAccessingSecurityScopedResource()
    }

    deinit {
        if started {
            url.stopAccessingSecurityScopedResource()
        }
    }

    static func == (lhs: SecurityScopedAccess, rhs: SecurityScopedAccess) -> Bool {
        lhs === rhs
    }

    /// Runs `body` with a coordinated read of the document, which also downloads an iCloud file
    /// that is not on the device yet, into iCloud's own storage rather than the app's.
    static func coordinatedRead<T>(_ url: URL, _ body: (URL) throws -> T) throws -> T {
        var coordinationError: NSError?
        var result: Result<T, Error> = .failure(CocoaError(.fileReadUnknown))
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinationError) { readURL in
            result = Result { try body(readURL) }
        }
        if let coordinationError = coordinationError {
            throw coordinationError
        }
        return try result.get()
    }
}
