// swiftlint:disable file_length
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_insertScenarioTests: XCTestCase {
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
    
    private func getFieldValues() -> [String: String] {
        var result = [:] as [String: String]
        for field in testData.VAULT.VALID_FIELDS {
            result[field.NAME] = field.VALUE
        }
        
        return result
    }
    
    func testInsertNoVaultID() {
        let error = ErrorCodes.EMPTY_VAULT_ID().errorObject
        let expectation = XCTestExpectation(description: "no records")
        let callback = DemoAPICallback(expectation: expectation)
        
        // Client no records
        let client = ClientScenario(tokenProvider: self.tokenProvider)
            .setVaultID(vaultId: "")
            .setVaultUrl(vaultURL: testData.CLIENT.VAULT_URL)
        InsertScenario(client: client, callback: callback)
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, error.code)
        XCTAssert(callback.error!.localizedDescription.contains(error.localizedDescription))
    }
    
    func testInsertNoVaultURL() {
        let error = ErrorCodes.EMPTY_VAULT_URL().errorObject
        let expectation = XCTestExpectation(description: "no records")
        let callback = DemoAPICallback(expectation: expectation)
        
        // Client no records
        let client = ClientScenario(tokenProvider: self.tokenProvider)
            .setVaultID(vaultId: testData.CLIENT.VAULT_ID)
            .setVaultUrl(vaultURL: "")
        InsertScenario(client: client, callback: callback)
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, error.code)
        XCTAssert(callback.error!.localizedDescription.contains(error.localizedDescription))
    }
    
//    func testInsertInvalidVaultID() {
//        let expectation = XCTestExpectation(description: "invalid vault id")
//        let callback = DemoAPICallback(expectation: expectation)
//
//        // Client no records
//        let client = ClientScenario(tokenProvider: self.tokenProvider)
//            .setVaultID(vaultId: testData.CLIENT.INVALID_VAULT_ID)
//            .setVaultUrl(vaultURL: testData.CLIENT.VAULT_URL)
//        InsertScenario(client: client, callback: callback)
//            .addRecord([
//                    "fields": getFieldValues(),
//                    "table": testData.VAULT.TABLE_NAME])
//            .execute()
//
//        wait(for: [expectation], timeout: 10.0)
//        XCTAssertEqual(callback.error?.code, 404)
//        XCTAssert(callback.error!.localizedDescription.contains(" not found"))
//    }
    
    func testInsertInvalidVaultURL() {
        let expectation = XCTestExpectation(description: "invalid vault url")
        let callback = DemoAPICallback(expectation: expectation)
        
        // Client no records
        let client = ClientScenario(tokenProvider: self.tokenProvider)
            .setVaultID(vaultId: testData.CLIENT.VAULT_ID)
            .setVaultUrl(vaultURL: testData.CLIENT.INVALID_VAULT_URL)
        InsertScenario(client: client, callback: callback)
            .addRecord([
                    "table": testData.VAULT.TABLE_NAME,
                    "fields": getFieldValues()])
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, -1002)
        XCTAssert(callback.error!.localizedDescription.contains("unsupported URL"))
    }
    
    func testInsertNoRecordsKey() {
        let error = ErrorCodes.RECORDS_KEY_ERROR().errorObject
        let expectation = XCTestExpectation(description: "no records - no vaultID")
        let callback = DemoAPICallback(expectation: expectation)
        
        // Normal Client - No records key
        let client = ClientScenario(tokenProvider: self.tokenProvider)
            .setVaultID(vaultId: testData.CLIENT.VAULT_ID)
            .setVaultUrl(vaultURL: testData.CLIENT.VAULT_URL)
        InsertScenario(client: client, callback: callback)
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, error.code)
        XCTAssert(callback.error!.localizedDescription.contains(error.localizedDescription))
    }

    
    func testInsertNoFieldsKey() {
        let error = Skyflow.ErrorCodes.FIELDS_KEY_ERROR().errorObject
        let tokenProvider = DemoTokenProvider()
        let expectation = XCTestExpectation(description: "Should fail")
        let callback = DemoAPICallback(expectation: expectation)
        
        let client = ClientScenario(tokenProvider: tokenProvider)
            .setVaultID(vaultId: testData.CLIENT.VAULT_ID)
            .setVaultUrl(vaultURL: testData.CLIENT.VAULT_URL)
        
        InsertScenario(client: client, callback: callback)
            .initiateRecords()
            .addRecord(["table": testData.VAULT.TABLE_NAME])
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, error.code)
        XCTAssert(callback.error!.localizedDescription.contains(error.localizedDescription))

    }
    
    func testInsertNoTableKey() {
        let error = Skyflow.ErrorCodes.TABLE_KEY_ERROR().errorObject
        let tokenProvider = DemoTokenProvider()
        let expectation = XCTestExpectation(description: "Should fail")
        let callback = DemoAPICallback(expectation: expectation)
        
        let client = ClientScenario(tokenProvider: tokenProvider)
            .setVaultID(vaultId: testData.CLIENT.INVALID_VAULT_ID)
            .setVaultUrl(vaultURL: testData.CLIENT.INVALID_VAULT_URL)
        
        InsertScenario(client: client, callback: callback)
            .initiateRecords()
            .addRecord(["fields": getFieldValues()])
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, error.code)
        XCTAssert(callback.error!.localizedDescription.contains(error.localizedDescription))
    }
    

}

