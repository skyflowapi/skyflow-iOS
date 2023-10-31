//
//  Test.swift
//  
//
//  Created by Bharti Sagar on 12/06/23.
//

import Foundation
import XCTest
@testable import Skyflow

class skyflow_iOS_ValidateGetRecordTest: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(
            vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
            vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
            tokenProvider: DemoTokenProvider(),
            options: Options(logLevel: .DEBUG)))
    }

    override func tearDown() {
        skyflow = nil
    }
    
    func testEmptyRecords(){
        let errorCode: ErrorCodes! = self.skyflow.validateGetRecords(entry:[:], getOptions: GetOptions())
        print(errorCode!)
        XCTAssertEqual(errorCode.description, ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }
    
    func testIdRecordEmptyRecordsObject(){
        let errorCode = self.skyflow.validateGetRecords(entry:["id": [], "table": "table1", "redaction": RedactionType.REDACTED], getOptions: GetOptions())
        XCTAssertEqual(errorCode?.description, ErrorCodes.MISSING_IDS_OR_COLUMN_VALUES_IN_GET().description)
    }
    
    func testIdRecordEmptyRecordsObject2(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": "demo"], getOptions: GetOptions())
        XCTAssertEqual(errorCode!.description, ErrorCodes.INVALID_IDS_TYPE().description)
    }
    func testIdRecordEmptyRecordsObject3(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": [[:]]], getOptions: GetOptions())
        XCTAssertEqual(errorCode!.description, ErrorCodes.INVALID_IDS_TYPE().description)
    }
    
    func testIdRecordEmptyRecordsInvalid(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": [12]], getOptions: GetOptions())
        XCTAssertEqual(errorCode!.description, ErrorCodes.INVALID_IDS_TYPE().description)
    }
    func testIdRecordEmptyRecordsInvalid2(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": ["123", 12]], getOptions: GetOptions())
        XCTAssertEqual(errorCode!.description, ErrorCodes.INVALID_IDS_TYPE().description)
    }
    func testIdRecordEmptyRecordsInvalid3(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": []], getOptions: GetOptions())
        XCTAssertEqual(errorCode!.description, ErrorCodes.EMPTY_IDS().description)
    }
    func testIdRecordEmptyRecordsInvalid4(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": [""]], getOptions: GetOptions())
        XCTAssertEqual(errorCode!.description, ErrorCodes.EMPTY_ID_VALUE().description)
    }
    func testInvalidRecordTableMissing(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": ["123"]], getOptions: GetOptions())
        XCTAssertEqual(errorCode!.description, ErrorCodes.TABLE_KEY_ERROR().description)
    }
    func testIdRecordEmptyRecordsInvalidTable(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": ["123"], "table": []], getOptions: GetOptions())
        XCTAssertEqual(errorCode!.description, ErrorCodes.INVALID_TABLE_NAME_TYPE().description)
    }
    func testIdRecordEmptyRecordsInvalid6(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": ["123"], "table": "table1"], getOptions: GetOptions())
        XCTAssertEqual(errorCode!.description, ErrorCodes.REDACTION_KEY_ERROR().description)
    }
    func testIdRecordEmptyRecordsInvalidTokenFalse(){
        let errorCode = self.skyflow.validateGetRecords(entry: ["ids": ["123"], "table": "table1"], getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode!.description, ErrorCodes.REDACTION_KEY_ERROR().description)
    }
    func testIdRecordEmptyRecordsInvalidRedaction(){
        let entry = ["ids": ["123"], "table": "table1", "redaction": []] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode!.description, ErrorCodes.INVALID_REDACTION_TYPE(value: String(describing: entry["redaction"])).description)
    }
    func testIdRecordEmptyRecordsValidRedaction(){
        let entry = ["ids": ["123"], "table": "table1", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertNil(errorCode)
    }
    func testIdRecordEmptyRecordsValidRedactionGetOptionTrue(){
        let entry = ["ids": ["123"], "table": "table1", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: true))
        XCTAssertEqual(errorCode?.description, ErrorCodes.REDACTION_WITH_TOKEN_NOT_SUPPORTED().description)
    }
    func testIdRecordEmptyRecordsNoRedactionGetOptionTrue(){
        let entry = ["ids": ["123"], "table": "table1", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: true))
        XCTAssertEqual(errorCode?.description, ErrorCodes.REDACTION_WITH_TOKEN_NOT_SUPPORTED().description)
    }
    func testColumnRecordEmptyRecordsNoRedactionGetOptionTrue(){
        let entry = ["table": "demo"] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: true))
        XCTAssertEqual(errorCode?.description, ErrorCodes.MISSING_IDS_OR_COLUMN_VALUES_IN_GET().description)
    }
    func testColumnRecordInvalidcolumnValues(){
        let entry = ["columnValues": "", "table": "demo","redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode?.description, ErrorCodes.INVALID_COLUMN_VALUES_IN_GET().description)
    }
    func testColumnRecordInvalidEmptycolumnValues(){
        let entry = ["columnValues": [], "table": "demo", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode?.description, ErrorCodes.EMPTY_COLUMN_VALUE().description)
    }
    func testColumnRecordInvalidcolumnValuesArrayValues(){
        let entry = ["columnValues": [[]], "table": "demo", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode?.description, ErrorCodes.INVALID_COLUMN_VALUES_IN_GET().description)
    }
    func testColumnRecordEmptycolumnValueArrayValues(){
        let entry = ["columnValues": ["1234", ""], "table": "demo", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode?.description, ErrorCodes.EMPTY_COLUMN_VALUE().description)
    }
    func testColumnRecordInvalidcolumnNameArrayValues(){
        let entry = ["columnValues": ["1234"], "table": "demo", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode?.description, ErrorCodes.MISSING_COLUMN_NAME().description)
    }
    func testColumnRecordInvalidcolumnNameValues(){
        let entry = ["columnValues": ["1234"], "table": "demo", "columnName": [], "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode?.description, ErrorCodes.INVALID_COLUMN_NAME().description)
    }
    func testColumnRecordEmptycolumnNameValuesOptionTrue(){
        let entry = ["columnValues": ["1234"], "table": "demo", "columnName": "", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode?.description, ErrorCodes.EMPTY_COLUMN_NAME().description)
    }
    func testColumnRecordValidcolumnNameValuesOptionTrue(){
        let entry = ["columnValues": ["1234"], "table": "demo", "columnName": "123", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertNil(errorCode)
    }
    func testColumnRecordValidcolumnNameValuesOptionTrueWithId(){
        let entry = ["columnValues": ["1234"], "table": "demo", "columnName": "123", "ids": ["123"], "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode!.description, ErrorCodes.SKYFLOW_IDS_AND_COLUMN_NAME_BOTH_SPECIFIED().description)
    }
    func testColumnRecordValidcolumnValuesValuesOptionTrueWithId(){
        let entry = ["columnValues": ["1234"], "table": "demo", "ids": ["123"], "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: false))
        XCTAssertEqual(errorCode?.description, ErrorCodes.MISSING_COLUMN_NAME().description)
    }
    
    func testColumnRecordValidcolumnValuesValuesOptionTrue2(){
        let entry = ["columnValues": ["1234"], "table": "demo", "redaction": RedactionType.REDACTED] as [String : Any]
        let errorCode = self.skyflow.validateGetRecords(entry: entry, getOptions: GetOptions(tokens: true))
        XCTAssertEqual(errorCode?.description, ErrorCodes.TOKENS_GET_COLUMN_NOT_SUPPPORTED().description)
    }
    
}
