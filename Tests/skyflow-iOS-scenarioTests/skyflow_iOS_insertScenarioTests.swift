/*
 * Copyright (c) 2022 Skyflow
*/

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
    

}

