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

public class DemoAPICallback: Callback {
    var receivedResponse: String = ""
    var xml: String = ""
    var expectation: XCTestExpectation
    var data: [String: Any] = [:]
    var error: NSError? = nil
    
    public init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    public func onSuccess(_ responseBody: Any) {
        self.receivedResponse = responseBody as! String
        expectation.fulfill()
    }
    
    public func onFailure(_ error: Any) {
        print(error)
        if error is NSError {
            self.error = error as! NSError
        } else if error is [String: Any] {
            self.data = (error as! [String: Any])
        }
        if error is SkyflowError {
            self.xml = (error as! SkyflowError).getXML()
        }
        expectation.fulfill()
    }
    
    public func update(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
}
