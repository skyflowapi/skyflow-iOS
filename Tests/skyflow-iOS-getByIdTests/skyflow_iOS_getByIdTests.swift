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
        self.skyflow = Client(Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!, vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!, tokenProvider: DemoTokenProvider()))
    }

    override func tearDown() {
        skyflow = nil
    }

//    func testGetById(){
//        let records = [
//            "records": [
//                [
//                    "ids": [
//                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID1"]!,
//                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID2"]!,
//                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID3"]!
//                    ],
//                    "table": "persons",
//                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
//                ],
//                [
//                    "ids": [
//                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID3"]!
//                    ],
//                    "table": "persons",
//                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
//                ]
//            ]
//        ]
//        let expectation = XCTestExpectation(description: "getById call")
//
//        let callback = DemoAPICallback(expectation: expectation)
//
//        self.skyflow?.getById(records: records, callback: callback)
//
//        wait(for: [expectation], timeout: 30.0)
//
//        let responseData = Data(callback.receivedResponse.utf8)
//        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]
//        let responseEntries = jsonData["records"] as! [Any]
//
//        XCTAssertEqual(responseEntries.count, 4)
//        XCTAssertNotNil((responseEntries[0] as? [String: Any])?["fields"])
//
//    }
    
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
    
    func testGetByIdInvalidUrl(){
        let skyflow = Client(Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!, vaultURL: "https://dummy.area51.vault.skyflowapis.dev", tokenProvider: DemoTokenProvider()))
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
        
        XCTAssertNotNil(errorMessage?.contains("hostname could not be found"))
    }
    
    func testGetByIdInvalidVaultId(){
        let skyflow = Client(Configuration(vaultID: "invalid-id", vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!, tokenProvider: DemoTokenProvider()))
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
        
        XCTAssertNotNil(errorMessage?.contains("document does not exist"))
    }
    
//    func testGetByIdInvalidInput(){
//        let records = [
//            "records": [
//                [
//                    "ids": [
//                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID2"]!,
//                        "invalid-id"
//                    ],
//                    "table": "persons",
//                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
//                ],
//                [
//                    "ids": [
//                        ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID3"]!,
//                    ],
//                    "table": "persons",
//                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
//                ],
//                [
//                    "ids": [
//                        "invalid-id"
//                    ],
//                    "table": "persons",
//                    "redaction": Skyflow.RedactionType.PLAIN_TEXT
//                ]
//            ]
//        ]
//        let expectation = XCTestExpectation(description: "getById call")
//
//        let callback = DemoAPICallback(expectation: expectation)
//
//        self.skyflow?.getById(records: records, callback: callback)
//
//        wait(for: [expectation], timeout: 30.0)
//
//
//        let jsonData = callback.data
//
//        let responseEntries = jsonData["records"] as! [Any]
//        let errorEntries = jsonData["errors"] as! [Any]
//        XCTAssertEqual(responseEntries.count, 2)
//        XCTAssertEqual(errorEntries.count, 1)
//    }
    
    
    static var allTests = [
//        ("testGetById", testGetById),
        ("testGetByIdInvalidToken", testGetByIdInvalidToken),
        ("testGetByIdInvalidUrl", testGetByIdInvalidUrl),
        ("testGetByIdInvalidVaultId", testGetByIdInvalidVaultId),
//        ("testGetByIdInvalidInput", testGetByIdInvalidInput)
    ]
}
