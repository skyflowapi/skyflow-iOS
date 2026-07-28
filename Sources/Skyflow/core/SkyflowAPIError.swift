/*
 * Copyright (c) 2022 Skyflow
*/

// Shared structured-error shape delivered via Callback.onFailure when an entire Collect or
// Reveal request fails (e.g. vault not found, network error) rather than a per-record/per-token
// failure inside the corresponding records array.

import Foundation

public struct SkyflowAPIError {
    // Shadows Swift's built-in Error protocol within this scope - use Swift.Error if ever
    // needed here.
    public struct Error {
        public let grpcCode: Int?
        public let httpCode: Int?
        public let message: String?
        public let httpStatus: String?
        public let details: [Any]?

        init(_ dict: [String: Any]) {
            self.grpcCode = dict["grpcCode"] as? Int
            self.httpCode = dict["httpCode"] as? Int
            self.message = dict["message"] as? String
            self.httpStatus = dict["httpStatus"] as? String
            self.details = dict["details"] as? [Any]
        }
    }

    public let error: Error

    public init?(_ error: Any) {
        guard let dict = error as? [String: Any],
              let detail = dict["error"] as? [String: Any] else { return nil }
        self.error = Error(detail)
    }
}
