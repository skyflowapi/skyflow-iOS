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

// Each entry in "records" is either a successfully inserted/updated CollectRecordSuccess or a
// CollectRecordError describing why that entry failed - the vault returns both together in the same
// array, each tagged with its own httpCode.
public enum CollectRecord {
    case success(CollectRecordSuccess)
    case failure(CollectRecordError)

    init(_ dict: [String: Any]) {
        if let error = dict["error"] as? String {
            self = .failure(CollectRecordError(dict, error: error))
        } else {
            self = .success(CollectRecordSuccess(dict))
        }
    }

    public var record: CollectRecordSuccess? {
        if case .success(let record) = self { return record }
        return nil
    }

    public var error: CollectRecordError? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

public struct CollectRecordSuccess {
    public let tableName: String?
    public let skyflowID: String?
    // Keyed by column name, e.g. "card_number": [{"token": "...", "tokenGroupName": "..."}].
    public let fields: [String: Any]?
    // Keyed by column name, e.g. "card_number": [{"data": "...", "hashName": "..."}].
    public let hashedData: [String: Any]?
    public let httpCode: Int?

    init(_ dict: [String: Any]) {
        self.tableName = dict["tableName"] as? String
        self.skyflowID = dict["skyflowID"] as? String
        self.fields = dict["fields"] as? [String: Any]
        self.hashedData = dict["hashedData"] as? [String: Any]
        self.httpCode = dict["httpCode"] as? Int
    }
}

public struct CollectRecordError {
    public let error: String
    public let skyflowID: String?
    public let tableName: String?
    public let httpCode: Int?

    init(_ dict: [String: Any], error: String) {
        self.error = error
        self.skyflowID = dict["skyflowID"] as? String
        self.tableName = dict["tableName"] as? String
        self.httpCode = dict["httpCode"] as? Int
    }
}

// A ready-made Skyflow.Callback that unwraps the raw responseBody/error into CollectResponse
// for you. Use it directly with the original callback-based collect(callback:options:).
public class CollectCallback: Callback {
    private let successHandler: (CollectResponse) -> Void
    private let failureHandler: (Any) -> Void

    public init(onSuccess: @escaping (CollectResponse) -> Void, onFailure: @escaping (Any) -> Void) {
        self.successHandler = onSuccess
        self.failureHandler = onFailure
    }

    public func onSuccess(_ responseBody: Any) {
        guard let response = CollectResponse(responseBody) else {
            failureHandler(responseBody)
            return
        }
        successHandler(response)
    }

    // Delivered when the entire request fails (e.g. vault not found, network error) rather
    // than a per-record failure inside CollectResponse.records.
    public func onFailure(_ error: Any) {
        guard let apiError = SkyflowAPIError(error) else {
            failureHandler(error)
            return
        }
        failureHandler(apiError)
    }
}
