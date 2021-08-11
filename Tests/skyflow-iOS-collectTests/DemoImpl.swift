//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 10/08/21.
//

import Foundation
import XCTest
import skyflow_iOS

public class DemoTokenProvider : TokenProvider {
    
    public func getAccessToken(_ apiCallback: SkyflowCallback) {
        if let url = URL(string: "http://localhost:8000/js/analystToken") {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url){ data, response, error in
                if(error != nil){
                    print(error!)
                    return
                }
                if let safeData = data {
                    do{
                        let x = try JSONSerialization.jsonObject(with: safeData, options:[]) as? [String: String]
                        if let accessToken = x?["accessToken"]{
                            apiCallback.onSuccess(accessToken)
                        }
                    }
                    catch{
                        print("access token wrong format")
                    }
                }
            }
            task.resume()
        }
    }
}

public class DemoAPICallback: SkyflowCallback {
    
    var receivedResponse: String = ""
    var expectation: XCTestExpectation
    
    public init(expectation: XCTestExpectation){
        self.expectation = expectation
    }
    
    public func onSuccess(_ responseBody: String) {
        print(responseBody)
        self.receivedResponse = responseBody
        expectation.fulfill()
    }
    
    public func onFailure(_ error: Error) {
        print(error)
        self.receivedResponse = String(error.localizedDescription)
        expectation.fulfill()
    }
}
