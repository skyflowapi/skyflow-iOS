//
//  CollectCallback.swift
//  Skyflow
//
//  Created by Bharti Sagar  on 13/08/26.
//

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
