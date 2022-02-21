// swiftlint:disable file_length
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_scenarioTests: XCTestCase {
    var skyflow: Client!
    var tokenProvider: TokenProvider!
    
    override func setUp() {
        self.skyflow = Client(Configuration(tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
        self.tokenProvider = DemoTokenProvider()
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    func testInsertNoRecordsKey() {
        let error = ErrorCodes.EMPTY_VAULT_ID().errorObject
        let expectation = XCTestExpectation(description: "no records - no vaultID")
        let callback = DemoAPICallback(expectation: expectation)
        
        // Normal Client - No records key
        let client = ClientScenario(tokenProvider: self.tokenProvider)
            .setVaultID(vaultId: "vaultId")
            .setVaultUrl(vaultURL: "https://skyflow.com/insert")
        InsertScenario(client: client, callback: callback)
            .execute()
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, error.code)
        XCTAssertEqual(callback.error?.description, error.description)
    }
    
    func testInsertNoVaultID() {
        let error = ErrorCodes.EMPTY_VAULT_ID().errorObject
        let expectation = XCTestExpectation(description: "no records")
        let callback = DemoAPICallback(expectation: expectation)
        
        // Client no records
        let client = ClientScenario(tokenProvider: self.tokenProvider)
            .setVaultID(vaultId: "")
            .setVaultUrl(vaultURL: "")
        InsertScenario(client: client, callback: callback)
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, error.code)
        XCTAssertEqual(callback.error?.description, error.description)
    }
    
    func getDesc(errorCode: ErrorCodes) -> String {
        return errorCode.errorObject.localizedDescription
    }
    
    func testInsertNoFieldsKey() {
        let error = Skyflow.ErrorCodes.FIELDS_KEY_ERROR().errorObject
        let tokenProvider = DemoTokenProvider()
        let expectation = XCTestExpectation(description: "Should fail")
        let callback = DemoAPICallback(expectation: expectation)
        
        let client = ClientScenario(tokenProvider: tokenProvider)
            .setVaultID(vaultId: "vaultId")
            .setVaultUrl(vaultURL: "https://skyflow.com/insert")
        
        InsertScenario(client: client, callback: callback)
            .initiateRecords()
            .addRecord(record: ["table": "NoFieldsKeyHere"])
            .execute()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.error?.code, error.code)
        XCTAssertEqual(callback.error?.description, error.description)
        
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
        XCTAssertEqual(callback.error?.description, error.description)
        
    }

}

