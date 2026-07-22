/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow


final class skyflow_iOS_collectUtilTests: XCTestCase {
    var collectCallback: FlowVaultCollectAPICallback! = nil
    var defaultRecord: [String: Any] = ["records": [["table": "table", "fields": ["field": "value"]]]]

    override func setUp() {
        self.collectCallback = FlowVaultCollectAPICallback(callback: DemoAPICallback(expectation: XCTestExpectation()),
                                                  apiClient: APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider()),
                                                  records: defaultRecord,
                                                  options: FlowVaultICOptions(tokens: false, additionalFields: nil),
                                                  contextOptions: ContextOptions())
    }

    func testBuildFieldsDict() {
        let dict = ["key": "value", "nested": ["key": "value"]] as [String: Any]
        let result = self.collectCallback.buildFieldsDict(dict: dict)
        XCTAssertEqual(dict["key"] as! String, result["key"] as! String)
        XCTAssertEqual(dict["nested"] as! [String: String], result["nested"] as! [String: String])
    }

    func testOnSuccessInvalidUrl() {
        let expectation = XCTestExpectation(description: "Invalid URL should trigger failure")
        let callback = DemoAPICallback(expectation: expectation)
        self.collectCallback.apiClient.vaultURL = "Invalid url"
        self.collectCallback.callback = callback

        self.collectCallback.onSuccess("string")
        wait(for: [expectation], timeout: 20.0)

        let errorObject = callback.data["error"] as! [String: Any]
        let msg = errorObject["message"] as! String
        XCTAssert(msg.contains("unsupported URL"))
    }

    func testGetRequestSession() {
        let url = URL(string: "https://example.org")!
        do {
            let (request, session) = try self.collectCallback.getRequestSession(url: url)

            XCTAssertEqual(request.allHTTPHeaderFields!["Authorization"], "Bearer ") // From DemoTokenProvider()
            XCTAssertEqual(request.allHTTPHeaderFields!["Content-Type"], "application/json")
            XCTAssertEqual(request.allHTTPHeaderFields!["Accept"], "application/json")
            let body = try JSONSerialization.jsonObject(with: request.httpBody!, options: .allowFragments) as! [String: Any]
            let records = body["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["data"] as! [String: String], ["field": "value"])
            XCTAssertEqual(records[0]["tableName"] as! String, "table")

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGetCollectResponse() {
        let response = ["records": [["skyflowID": "SID", "tableName": "table"]]]

        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let result = try self.collectCallback.getCollectResponseBody(data: data)
            let records = result["records"] as! [[String: Any]]
            let errors = result["errors"] as! [[String: Any]]

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["skyflowID"] as! String, "SID")
            XCTAssertEqual(records[0]["tableName"] as! String, "table")
            XCTAssertNil(records[0]["tokens"])
            XCTAssertTrue(errors.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGetCollectResponseWithTokens() {
        let response = ["records": [["skyflowID": "SID", "tableName": "table", "tokens": ["field": "value"]]]] as [String: Any]
        self.collectCallback.options = FlowVaultICOptions()

        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let result = try self.collectCallback.getCollectResponseBody(data: data)
            let records = result["records"] as! [[String: Any]]

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["tableName"] as! String, "table")
            XCTAssertEqual(records[0]["tokens"] as! [String: String], ["field": "value"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGetCollectResponseWithDataAndHashedDataAndHttpCode() {
        let response: [String: Any] = ["records": [[
            "skyflowID": "SID",
            "tableName": "table",
            "httpCode": 200,
            "data": ["field": "value"],
            "hashedData": ["field": "hashed-value"]
        ]]]
        self.collectCallback.options = FlowVaultICOptions()

        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let result = try self.collectCallback.getCollectResponseBody(data: data)
            let records = result["records"] as! [[String: Any]]

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["httpCode"] as? Int, 200)
            XCTAssertEqual(records[0]["data"] as! [String: String], ["field": "value"])
            XCTAssertEqual(records[0]["hashedData"] as! [String: String], ["field": "hashed-value"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponse() {
        let response = ["records": [["skyflowID": "SID", "tableName": "table"]]]

        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

            let processedData = try self.collectCallback.processResponse(data: data, response: response, error: nil)
            let records = processedData["records"] as! [[String: Any]]
            XCTAssertEqual(records[0]["skyflowID"] as! String, "SID")
            XCTAssertEqual(records[0]["tableName"] as! String, "table")

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponseError() {
        let response = ["records": [["skyflowID": "SID", "tableName": "table"]]]

        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

            let processedData = try self.collectCallback.processResponse(data: data, response: response, error: NSError(domain: "", code: 400, userInfo: nil))
            as! [String: [String: String]]
        } catch {
        }
    }

    func testProcessResponseFailure() {
        let response = ["error": ["message": "Internal Server Error"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: ["x-request-id": "RID"])

//            XCTFail("Not throwing on Api Error")
            do {
                var res = try self.collectCallback.processResponse(data: data, response: response, error: nil)
                let message = (res["error"] as! [String: Any])["message"] as! String
                XCTAssertEqual(message, "Internal Server Error - request-id: RID")
            } catch {
                XCTFail("sHOULD Not throwing on Api Error")
            }
        } catch {
            XCTAssertEqual(error.localizedDescription, "Internal Server Error - request-id: RID")
        }
    }

    func testCollectInvalidBearerToken() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let client = Client(Configuration(vaultID: "id", vaultURL: "https://www.skyflow.com", tokenProvider: DemoTokenProvider()))
        let container = client.container(type: ContainerType.COLLECT)
        let input = CollectElementInput(table: "table", column: "column", type: .EXPIRATION_YEAR)
        let element = container?.create(input: input)

        UIWindow().addSubview(element!)

        container?.collect(callback: callback)

        wait(for: [expectation], timeout: 20.0)
        XCTAssertTrue(callback.receivedResponse.contains("Token generated from 'getBearerToken' callback function is invalid"))
    }
    func testGetDeviceDetails() {
        let device = UIDevice()
        let deviceInfo = FetchMetrices().getMetrices()
        XCTAssertEqual(UIDevice.current.name, deviceInfo["sdk_client_device_model"] as! String)
        XCTAssertEqual("skyflow-iOS@" + SDK_VERSION, deviceInfo["sdk_name_version"] as! String);
        XCTAssertEqual(device.systemName + "@" + device.systemVersion, deviceInfo["sdk_client_os_details"] as! String)
    }
    func testDeviceDetails() {

        let deviceDetails = FetchMetrices().getDeviceDetails()

         XCTAssertNotNil(deviceDetails["device"])
         XCTAssertNotNil(deviceDetails["os_details"])
         XCTAssertNotNil(deviceDetails["sdk_name_version"])

         if let device = deviceDetails["device"] as? String {
             XCTAssertFalse(device.isEmpty)
         } else {
             XCTAssertTrue(deviceDetails["device"] as! String == "")
         }

         if let osDetails = deviceDetails["os_details"] as? String {
             XCTAssertFalse(osDetails.isEmpty)
         } else {
             XCTAssertTrue(deviceDetails["os_details"] as! String == "")
         }

         if let sdkNameVersion = deviceDetails["sdk_name_version"] as? String {
             XCTAssertFalse(sdkNameVersion.isEmpty)
         } else {
             XCTAssertTrue(deviceDetails["sdk_name_version"] as! String == "")
         }
     }

    func testOnlyInsertSuccess() {
        let expectation = XCTestExpectation(description: "Only insert records should succeed")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecord: [String: Any] = [
            "table": "table",
            "fields": ["field": "value"]
        ]

        let collectCallback = FlowVaultCollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": [insertRecord]],
            options: FlowVaultICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        // Simulate a successful insert response
        let insertResponseDict: [String: Any] = ["records": [["skyflowID": "SID", "tableName": "table", "tokens": ["field": "value"]]]]

        let insertResponseData = try! JSONSerialization.data(withJSONObject: insertResponseDict, options: .fragmentsAllowed)
        let insertUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/v2/records/insert")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        do {
            let processedInsert = try collectCallback.processResponse(data: insertResponseData, response: insertUrlResponse, error: nil)
            let insertRecords = processedInsert["records"] as! [[String: Any]]
            let errors = processedInsert["errors"] as! [[String: Any]]

            XCTAssertEqual(insertRecords.count, 1)
            XCTAssertEqual(insertRecords[0]["skyflowID"] as? String, "SID")
            let tokens = insertRecords[0]["tokens"] as? [String: String]
            XCTAssertEqual(tokens?["field"], "value")
            XCTAssertTrue(errors.isEmpty)
        } catch {
            XCTFail("Insert scenario failed: \(error)")
        }
    }

    func testInsertPartialFailure() {
        let expectation = XCTestExpectation(description: "Partial insert failure should populate errors array")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecords: [[String: Any]] = [
            ["table": "table", "fields": ["field": "value"]],
            ["table": "table", "fields": ["field": "value2"]]
        ]

        let collectCallback = FlowVaultCollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": insertRecords],
            options: FlowVaultICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        let responseDict: [String: Any] = ["records": [
            ["skyflowID": "SID", "tableName": "table", "tokens": ["field": "value"]],
            ["tableName": "table", "error": "insert failed", "httpCode": 400]
        ]]
        let responseData = try! JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.org/v2/records/insert")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        do {
            let processed = try collectCallback.processResponse(data: responseData, response: urlResponse, error: nil)
            let records = processed["records"] as! [[String: Any]]
            let errors = processed["errors"] as! [[String: Any]]

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(errors.count, 1)
            XCTAssertEqual(errors[0]["error"] as? String, "insert failed")
            XCTAssertEqual(errors[0]["httpCode"] as? Int, 400)
        } catch {
            XCTFail("Partial insert failure scenario failed: \(error)")
        }
    }

    func testInsertFullFailureWithNon2xxOuterStatus() {
        let expectation = XCTestExpectation(description: "Full batch failure with 400 outer status should still parse per-record errors")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecords: [[String: Any]] = [
            ["table": "table", "fields": ["field": "value"]],
            ["table": "table", "fields": ["field": "value2"]]
        ]

        let collectCallback = FlowVaultCollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": insertRecords],
            options: FlowVaultICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        let responseDict: [String: Any] = ["records": [
            ["skyflowID": NSNull(), "tokens": NSNull(), "data": NSNull(), "hashedData": NSNull(),
             "error": "Invalid request. Table name table not present for record. Specify a valid table name.",
             "httpCode": 400, "tableName": ""],
            ["skyflowID": NSNull(), "tokens": NSNull(), "data": NSNull(), "hashedData": NSNull(),
             "error": "Invalid request. Table name table not present for record. Specify a valid table name.",
             "httpCode": 400, "tableName": ""]
        ]]
        let responseData = try! JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.org/v2/records/insert")!, statusCode: 400, httpVersion: "1.1", headerFields: nil)

        do {
            let processed = try collectCallback.processResponse(data: responseData, response: urlResponse, error: nil)
            XCTAssertNil(processed["error"], "Should not collapse into a generic top-level error when the body has a records array")
            let records = processed["records"] as! [[String: Any]]
            let errors = processed["errors"] as! [[String: Any]]

            XCTAssertTrue(records.isEmpty)
            XCTAssertEqual(errors.count, 2)
            XCTAssertEqual(errors[0]["error"] as? String, "Invalid request. Table name table not present for record. Specify a valid table name.")
            XCTAssertEqual(errors[0]["httpCode"] as? Int, 400)
        } catch {
            XCTFail("Full failure scenario should not throw: \(error)")
        }
    }

    func testInsertPartialFailureWith207OuterStatus() {
        let expectation = XCTestExpectation(description: "Partial failure with 207 outer status should parse per-record errors")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecords: [[String: Any]] = [
            ["table": "table2", "fields": ["address": "dedede", "gender": "sagar"]],
            ["table": "table", "fields": ["field": "value"]]
        ]

        let collectCallback = FlowVaultCollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": insertRecords],
            options: FlowVaultICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        let responseDict: [String: Any] = ["records": [
            ["skyflowID": "b187b5b6-28b4-4881-93fa-4ef10e30b20e", "tokens": ["address": [["token": "dedwim", "tokenGroupName": "deterministic_string"]]],
             "data": ["address": "dedede", "gender": "sagar"], "hashedData": [:], "error": NSNull(), "httpCode": 200, "tableName": "table2"],
            ["skyflowID": NSNull(), "tokens": NSNull(), "data": NSNull(), "hashedData": NSNull(),
             "error": "Invalid request. Table name table not present for record. Specify a valid table name.",
             "httpCode": 400, "tableName": ""]
        ]]
        let responseData = try! JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.org/v2/records/insert")!, statusCode: 207, httpVersion: "1.1", headerFields: nil)

        do {
            let processed = try collectCallback.processResponse(data: responseData, response: urlResponse, error: nil)
            let records = processed["records"] as! [[String: Any]]
            let errors = processed["errors"] as! [[String: Any]]

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["skyflowID"] as? String, "b187b5b6-28b4-4881-93fa-4ef10e30b20e")
            XCTAssertEqual(errors.count, 1)
            XCTAssertEqual(errors[0]["httpCode"] as? Int, 400)
        } catch {
            XCTFail("Partial (207) scenario should not throw: \(error)")
        }
    }

    func testUpdateSuccessResponseLiteral() {
        let json = """
        {
            "records": [
                {
                    "skyflowID": "f30c8ccf-7e86-46b4-be74-0b2db44e4b87",
                    "tokens": {
                        "email": [{"token": "a@ehmw.aqk", "tokenGroupName": "nondeterministic_string"}],
                        "name": [{"token": "sagwm", "tokenGroupName": "deterministic_string"}],
                        "passport": [{"token": "21284054160", "tokenGroupName": "deterministic_string"}]
                    },
                    "data": {"email": "b@demo.com", "name": "sagar", "passport": "21212121212"},
                    "hashedData": {},
                    "error": null,
                    "httpCode": 200,
                    "tableName": "table1"
                }
            ]
        }
        """
        let responseData = json.data(using: .utf8)!
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.org/v2/records/update")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        self.collectCallback.options = FlowVaultICOptions(tokens: true)

        do {
            let processed = try self.collectCallback.processResponse(data: responseData, response: urlResponse, error: nil)
            let records = processed["records"] as! [[String: Any]]
            let errors = processed["errors"] as! [[String: Any]]

            XCTAssertTrue(errors.isEmpty)
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["skyflowID"] as? String, "f30c8ccf-7e86-46b4-be74-0b2db44e4b87")
            let data = records[0]["data"] as! [String: Any]
            XCTAssertEqual(data["name"] as? String, "sagar")
            let tokens = records[0]["tokens"] as! [String: Any]
            let nameTokens = tokens["name"] as! [[String: Any]]
            XCTAssertEqual(nameTokens[0]["token"] as? String, "sagwm")
        } catch {
            XCTFail("Update success response should not throw: \(error)")
        }
    }

    func testUpdateFullFailureResponseLiteral() {
        let json = """
        {
            "records": [
                {
                    "skyflowID": null, "tokens": null, "data": null, "hashedData": null,
                    "error": "Invalid request. Table name table not present for record. Specify a valid table name.",
                    "httpCode": 400, "tableName": ""
                },
                {
                    "skyflowID": null, "tokens": null, "data": null, "hashedData": null,
                    "error": "Invalid request. Table name table not present for record. Specify a valid table name.",
                    "httpCode": 400, "tableName": ""
                }
            ]
        }
        """
        let responseData = json.data(using: .utf8)!
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.org/v2/records/update")!, statusCode: 400, httpVersion: "1.1", headerFields: nil)

        do {
            let processed = try self.collectCallback.processResponse(data: responseData, response: urlResponse, error: nil)
            XCTAssertNil(processed["error"], "Should not collapse into a generic top-level error when the body has a records array")
            let records = processed["records"] as! [[String: Any]]
            let errors = processed["errors"] as! [[String: Any]]

            XCTAssertTrue(records.isEmpty)
            XCTAssertEqual(errors.count, 2)
            XCTAssertEqual(errors[0]["error"] as? String, "Invalid request. Table name table not present for record. Specify a valid table name.")
        } catch {
            XCTFail("Update full failure response should not throw: \(error)")
        }
    }

    func testUpdatePartialFailureResponseLiteral() {
        let json = """
        {
            "records": [
                {
                    "skyflowID": "b187b5b6-28b4-4881-93fa-4ef10e30b20e",
                    "tokens": {
                        "address": [{"token": "dedwim", "tokenGroupName": "deterministic_string"}],
                        "gender": [{"token": "sagwm", "tokenGroupName": "deterministic_string"}]
                    },
                    "data": {"address": "dedede", "gender": "sagar"},
                    "hashedData": {},
                    "error": null,
                    "httpCode": 200,
                    "tableName": "table2"
                },
                {
                    "skyflowID": null, "tokens": null, "data": null, "hashedData": null,
                    "error": "Invalid request. Table name table not present for record. Specify a valid table name.",
                    "httpCode": 400, "tableName": ""
                }
            ]
        }
        """
        let responseData = json.data(using: .utf8)!
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.org/v2/records/update")!, statusCode: 207, httpVersion: "1.1", headerFields: nil)
        self.collectCallback.options = FlowVaultICOptions(tokens: true)

        do {
            let processed = try self.collectCallback.processResponse(data: responseData, response: urlResponse, error: nil)
            let records = processed["records"] as! [[String: Any]]
            let errors = processed["errors"] as! [[String: Any]]

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["skyflowID"] as? String, "b187b5b6-28b4-4881-93fa-4ef10e30b20e")
            XCTAssertEqual(errors.count, 1)
            XCTAssertEqual(errors[0]["httpCode"] as? Int, 400)
        } catch {
            XCTFail("Update partial response should not throw: \(error)")
        }
    }
}
