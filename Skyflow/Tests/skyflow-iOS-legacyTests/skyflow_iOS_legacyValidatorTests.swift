/*
 * Copyright (c) 2022 Skyflow
*/

// Direct tests for the legacy (v1) RequestValidators: checkRecord,
// checkAdditionalFields, checkDetokenizeRecord and checkGetByIdEntry.
// (checkUpsertOptions is covered in skyflow_iOS_legacyUtilTests, and
// validateGetRecords in skyflow-iOS-getTests.)

import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class skyflow_iOS_legacyValidatorTests: XCTestCase {

    private func assertError(_ actual: ErrorCodes?, _ expected: ErrorCodes) {
        XCTAssertEqual(actual?.getErrorObject(contextOptions: ContextOptions()).localizedDescription,
                       expected.getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    // MARK: - checkRecord

    func testCheckRecordValid() {
        XCTAssertNil(RequestValidators.checkRecord(record: ["table": "persons", "fields": ["name": "john"]], index: 0))
    }

    func testCheckRecordMissingTable() {
        assertError(RequestValidators.checkRecord(record: ["fields": ["name": "john"]], index: 0),
                    .TABLE_KEY_ERROR(value: "0"))
    }

    func testCheckRecordInvalidTableType() {
        assertError(RequestValidators.checkRecord(record: ["table": 1, "fields": ["name": "john"]], index: 0),
                    .INVALID_TABLE_NAME_TYPE(value: "0"))
    }

    func testCheckRecordEmptyTableName() {
        assertError(RequestValidators.checkRecord(record: ["table": "", "fields": ["name": "john"]], index: 0),
                    .EMPTY_TABLE_NAME())
    }

    func testCheckRecordMissingFields() {
        assertError(RequestValidators.checkRecord(record: ["table": "persons"], index: 0),
                    .FIELDS_KEY_ERROR(value: "0"))
    }

    func testCheckRecordInvalidFieldsType() {
        assertError(RequestValidators.checkRecord(record: ["table": "persons", "fields": "not a dict"], index: 0),
                    .INVALID_FIELDS_TYPE(value: "0"))
    }

    func testCheckRecordEmptyFields() {
        assertError(RequestValidators.checkRecord(record: ["table": "persons", "fields": [:] as [String: Any]], index: 0),
                    .EMPTY_FIELDS_KEY(value: "0"))
    }

    // MARK: - checkAdditionalFields

    func testCheckAdditionalFieldsValid() {
        let additionalFields: [String: Any] = ["records": [["table": "persons", "fields": ["name": "john"]]]]

        XCTAssertNil(RequestValidators.checkAdditionalFields(additionalFields))
    }

    func testCheckAdditionalFieldsMissingRecordsKey() {
        assertError(RequestValidators.checkAdditionalFields(["norecords": []]),
                    .MISSING_RECORDS_IN_ADDITIONAL_FIELDS())
    }

    func testCheckAdditionalFieldsEmptyRecords() {
        assertError(RequestValidators.checkAdditionalFields(["records": [] as [[String: Any]]]),
                    .EMPTY_RECORDS_OBJECT())
    }

    func testCheckAdditionalFieldsInvalidRecordsType() {
        assertError(RequestValidators.checkAdditionalFields(["records": "not an array"]),
                    .INVALID_RECORDS_TYPE())
    }

    func testCheckAdditionalFieldsPropagatesRecordErrorWithIndex() {
        let additionalFields: [String: Any] = ["records": [
            ["table": "persons", "fields": ["name": "john"]],
            ["fields": ["name": "jane"]]
        ]]

        assertError(RequestValidators.checkAdditionalFields(additionalFields),
                    .TABLE_KEY_ERROR(value: "1"))
    }

    // MARK: - checkDetokenizeRecord

    func testCheckDetokenizeRecordValidWithoutRedaction() {
        XCTAssertNil(RequestValidators.checkDetokenizeRecord(token: ["token": "abc"], index: 0))
    }

    func testCheckDetokenizeRecordValidWithRedaction() {
        XCTAssertNil(RequestValidators.checkDetokenizeRecord(token: ["token": "abc", "redaction": RedactionType.MASKED], index: 0))
    }

    func testCheckDetokenizeRecordInvalidRedactionType() {
        assertError(RequestValidators.checkDetokenizeRecord(token: ["token": "abc", "redaction": "MASKED"], index: 0),
                    .INVALID_REDACTION_TYPE())
    }

    func testCheckDetokenizeRecordMissingToken() {
        assertError(RequestValidators.checkDetokenizeRecord(token: ["redaction": RedactionType.PLAIN_TEXT], index: 0),
                    .ID_KEY_ERROR())
    }

    func testCheckDetokenizeRecordInvalidTokenType() {
        assertError(RequestValidators.checkDetokenizeRecord(token: ["token": 123], index: 2),
                    .INVALID_TOKEN_TYPE(value: "2"))
    }

    // MARK: - checkGetByIdEntry

    private var validGetByIdEntry: [String: Any] {
        ["ids": ["id1"], "table": "persons", "redaction": RedactionType.PLAIN_TEXT]
    }

    func testCheckGetByIdEntryValid() {
        XCTAssertNil(RequestValidators.checkGetByIdEntry(entry: validGetByIdEntry, index: 0))
    }

    func testCheckGetByIdEntryEmpty() {
        assertError(RequestValidators.checkGetByIdEntry(entry: [:], index: 0),
                    .EMPTY_RECORDS_OBJECT())
    }

    func testCheckGetByIdEntryMissingIds() {
        assertError(RequestValidators.checkGetByIdEntry(entry: ["table": "persons", "redaction": RedactionType.PLAIN_TEXT], index: 0),
                    .MISSING_KEY_IDS(value: "0"))
    }

    func testCheckGetByIdEntryInvalidIdsType() {
        var entry = validGetByIdEntry
        entry["ids"] = "not an array"

        assertError(RequestValidators.checkGetByIdEntry(entry: entry, index: 0), .INVALID_IDS_TYPE())
    }

    func testCheckGetByIdEntryEmptyIdsArray() {
        var entry = validGetByIdEntry
        entry["ids"] = [] as [String]

        assertError(RequestValidators.checkGetByIdEntry(entry: entry, index: 0), .EMPTY_IDS(value: "0"))
    }

    func testCheckGetByIdEntryEmptyIdValue() {
        var entry = validGetByIdEntry
        entry["ids"] = ["id1", ""]

        assertError(RequestValidators.checkGetByIdEntry(entry: entry, index: 0), .EMPTY_ID_VALUE(value: "0"))
    }

    func testCheckGetByIdEntryMissingTable() {
        assertError(RequestValidators.checkGetByIdEntry(entry: ["ids": ["id1"], "redaction": RedactionType.PLAIN_TEXT], index: 0),
                    .TABLE_KEY_ERROR(value: "0"))
    }

    func testCheckGetByIdEntryInvalidTableType() {
        var entry = validGetByIdEntry
        entry["table"] = 5

        assertError(RequestValidators.checkGetByIdEntry(entry: entry, index: 0), .INVALID_TABLE_NAME_TYPE(value: "0"))
    }

    func testCheckGetByIdEntryEmptyTableName() {
        var entry = validGetByIdEntry
        entry["table"] = ""

        assertError(RequestValidators.checkGetByIdEntry(entry: entry, index: 0), .EMPTY_TABLE_NAME())
    }

    func testCheckGetByIdEntryMissingRedaction() {
        assertError(RequestValidators.checkGetByIdEntry(entry: ["ids": ["id1"], "table": "persons"], index: 0),
                    .REDACTION_KEY_ERROR(value: "0"))
    }

    func testCheckGetByIdEntryInvalidRedactionType() {
        var entry = validGetByIdEntry
        entry["redaction"] = "PLAIN_TEXT"

        assertError(RequestValidators.checkGetByIdEntry(entry: entry, index: 0), .INVALID_REDACTION_TYPE())
    }

    // MARK: - validateGetRecords (branches not covered by skyflow-iOS-getTests)

    func testValidateGetRecordsEmptyTableName() {
        let entry: [String: Any] = ["ids": ["id1"], "table": "", "redaction": RedactionType.PLAIN_TEXT]

        assertError(RequestValidators.validateGetRecords(entry: entry, getOptions: GetOptions(), index: 0),
                    .EMPTY_TABLE_NAME())
    }

    func testValidateGetRecordsColumnNameWithoutColumnValues() {
        let entry: [String: Any] = ["table": "persons", "columnName": "email", "redaction": RedactionType.PLAIN_TEXT]

        assertError(RequestValidators.validateGetRecords(entry: entry, getOptions: GetOptions(), index: 0),
                    .MISSING_RECORD_COLUMN_VALUE())
    }
}
