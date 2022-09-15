/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation
import XCTest
import Skyflow

public class DemoTokenProvider: TokenProvider {
    public func getBearerToken(_ apiCallback: Callback) {
        if let url = URL(string: ProcessInfo.processInfo.environment["TOKEN_ENDPOINT"]!) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { data, _, error in
                if error != nil {
                    print(error!)
                    return
                }
                if let safeData = data {
                    do {
                        let x = try JSONSerialization.jsonObject(with: safeData, options: []) as? [String: String]
                        if let accessToken = x?["accessToken"] {
                            apiCallback.onSuccess(accessToken)
                        }
                    } catch {
                        print("access token wrong format")
                    }
                }
            }
            task.resume()
        }
    }
}

public class InvalidTokenProvider: TokenProvider {
    public func getBearerToken(_ apiCallback: Callback) {
        apiCallback.onSuccess("invalid-token")
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
        if responseBody is String {
            self.receivedResponse = responseBody as! String
        }
        else {
            let dataString = String(data: try! JSONSerialization.data(withJSONObject: responseBody), encoding: .utf8)
            self.receivedResponse = dataString!
        }
        expectation.fulfill()
    }
    
    public func onFailure(_ error: Any) {
        print(error)
        if error is NSError {
            self.receivedResponse = String((error as! Error).localizedDescription)
        } else if error is [String: Any] {
            self.data = (error as! [String: Any])
        }
        expectation.fulfill()
    }
}
