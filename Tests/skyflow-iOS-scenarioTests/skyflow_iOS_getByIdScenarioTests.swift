// swiftlint:disable file_length
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_getByIdScenarioTests: XCTestCase {
    var skyflow: Client!
    var tokenProvider: TokenProvider!
    
    let testData = try! JSONDecoder().decode(TestData.self, from: Data(ProcessInfo.processInfo.environment["TEST_DATA"]!.utf8))
    
    override func setUp() {
        self.skyflow = Client(Configuration(tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
        self.tokenProvider = DemoTokenProvider()
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    
    // FIX - invalid test
    func testInsertNoVaultID() {
        let errorObj = ErrorCodes.EMPTY_VAULT_ID().errorObject
        let expectation = XCTestExpectation(description: "no records")
        let callback = DemoAPICallback(expectation: expectation)
        
        // Client no records
        let client = ClientScenario(tokenProvider: self.tokenProvider)
            .setVaultID(vaultId: "")
            .setVaultUrl(vaultURL: testData.CLIENT.VAULT_URL)
        GetByIdScenario(client: client, callback: callback)
            .initiatializeRecords()
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        let errors = callback.data["errors"] as! [NSError]
        let error = errors[0]
        XCTAssertEqual(error.code, errorObj.code)
        XCTAssert(error.localizedDescription.contains(errorObj.localizedDescription))
    }
    
    func testInsertNoVaultURL() {
        let errorObj = ErrorCodes.EMPTY_VAULT_URL().errorObject
        let expectation = XCTestExpectation(description: "no records")
        let callback = DemoAPICallback(expectation: expectation)
        
        // Client no records
        let client = ClientScenario(tokenProvider: self.tokenProvider)
            .setVaultID(vaultId: testData.CLIENT.VAULT_ID)
            .setVaultUrl(vaultURL: "")
        GetByIdScenario(client: client, callback: callback)
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        let errors = callback.data["errors"] as! [NSError]
        let error = errors[0]
        XCTAssertEqual(error.code, errorObj.code)
        XCTAssert(error.localizedDescription.contains(errorObj.localizedDescription))
    }
    
//    func testGetByIdInvalidVaultID() {
//        let expectation = XCTestExpectation(description: "invalid vault id")
//        let callback = DemoAPICallback(expectation: expectation)
//        
//        let client = ClientScenario(tokenProvider: self.tokenProvider)
//            .setVaultID(vaultId: testData.CLIENT.INVALID_VAULT_ID)
//            .setVaultUrl(vaultURL: testData.CLIENT.VAULT_URL)
//        GetByIdScenario(client: client, callback: callback)
//            .initiatializeRecords()
//            .addIds(["ids": [testData.VAULT.INVALID_ID], "table": testData.VAULT.TABLE_NAME, "redaction": RedactionType.DEFAULT])
//            .execute()
//        
//        wait(for: [expectation], timeout: 10.0)
//        let errors = callback.data["errors"] as! [[String: Any]]
//        XCTAssertNotNil(errors)
//        XCTAssertNil(callback.error)
//        let error = errors[0]["error"] as! NSError
//        print("===")
//        XCTAssertEqual(error.code, 404)
//        XCTAssert((error.localizedDescription.contains(" not found")))
//    }
    
    func testGetByIdInvalidVaultURL() {
        let expectation = XCTestExpectation(description: "invalid vault url")
        let callback = DemoAPICallback(expectation: expectation)
        
        // Client no records
        let client = ClientScenario(tokenProvider: self.tokenProvider)
            .setVaultID(vaultId: testData.CLIENT.VAULT_ID)
            .setVaultUrl(vaultURL: testData.CLIENT.INVALID_VAULT_URL)
        GetByIdScenario(client: client, callback: callback)
            .initiatializeRecords()
            .addIds(["ids": [testData.VAULT.INVALID_ID], "table": testData.VAULT.TABLE_NAME, "redaction": RedactionType.DEFAULT])
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        let errors = callback.data["errors"] as! [[String: Any]]
        let error = errors[0]["error"] as! NSError
        XCTAssertEqual(error.code, -1002)
        XCTAssert(error.localizedDescription.contains("unsupported URL"))
    }
    

}

