// swiftlint:disable file_length
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_scenarioTests: XCTestCase {
    var skyflow: Client!
    var tokenProvider: TokenProvider!
    var testData: TestData!
    
    override func setUp() {
        self.skyflow = Client(Configuration(tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
        self.tokenProvider = DemoTokenProvider()
        self.testData = try! JSONDecoder().decode(TestData.self, from: Data(ProcessInfo.processInfo.environment["TEST_DATA"]!.utf8))
    }
    
    override func tearDown() {
        skyflow = nil
        self.testData = nil
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
//        XCTAssertEqual(callback.error!.localizedDescription, error.localizedDescription)
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
            .addRecord(record: ["table": testData.VAULT.TABLE_NAME])
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
            .setVaultID(vaultId: "vaultId")
            .setVaultUrl(vaultURL: "https://skyflow.com/insert")
        
        InsertScenario(client: client, callback: callback)
            .initiateRecords()
            .addRecord(record: ["fields": ["value": "NoTableKeyHere"]])
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, error.code)
        XCTAssert(callback.error!.localizedDescription.contains(error.localizedDescription))

    }

}

