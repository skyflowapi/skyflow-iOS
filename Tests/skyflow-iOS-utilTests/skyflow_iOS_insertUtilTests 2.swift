/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import SkyflowFlowVaultIOS
@testable import SkyflowCore


final class skyflow_iOS_insertUtilTests: XCTestCase {
    var collectCallback: FlowVaultInsertAPICallback! = nil
    var defaultRecord: [String: Any] = ["records": [["table": "table", "fields": ["field": "value"]]]]

    override func setUp() {
        self.collectCallback = FlowVaultInsertAPICallback(callback: DemoAPICallback(expectation: XCTestExpectation()),
                                                  apiClient: APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider()),
                                                  records: defaultRecord,
                                                  options: FlowVaultICOptions(additionalFields: nil),
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

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["tableName"] as! String, "table")
            XCTAssertEqual(records[0]["skyflowID"] as! String, "SID")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGetCollectResponseWithTokens() {
        let response = ["records": [["skyflowID": "SID", "tableName": "table", "tokens": ["field": [["token": "tok", "tokenGroupName": "group"]]]]]] as [String: Any]
        self.collectCallback.options = FlowVaultICOptions()

        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let result = try self.collectCallback.getCollectResponseBody(data: data)
            let records = result["records"] as! [[String: Any]]

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["tableName"] as! String, "table")
            XCTAssertEqual(records[0]["skyflowID"] as! String, "SID")
            let fields = records[0]["fields"] as! [String: Any]
            let fieldTokens = fields["field"] as! [[String: Any]]
            XCTAssertEqual(fieldTokens[0]["token"] as? String, "tok")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGetCollectResponseWithHashedData() {
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
            let fields = records[0]["fields"] as! [String: Any]
            XCTAssertNil(fields["data"])
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
            XCTAssertEqual(records[0]["tableName"] as! String, "table")
            XCTAssertEqual(records[0]["skyflowID"] as! String, "SID")

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponseError() {
        // A genuine connection/network-level error (URLSession error, no HTTP response reached)
        // should not throw - it returns a top-level {"error": {...}} dict directly.
        let networkError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])

        do {
            let processedData = try self.collectCallback.processResponse(data: nil, response: nil, error: networkError)
            let errorDict = processedData["error"] as! [String: Any]
            XCTAssertEqual(errorDict["message"] as? String, "The Internet connection appears to be offline.")
        } catch {
            XCTFail("Should not throw for a connection-level error: \(error)")
        }
    }

    func testGetCollectResponseBodyWithMalformedTopLevelJSON() {
        // A response body that parses as valid JSON but isn't a top-level object (e.g. a bare
        // array or scalar) must not crash - it should fall back to an empty result.
        do {
            let arrayData = try JSONSerialization.data(withJSONObject: ["not", "an", "object"], options: .fragmentsAllowed)
            let result = try self.collectCallback.getCollectResponseBody(data: arrayData)
            XCTAssertEqual((result["records"] as? [[String: Any]])?.count, 0)
        } catch {
            XCTFail("Malformed top-level JSON should not throw or crash: \(error)")
        }
    }

    func testProcessResponseFailure() {
        let response = ["error": ["message": "Internal Server Error"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: ["x-request-id": "RID"])

            let res = try self.collectCallback.processResponse(data: data, response: response, error: nil)
            let message = (res["error"] as! [String: Any])["message"] as! String
            XCTAssertEqual(message, "Internal Server Error - request-id: RID")
        } catch {
            XCTFail("Should not throw on Api Error: \(error)")
        }
    }

    func testCollectInvalidBearerToken() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let client = Client(Configuration(vaultID: "id", vaultURL: "https://www.skyflow.com", tokenProvider: DemoTokenProvider()))
        let container = client.container(type: ContainerType.COLLECT)
        let input = CollectElementInput(tableName: "table", column: "column", type: .EXPIRATION_YEAR)
        let element = container?.create(input: input)

        UIWindow().addSubview(element!)

        container?.collect(callback: callback.asCollectCallback)

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

        let collectCallback = FlowVaultInsertAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": [insertRecord]],
            options: FlowVaultICOptions(additionalFields: nil),
            contextOptions: ContextOptions()
        )

        // Simulate a successful insert response
        let insertResponseDict: [String: Any] = ["records": [["skyflowID": "SID", "tableName": "table", "tokens": ["field": "value"]]]]

        let insertResponseData = try! JSONSerialization.data(withJSONObject: insertResponseDict, options: .fragmentsAllowed)
        let insertUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/v2/records/insert")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        do {
            let processedInsert = try collectCallback.processResponse(data: insertResponseData, response: insertUrlResponse, error: nil)
            let insertRecords = processedInsert["records"] as! [[String: Any]]

            XCTAssertEqual(insertRecords.count, 1)
            XCTAssertEqual(insertRecords[0]["tableName"] as? String, "table")
            XCTAssertEqual(insertRecords[0]["skyflowID"] as? String, "SID")
            let fields = insertRecords[0]["fields"] as! [String: Any]
            XCTAssertEqual(fields["field"] as? String, "value")
        } catch {
            XCTFail("Insert scenario failed: \(error)")
        }
    }

    func testInsertFullFailureWithNon2xxOuterStatus() {
        let expectation = XCTestExpectation(description: "Full batch failure with 400 outer status should still parse per-record errors")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecord: [String: Any] = [
            "table": "table",
            "fields": ["field": "value"]
        ]

        let collectCallback = FlowVaultInsertAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": [insertRecord]],
            options: FlowVaultICOptions(additionalFields: nil),
            contextOptions: ContextOptions()
        )

        let responseDict: [String: Any] = ["records": [
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

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["error"] as? String, "Invalid request. Table name table not present for record. Specify a valid table name.")
            XCTAssertEqual(records[0]["httpCode"] as? Int, 400)
        } catch {
            XCTFail("Full failure scenario should not throw: \(error)")
        }
    }

}
