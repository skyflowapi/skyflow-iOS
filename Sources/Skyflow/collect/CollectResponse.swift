/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

public struct CollectResponse {
    public let records: [CollectRecord]

    public init?(_ responseBody: Any) {
        guard let dict = responseBody as? [String: Any],
              let recordDicts = dict["records"] as? [[String: Any]] else { return nil }
        self.records = recordDicts.map { CollectRecord($0) }
    }
}

// Each entry in "records" is either a successfully inserted/updated record (error is nil) or a
// failed one (error is non-nil) - the vault returns both together in the same array, each tagged
// with its own httpCode.
public struct CollectRecord {
    public let tableName: String?
    public let skyflowID: String?
    // Keyed by column name, e.g. "card_number": [{"token": "...", "tokenGroupName": "..."}].
    public let fields: [String: Any]?
    // Keyed by column name, e.g. "card_number": [{"data": "...", "hashName": "..."}].
    public let hashedData: [String: Any]?
    public let httpCode: Int
    public let error: String?

    init(_ dict: [String: Any]) {
        self.tableName = dict["tableName"] as? String
        self.skyflowID = dict["skyflowID"] as? String
        self.fields = dict["fields"] as? [String: Any]
        self.hashedData = dict["hashedData"] as? [String: Any]
        self.httpCode = dict["httpCode"] as? Int ?? 0
        self.error = dict["error"] as? String
    }
}

// A ready-made Skyflow.Callback that unwraps the raw responseBody/error into CollectResponse
// for you. Use it directly with the original callback-based collect(callback:options:).
public class CollectCallback: Callback {
    private let successHandler: (CollectResponse) -> Void
    private let failureHandler: (SkyflowError) -> Void

    public init(onSuccess: @escaping (CollectResponse) -> Void, onFailure: @escaping (SkyflowError) -> Void) {
        self.successHandler = onSuccess
        self.failureHandler = onFailure
    }

    public func onSuccess(_ responseBody: Any) {
        guard let response = CollectResponse(responseBody) else {
            failureHandler(SkyflowError.wrap(responseBody))
            return
        }
        successHandler(response)
    }

    // Delivered when the entire request fails (e.g. vault not found, network error) rather
    // than a per-record failure inside CollectResponse.records, and for client-side validation
    // failures. Always normalized into a Skyflow.SkyflowError - see SkyflowError.wrap.
    public func onFailure(_ error: Any) {
        failureHandler(SkyflowError.wrap(error))
    }
}
