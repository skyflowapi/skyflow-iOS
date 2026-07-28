/*
 * Copyright (c) 2022 Skyflow
*/

// Public typed wrappers around the dictionary delivered via Callback.onSuccess for both
// Client.detokenize() and Container<RevealContainer>.reveal() - both deliver the same merged
// {"records": [...]} shape (success and per-token failures share one array, matching Collect's
// convention). The Callback protocol still delivers raw [String: Any] as before - these types
// don't change that, they just wrap it directly (no JSONDecoder round-trip). Usage:
//
//   public func onSuccess(_ responseBody: Any) {
//       guard let response = Skyflow.RevealResponse(responseBody) else { return }
//       ...
//   }

import Foundation

public struct RevealResponse {
    public let records: [RevealRecord]

    public init?(_ responseBody: Any) {
        guard let dict = responseBody as? [String: Any],
              let recordDicts = dict["records"] as? [[String: Any]] else { return nil }
        self.records = recordDicts.map { RevealRecord($0) }
    }
}

// Each entry in "records" is either a successfully revealed RevealRecordSuccess or a
// RevealRecordError describing why that token failed - the vault returns both together in the
// same array, each tagged with its own httpCode.
public enum RevealRecord {
    case success(RevealRecordSuccess)
    case failure(RevealRecordError)

    init(_ dict: [String: Any]) {
        if let error = dict["error"] as? String {
            self = .failure(RevealRecordError(dict, error: error))
        } else {
            self = .success(RevealRecordSuccess(dict))
        }
    }

    public var record: RevealRecordSuccess? {
        if case .success(let record) = self { return record }
        return nil
    }

    public var error: RevealRecordError? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

public struct RevealRecordSuccess {
    public let token: String?
    public let tokenGroupName: String?
    // Keyed by whatever fields the vault includes (e.g. "skyflowID", "tableName").
    public let metadata: [String: Any]?
    public let httpCode: Int?

    init(_ dict: [String: Any]) {
        self.token = dict["token"] as? String
        self.tokenGroupName = dict["tokenGroupName"] as? String
        self.metadata = dict["metadata"] as? [String: Any]
        self.httpCode = dict["httpCode"] as? Int
    }
}

public struct RevealRecordError {
    public let error: String
    public let token: String?
    public let httpCode: Int?

    init(_ dict: [String: Any], error: String) {
        self.error = error
        self.token = dict["token"] as? String
        self.httpCode = dict["httpCode"] as? Int
    }
}

// A ready-made Skyflow.Callback that unwraps the raw responseBody/error into RevealResponse
// for you. Use it directly with the callback-based reveal(callback:options:) - RevealValueCallback
// merges success/failure into one "records" array (matching Collect's convention), so the same
// RevealResponse type used for Client.detokenize() applies here too.
public class RevealCallback: Callback {
    private let successHandler: (RevealResponse) -> Void
    private let failureHandler: (Any) -> Void

    public init(onSuccess: @escaping (RevealResponse) -> Void, onFailure: @escaping (Any) -> Void) {
        self.successHandler = onSuccess
        self.failureHandler = onFailure
    }

    public func onSuccess(_ responseBody: Any) {
        guard let response = RevealResponse(responseBody) else {
            failureHandler(responseBody)
            return
        }
        successHandler(response)
    }

    // Delivered when the entire request fails (e.g. vault not found, network error) rather
    // than a per-token failure inside RevealResponse.records, as a raw dictionary matching
    // SkyflowAPIError's shape - construct one yourself via SkyflowAPIError(error) if needed.
    // Note: RevealContainer.reveal()'s validation errors (empty vaultID, unmounted element,
    // etc.) are raw NSError, not this shape.
    public func onFailure(_ error: Any) {
        failureHandler(error)
    }
}
