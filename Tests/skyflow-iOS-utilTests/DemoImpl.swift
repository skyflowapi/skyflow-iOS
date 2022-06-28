/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation
import XCTest
import Skyflow

public class DemoTokenProvider: TokenProvider {
    public func getBearerToken(_ apiCallback: Callback) {
        apiCallback.onSuccess("dummy_token")
    }
}

public class DemoAPICallback: Callback {
    var receivedResponse: String = ""
    var expectation: XCTestExpectation
    var data: [String: Any] = [:]

    public init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    public func onSuccess(_ responseBody: Any) {
        print("success")
        if let response = responseBody as? String {
            self.receivedResponse = response
        }
        else {
            data = responseBody as! [String: Any]
        }
        expectation.fulfill()
    }

    public func onFailure(_ error: Any) {
        print("failure")
        print(error)
        if error is NSError {
            self.receivedResponse = String((error as! Error).localizedDescription)
        } else if error is [String: Any] {
            self.data = (error as! [String: Any])
        }
        expectation.fulfill()
    }
}
