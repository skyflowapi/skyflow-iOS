//
//  skyflow_iOS_validateGetRecordTests.swift
//  
//
//  Created by Bharti Sagar on 12/06/23.
//

import Foundation
import XCTest
@testable import Skyflow

class skyflow_iOS_getTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(
            vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
            vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
            tokenProvider: DemoTokenProvider(),
            options: Options(logLevel: .DEBUG)))
    }

    override func tearDown() {
        skyflow = nil
    }

    
    func testGetInvalidToken(){
        
        class InvalidTokenProvider: TokenProvider {
            func getBearerToken(_ apiCallback: Callback) {
                apiCallback.onFailure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "TokenProvider error"]))
            }
        }
        
        let invalidTokenProvider = InvalidTokenProvider()
        let skyflow = Client(Configuration(vaultID: "2", vaultURL: "https://example.org", tokenProvider: invalidTokenProvider))
        let records = [
            "records": [
                [
                    "ids": [
                        "1",
                        "2",
                        "3"
                    ],
                    "table": "persons",
                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
                ],
                [
                    "ids": [
                        "1"
                    ],
                    "table": "persons",
                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "get call")
        
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.get(records: records, callback: callback)
        
        wait(for: [expectation], timeout: 30.0)

        let errorEntry = (callback.data["errors"] as? [Any])?[0]
        
        let errorMessage = ((errorEntry as? [String: Any])?["error"] as? Error)?.localizedDescription
        
        XCTAssertEqual(errorMessage, "TokenProvider error")
    }
    func testGetMethod(){
        class ValidTokenProvider: TokenProvider {
            func getBearerToken(_ apiCallback: Callback) {
                apiCallback.onSuccess("token")
            }
        }
        
        let validTokenProvider = ValidTokenProvider()
        let skyflow = Client(Configuration(vaultID: "2", vaultURL: "https://example.org", tokenProvider: validTokenProvider))

        let records = [
            "records": [
                [
                    "ids": [
                        "1",
                        "2",
                        "3"
                    ],
                    "table": "persons",
                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
                ],
                [
                    "ids": [
                        "1"
                    ],
                    "table": "persons",
                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "get call")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.get(records: records,options: GetOptions(tokens: true), callback: callback)
            
        wait(for: [expectation], timeout: 1.0)
        print(callback.receivedResponse)
        XCTAssertTrue(callback.data.description.contains(ErrorCodes.REDACTION_WITH_TOKEN_NOT_SUPPORTED().description))
    }
    
    
}
