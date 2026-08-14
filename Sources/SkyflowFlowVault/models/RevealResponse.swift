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

// Each entry in "records" is either a successfully revealed token (error is nil) or a failed one
// (error is non-nil) - the vault returns both together in the same array, each tagged with its
// own httpCode.
public struct RevealRecord {
    public let token: String?
    public let tokenGroupName: String?
    public let metadata: RevealMetadata?
    public let httpCode: Int
    public let error: String?

    init(_ dict: [String: Any]) {
        self.token = dict["token"] as? String
        self.tokenGroupName = dict["tokenGroupName"] as? String
        self.metadata = RevealMetadata(dict: dict["metadata"] as? [String: Any])
        self.httpCode = dict["httpCode"] as? Int ?? 0
        self.error = dict["error"] as? String
    }
}
