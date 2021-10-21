import Foundation
import XCTest
import Skyflow

public class DemoTokenProvider: TokenProvider {
    public func getBearerToken(_ apiCallback: Callback) {
        if let url = URL(string: "http://localhost:8000/js/userToken") {
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
    var expectation: XCTestExpectation
    var data: [String: Any] = [:]

    public init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    public func onSuccess(_ responseBody: Any) {
        defer{
            expectation.fulfill()
        }
        do {
            let dataString = String(data: try JSONSerialization.data(withJSONObject: responseBody), encoding: .utf8)
            if let unwrapped = dataString {
                self.receivedResponse = unwrapped
            }
        } catch {
            print("error decoding data ==>", responseBody)
        }
        
        expectation.fulfill()
    }

    public func onFailure(_ error: Any) {
        if let data = error as? [String: Any] {
            self.data = data
        } else {
            self.receivedResponse = (error as! Error).localizedDescription
        }
        expectation.fulfill()
    }
}
