/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 20/10/21.
//

import Foundation
import XCTest
@testable import Skyflow
@testable import SkyflowCore

// swiftlint:disable:next type_body_length
class skyflow_iOS_getByIdTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(
            vaultID: (ProcessInfo.processInfo.environment["VAULT_ID"] ?? "dummy_vault_id"),
            vaultURL: (ProcessInfo.processInfo.environment["VAULT_URL"] ?? "https://dummy.vault.skyflowapis.dev/"),
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
        let skyflow = Client(Configuration(vaultID: (ProcessInfo.processInfo.environment["VAULT_ID"] ?? "dummy_vault_id"), vaultURL: (ProcessInfo.processInfo.environment["VAULT_URL"] ?? "https://dummy.vault.skyflowapis.dev/"), tokenProvider: invalidTokenProvider))
        let records = [
            "records": [
                [
                    "ids": [
                        (ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID1"] ?? "dummy_skyflow_id_1"),
                        (ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID2"] ?? "dummy_skyflow_id_2"),
                        (ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID3"] ?? "dummy_skyflow_id_3")
                    ],
                    "table": "persons",
                    "redaction": RedactionType.PLAIN_TEXT
                ],
                [
                    "ids": [
                        (ProcessInfo.processInfo.environment["TEST_SKYFLOW_ID3"] ?? "dummy_skyflow_id_3")
                    ],
                    "table": "persons",
                    "redaction": RedactionType.PLAIN_TEXT
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

    func testGetByIdEmptyVaultURL() {
        // Client.getById()'s vault-level errors route through callRevealOnFailure, which
        // wraps the NSError in {"errors": [errorObject]} rather than passing it through raw.
        let expectation = XCTestExpectation(description: "getById with empty vaultURL should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let clientWithEmptyURL = Client(Configuration(vaultID: "id", vaultURL: "", tokenProvider: DemoTokenProvider()))

        clientWithEmptyURL.getById(records: ["records": [["ids": ["id1"], "table": "persons"]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        let errors = callback.data["errors"] as! [NSError]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0].localizedDescription, ErrorCodes.EMPTY_VAULT_URL().description)
    }

}
