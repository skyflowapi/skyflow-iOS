/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow


final class skyflow_iOS_collectUtilTests: XCTestCase {
    var collectCallback: CollectAPICallback! = nil
    var defaultRecord: [String: Any] = ["records": [["table": "table", "fields": ["field": "value"]]]]
    
    override func setUp() {
        self.collectCallback = CollectAPICallback(callback: DemoAPICallback(expectation: XCTestExpectation()),
                                                  apiClient: APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider()),
                                                  records: defaultRecord,
                                                  options: ICOptions(tokens: false, additionalFields: nil),
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
        
        let result = callback.data["errors"] as! [[String: Any]]
        let errorObject = result[0]["error"] as! [String: Any]
        let msg = errorObject["message"] as! String
        XCTAssert(msg.contains("unsupported URL"))
    }
    
    func testGetRequestSession() {
        let url = URL(string: "https://example.org")!
        do {
            let (request, session) = try self.collectCallback.getRequestSession(url: url)
            
            XCTAssertEqual(request.allHTTPHeaderFields!["Authorization"], "Bearer ") // From DemoTokenProvider()
            let body = try JSONSerialization.jsonObject(with: request.httpBody!, options: .allowFragments) as! [String: Any]
            let records = body["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["fields"] as! [String: String], ["field": "value"])
            XCTAssertEqual(records[0]["method"] as! String, "POST")
            XCTAssertEqual(records[0]["tableName"] as! String, "table")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testGetCollectResponse() {
        let response = ["responses": [["records": [["skyflow_id": "SID"]]]]]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let result = try self.collectCallback.getCollectResponseBody(data: data)
            
            XCTAssertEqual(result as! [String: [[String: String]]], ["records": [
                [
                    "table": "table",
                    "skyflow_id": "SID"
                ]
            ]])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testGetCollectResponseWithTokens() {
        let response = ["responses": [["records": [["skyflow_id": "SID"]]], ["fields": ["field": "value"]]]]
        self.collectCallback.options = ICOptions()
        
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let result = try self.collectCallback.getCollectResponseBody(data: data)
            let records = result["records"] as! [[String: Any]]
            
            let expected = ["records": [["table": "table", "fields": ["field": "value", "skyflow_id": "SID"]]]]
            
            XCTAssertEqual(records.count, expected["records"]!.count)
            XCTAssertEqual(records[0]["table"] as! String, expected["records"]![0]["table"] as! String)
            XCTAssertEqual(records[0]["fields"] as! [String: String], expected["records"]![0]["fields"] as! [String: String])
            
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProcessResponse() {
        let response = ["responses": [["records": [["skyflow_id": "SID"]]], ["fields": ["field": "value"]]]]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            
            let processedData = try self.collectCallback.processResponse(data: data, response: response, error: nil) as! [String: [[String: String]]]
            XCTAssertEqual(processedData, ["records": [["skyflow_id": "SID", "table": "table"]]])
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProcessResponseError() {
        let response = ["responses": [["records": [["skyflow_id": "SID"]]], ["fields": ["field": "value"]]]]
        
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
     func testUpdateNewFlow() {
        let expectation = XCTestExpectation(description: "Update new flow should succeed and merge response")
        let callback = DemoAPICallback(expectation: expectation)
        let updateRecord: [String: Any] = [
            "table": "table",
            "skyflowID": "id1",
            "fields": ["field": "newValue"]
        ]
        let collectCallback = CollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["update": ["id1": updateRecord]],
            options: ICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )
        // Simulate a successful update response
        let responseDict: [String: Any] = [
            "skyflow_id": "id1",
            "tokens": ["field": "newValue"]
        ]
        let responseData = try! JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.org/table/id1")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        do {
            let processed = try collectCallback.processUpdateResponse(data: responseData, response: urlResponse, error: nil, table: "table")
            let records = processed["records"] as! [[String: Any]]
            print("records after processing update response", records)
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["table"] as? String, "table")
            let fields = records[0]["fields"] as? [String: String]
            XCTAssertEqual((fields?["skyflow_id"] ?? "") as String, "id1")
            XCTAssertEqual(fields?["field"] as? String, "newValue")
        } catch {
            XCTFail("Update flow failed: \(error)")
        }
    }
    func testPartialInsertAndUpdateScenario() {
        let expectation = XCTestExpectation(description: "Partial insert and update scenario should succeed")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecord: [String: Any] = [
            "table": "table",
            "fields": ["field": "value"]
        ]

        let updateRecord: [String: Any] = [
            "table": "table",
            "skyflowID": "id1",
            "fields": ["field": "newValue"]
        ]

        let collectCallback = CollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": [insertRecord], "update": ["id1": updateRecord]],
            options: ICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        // Simulate a successful insert response
        let insertResponseDict = ["responses": [["records": [["skyflow_id": "SID"]]], ["fields": ["field": "value"]]]]
        let insertResponseData = try! JSONSerialization.data(withJSONObject: insertResponseDict, options: .fragmentsAllowed)
        let insertUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/vault")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        // Simulate a successful update response
        let updateResponseDict: [String: Any] = [
            "skyflow_id": "id1",
            "tokens": ["field": "newValue"]
        ]
        let updateResponseData = try! JSONSerialization.data(withJSONObject: updateResponseDict, options: .fragmentsAllowed)
        let updateUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/table/id1")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        do {
            let processedInsert = try collectCallback.processResponse(data: insertResponseData, response: insertUrlResponse, error: nil)
            let processedUpdate = try collectCallback.processUpdateResponse(data: updateResponseData, response: updateUrlResponse, error: nil, table: "table")

            let insertRecords = processedInsert["records"] as! [[String: Any]]
            let updateRecords = processedUpdate["records"] as! [[String: Any]]

            XCTAssertEqual(insertRecords.count, 1)
            let ifields = insertRecords[0]["fields"] as? [String: String]
            XCTAssertEqual(ifields?["skyflow_id"] as? String, "SID")

            XCTAssertEqual(updateRecords.count, 1)
            XCTAssertEqual(updateRecords[0]["table"] as? String, "table")
            let fields = updateRecords[0]["fields"] as? [String: String]
            XCTAssertEqual(fields?["skyflow_id"], "id1")
            XCTAssertEqual(fields?["field"], "newValue")
        } catch {
            XCTFail("Partial insert and update scenario failed: \(error)")
        }
    }
    func testOnlyInsertSuccess() {
        let expectation = XCTestExpectation(description: "Only insert records should succeed")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecord: [String: Any] = [
            "table": "table",
            "fields": ["field": "value"]
        ]

        let collectCallback = CollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": [insertRecord]],
            options: ICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        // Simulate a successful insert response
        let insertResponseDict = ["responses": [["records": [["skyflow_id": "SID"]]], ["fields": ["field": "value"]]]]

        let insertResponseData = try! JSONSerialization.data(withJSONObject: insertResponseDict, options: .fragmentsAllowed)
        let insertUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/vault")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        do {
            let processedInsert = try collectCallback.processResponse(data: insertResponseData, response: insertUrlResponse, error: nil)
            let insertRecords = processedInsert["records"] as! [[String: Any]]

            XCTAssertEqual(insertRecords.count, 1)
            let fields = insertRecords[0]["fields"] as? [String: String]
            XCTAssertEqual(fields?["skyflow_id"] as? String, "SID")
        } catch {
            XCTFail("Insert scenario failed: \(error)")
        }
    }

    func testOnlyUpdateSuccess() {
        let expectation = XCTestExpectation(description: "Only update records should succeed")
        let callback = DemoAPICallback(expectation: expectation)

        let updateRecord: [String: Any] = [
            "table": "table",
            "skyflowID": "id1",
            "fields": ["field": "newValue"]
        ]

        let collectCallback = CollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["update": ["id1": updateRecord]],
            options: ICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        // Simulate a successful update response
        let updateResponseDict: [String: Any] = [
            "skyflow_id": "id1",
            "tokens": ["field": "newValue"]
        ]
        let updateResponseData = try! JSONSerialization.data(withJSONObject: updateResponseDict, options: .fragmentsAllowed)
        let updateUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/table/id1")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        do {
            let processedUpdate = try collectCallback.processUpdateResponse(data: updateResponseData, response: updateUrlResponse, error: nil, table: "table")
            let updateRecords = processedUpdate["records"] as! [[String: Any]]

            XCTAssertEqual(updateRecords.count, 1)
            XCTAssertEqual(updateRecords[0]["table"] as? String, "table")
            let fields = updateRecords[0]["fields"] as? [String: String]
            XCTAssertEqual(fields?["skyflow_id"], "id1")
            XCTAssertEqual(fields?["field"], "newValue")
        } catch {
            XCTFail("Update scenario failed: \(error)")
        }
    }

    func testInsertAndUpdateSuccess() {
        let expectation = XCTestExpectation(description: "Insert and update records should succeed")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecord: [String: Any] = [
            "table": "table",
            "fields": ["field": "value"]
        ]

        let updateRecord: [String: Any] = [
            "table": "table",
            "skyflowID": "id1",
            "fields": ["field": "newValue"]
        ]

        let collectCallback = CollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": [insertRecord], "update": ["id1": updateRecord]],
            options: ICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        // Simulate a successful insert response
//        let insertResponseDict: [String: Any] = [
//            "records": [["skyflow_id": "inserted_id"]]
//        ]
        let insertResponseDict = ["responses": [["records": [["skyflow_id": "inserted_id"]]], ["fields": ["field": "value"]]]]

        let insertResponseData = try! JSONSerialization.data(withJSONObject: insertResponseDict, options: .fragmentsAllowed)
        let insertUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/vault")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        // Simulate a successful update response
        let updateResponseDict: [String: Any] = [
            "skyflow_id": "id1",
            "tokens": ["field": "newValue"]
        ]
        let updateResponseData = try! JSONSerialization.data(withJSONObject: updateResponseDict, options: .fragmentsAllowed)
        let updateUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/table/id1")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        do {
            let processedInsert = try collectCallback.processResponse(data: insertResponseData, response: insertUrlResponse, error: nil)
            let processedUpdate = try collectCallback.processUpdateResponse(data: updateResponseData, response: updateUrlResponse, error: nil, table: "table")

            let insertRecords = processedInsert["records"] as! [[String: Any]]
            let updateRecords = processedUpdate["records"] as! [[String: Any]]

            XCTAssertEqual(insertRecords.count, 1)
            var ifields = insertRecords[0]["fields"] as? [String: String]
            XCTAssertEqual(ifields?["skyflow_id"] as? String, "inserted_id")

            XCTAssertEqual(updateRecords.count, 1)
            XCTAssertEqual(updateRecords[0]["table"] as? String, "table")
            let fields = updateRecords[0]["fields"] as? [String: String]
            XCTAssertEqual(fields?["skyflow_id"], "id1")
            XCTAssertEqual(fields?["field"], "newValue")
        } catch {
            XCTFail("Insert and update scenario failed: \(error)")
        }
    }

    func testInsertSuccessAndUpdateFailure() {
        let expectation = XCTestExpectation(description: "Insert success and update failure")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecord: [String: Any] = [
            "table": "table",
            "fields": ["field": "value"]
        ]

        let updateRecord: [String: Any] = [
            "table": "table",
            "skyflowID": "id1",
            "fields": ["field": "newValue"]
        ]

        let collectCallback = CollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": [insertRecord], "update": ["id1": updateRecord]],
            options: ICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        // Simulate a successful insert response
        let insertResponseDict = ["responses": [["records": [["skyflow_id": "inserted_id"]]], ["fields": ["field": "value"]]]]
        let insertResponseData = try! JSONSerialization.data(withJSONObject: insertResponseDict, options: .fragmentsAllowed)
        let insertUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/vault")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        // Simulate a failed update response
        let updateError = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Update failed"])

        do {
            let processedInsert = try collectCallback.processResponse(data: insertResponseData, response: insertUrlResponse, error: nil)
            let insertRecords = processedInsert["records"] as! [[String: Any]]

            XCTAssertEqual(insertRecords.count, 1)
            var fields = insertRecords[0]["fields"] as? [String: Any]
            XCTAssertEqual(fields?["skyflow_id"] as? String, "inserted_id")

            let insertResponse = try collectCallback.processUpdateResponse(data: nil, response: nil, error: updateError, table: "table") as! [String: [String: String]]
            XCTAssertEqual(insertResponse, ["error": ["message": "Update failed"]])
        } catch {
            XCTFail("Insert success and update failure scenario failed: \(error)")
        }
    }

    func testInsertFailureAndUpdateSuccess() {
        let expectation = XCTestExpectation(description: "Insert failure and update success")
        let callback = DemoAPICallback(expectation: expectation)

        let insertRecord: [String: Any] = [
            "table": "table",
            "fields": ["field": "value"]
        ]

        let updateRecord: [String: Any] = [
            "table": "table",
            "skyflowID": "id1",
            "fields": ["field": "newValue"]
        ]

        let collectCallback = CollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": [insertRecord], "update": ["id1": updateRecord]],
            options: ICOptions(tokens: true, additionalFields: nil),
            contextOptions: ContextOptions()
        )

        // Simulate a failed insert response
        let insertErrorResponseDict: [String: Any] = [
            "error": ["message": "Insert failed"]
        ]
        let insertErrorResponseData = try! JSONSerialization.data(withJSONObject: insertErrorResponseDict, options: .fragmentsAllowed)
        let insertErrorUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/vault")!, statusCode: 400, httpVersion: "1.1", headerFields: nil)

        // Simulate a successful update response
        let updateResponseDict: [String: Any] = [
            "skyflow_id": "id1",
            "tokens": ["field": "newValue"]
        ]
        let updateResponseData = try! JSONSerialization.data(withJSONObject: updateResponseDict, options: .fragmentsAllowed)
        let updateUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/table/id1")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        do {
            let insertProccessed = try collectCallback.processResponse(data: insertErrorResponseData, response: insertErrorUrlResponse, error: nil)  as! [String: [String: Any]]
            XCTAssertEqual(insertProccessed["error"]?["message"] as? String, "Insert failed")
            XCTAssertEqual(insertProccessed["error"]?["code"] as? Int, 400)

            let processedUpdate = try collectCallback.processUpdateResponse(data: updateResponseData, response: updateUrlResponse, error: nil, table: "table")
            let updateRecords = processedUpdate["records"] as! [[String: Any]]

            XCTAssertEqual(updateRecords.count, 1)
            XCTAssertEqual(updateRecords[0]["table"] as? String, "table")
            let fields = updateRecords[0]["fields"] as? [String: String]
            XCTAssertEqual(fields?["skyflow_id"], "id1")
            XCTAssertEqual(fields?["field"], "newValue")
        } catch {
            XCTFail("Insert failure and update success scenario failed: \(error)")
        }
    }
//    func testInsertResponseStructure() {
//        let expectation = XCTestExpectation(description: "Insert response structure test")
//        let callback = DemoAPICallback(expectation: expectation)
//
//        let insertRecord: [String: Any] = [
//            "table": "table",
//            "fields": ["drivers_license_number": "REDACTED", "ssn": "XXX-XX-7645"]
//        ]
//
//        let collectCallback = CollectAPICallback(
//            callback: callback,
//            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
//            records: ["records": [insertRecord]],
//            options: ICOptions(tokens: true, additionalFields: nil),
//            contextOptions: ContextOptions()
//        )
//
//        // Simulate a successful insert response
//        let insertResponseDict: [String: Any] = [
//            "vaultID": "cd1d815aa09b4cbfbb803bd20349f202",
//            "responses": [
//                [
//                    "records": [
//                        [
//                            "fields": [
//                                "drivers_license_number": "REDACTED",
//                                "ssn": "XXX-XX-7645"
//                            ],
//                            "skyflow_id": "4bc4a3a6-dfba-4314-809d-5ca63d43c732"
//                        ]
//                    ]
//                ]
//            ]
//        ]
//        let insertResponseData = try! JSONSerialization.data(withJSONObject: insertResponseDict, options: .fragmentsAllowed)
//        let insertUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/vault")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
//
//        do {
//            let processedInsert = try collectCallback.processResponse(data: insertResponseData, response: insertUrlResponse, error: nil)
//            let insertRecords = processedInsert["records"] as! [[String: Any]]
//
//            XCTAssertEqual(insertRecords.count, 1)
//            XCTAssertEqual(insertRecords[0]["skyflow_id"] as? String, "4bc4a3a6-dfba-4314-809d-5ca63d43c732")
//            let fields = insertRecords[0]["fields"] as! [String: String]
//            XCTAssertEqual(fields["drivers_license_number"], "REDACTED")
//            XCTAssertEqual(fields["ssn"], "XXX-XX-7645")
//        } catch {
//            XCTFail("Insert response structure test failed: \(error)")
//        }
//    }
//
//    func testInsertErrorStructure() {
//        let expectation = XCTestExpectation(description: "Insert error structure test")
//        let callback = DemoAPICallback(expectation: expectation)
//
//        let insertRecord: [String: Any] = [
//            "table": "table",
//            "fields": ["drivers_license_number": "REDACTED", "ssn": "XXX-XX-7645"]
//        ]
//
//        let collectCallback = CollectAPICallback(
//            callback: callback,
//            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
//            records: ["records": [insertRecord]],
//            options: ICOptions(tokens: true, additionalFields: nil),
//            contextOptions: ContextOptions()
//        )
//
//        // Simulate a failed insert response
//        let insertErrorResponseDict: [String: Any] = [
//            "error": [
//                "grpc_code": 3,
//                "http_code": 400,
//                "http_status": "Bad Request",
//                "message": "The request was invalid or cannot be served. Check the request parameters and try again.",
//                "details": []
//            ]
//        ]
//        let insertErrorResponseData = try! JSONSerialization.data(withJSONObject: insertErrorResponseDict, options: .fragmentsAllowed)
//        let insertErrorUrlResponse = HTTPURLResponse(url: URL(string: "https://example.org/vault")!, statusCode: 400, httpVersion: "1.1", headerFields: nil)
//
//        do {
//            XCTAssertThrowsError(try collectCallback.processResponse(data: insertErrorResponseData, response: insertErrorUrlResponse, error: nil)) { error in
//                let errorDict = error as! [String: Any]
//                let errorMessage = (errorDict["error"] as! [String: Any])["message"] as! String
//                XCTAssertEqual(errorMessage, "The request was invalid or cannot be served. Check the request parameters and try again.")
//            }
//        } catch {
//            XCTFail("Insert error structure test failed: \(error)")
//        }
//    }
}
