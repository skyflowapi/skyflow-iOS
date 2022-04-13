//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 20/10/21.
//

import Foundation
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
class skyflow_iOS_getByIdTests: XCTestCase {
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

    
    func testGetByIdInvalidToken(){
        
        class InvalidTokenProvider: TokenProvider {
            func getBearerToken(_ apiCallback: Callback) {
                apiCallback.onFailure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "TokenProvider error"]))
            }
        }
        
        let invalidTokenProvider = InvalidTokenProvider()
        let skyflow = Client(Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!, vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!, tokenProvider: invalidTokenProvider))
        let records = [
            "records": [
                [
                    "ids": [
                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID1"]!,
                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID2"]!,
                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID3"]!
                    ],
                    "table": "persons",
                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
                ],
                [
                    "ids": [
                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID3"]!
                    ],
                    "table": "persons",
                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "getById call")
        
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.getById(records: records, callback: callback)
        
        wait(for: [expectation], timeout: 30.0)

        let errorEntry = (callback.data["errors"] as? [Any])?[0]
        
        let errorMessage = ((errorEntry as? [String: Any])?["error"] as? Error)?.localizedDescription
        
        XCTAssertEqual(errorMessage, "TokenProvider error")
    }
    
}
