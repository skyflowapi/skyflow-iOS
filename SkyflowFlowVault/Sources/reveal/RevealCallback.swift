//
//  RevealCallback.swift
//  Skyflow
//
//  Created by Bharti Sagar  on 13/08/26.
//

// A ready-made Skyflow.Callback that unwraps the raw responseBody/error into RevealResponse
// for you. Use it directly with the callback-based reveal(callback:options:) - RevealValueCallback
// merges success/failure into one "records" array (matching Collect's convention), so the same
// RevealResponse type used for Client.detokenize() applies here too.
public class RevealCallback: Callback {
    private let successHandler: (RevealResponse) -> Void
    private let failureHandler: (SkyflowError) -> Void

    public init(onSuccess: @escaping (RevealResponse) -> Void, onFailure: @escaping (SkyflowError) -> Void) {
        self.successHandler = onSuccess
        self.failureHandler = onFailure
    }

    public func onSuccess(_ responseBody: Any) {
        guard let response = RevealResponse(responseBody) else {
            failureHandler(SkyflowError.wrap(responseBody))
            return
        }
        successHandler(response)
    }

    // Delivered when the entire request fails (e.g. vault not found, network error) rather
    // than a per-token failure inside RevealResponse.records, and for client-side validation
    // failures (empty vaultID, unmounted element, etc.). Always normalized into a
    // Skyflow.SkyflowError - see SkyflowError.wrap.
    public func onFailure(_ error: Any) {
        failureHandler(SkyflowError.wrap(error))
    }
}
