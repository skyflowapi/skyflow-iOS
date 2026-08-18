/*
 * Copyright (c) 2022 Skyflow
*/

// Tests for the typed CollectRecordToken model and CollectRecord.tokens parsing
// ([String: [CollectRecordToken]]?, keyed by column name).

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class CollectRecordTokenParsingTests: XCTestCase {

    private func collectRecord(fields: Any?) -> CollectRecord {
        var dict: [String: Any] = ["tableName": "persons", "skyflowID": "id1", "httpCode": 200]
        if let fields = fields {
            dict["fields"] = fields
        }
        return CollectResponse(["records": [dict]])!.records[0]
    }

    private func collectRecord(hashedData: Any?) -> CollectRecord {
        var dict: [String: Any] = ["tableName": "persons", "skyflowID": "id1", "httpCode": 200]
        if let hashedData = hashedData {
            dict["hashedData"] = hashedData
        }
        return CollectResponse(["records": [dict]])!.records[0]
    }

    // MARK: - CollectRecordToken

    func testTokenPublicInit() {
        let token = CollectRecordToken(token: "tok-1", tokenGroupName: "deterministic", path: "card_number")

        XCTAssertEqual(token.token, "tok-1")
        XCTAssertEqual(token.tokenGroupName, "deterministic")
        XCTAssertEqual(token.path, "card_number")
    }

    func testTokenPublicInitDefaultsTokenGroupNameAndPathToNil() {
        let token = CollectRecordToken(token: "tok-1")
        XCTAssertNil(token.tokenGroupName)
        XCTAssertNil(token.path)
    }

    // MARK: - CollectRecord.tokens parsing

    func testTokensNilWhenFieldsKeyAbsent() {
        XCTAssertNil(collectRecord(fields: nil).tokens)
    }

    func testTokensParsesSingleTokenPerColumn() throws {
        let record = collectRecord(fields: [
            "card_number": [["token": "tok-1", "tokenGroupName": "vault"]]
        ])

        let tokens = try XCTUnwrap(record.tokens)
        XCTAssertEqual(tokens["card_number"]?.count, 1)
        XCTAssertEqual(tokens["card_number"]?.first?.token, "tok-1")
        XCTAssertEqual(tokens["card_number"]?.first?.tokenGroupName, "vault")
    }

    func testTokensParsesMultipleTokenGroupsForSameColumn() throws {
        let record = collectRecord(fields: [
            "card_number": [
                ["token": "tok-deterministic", "tokenGroupName": "deterministic"],
                ["token": "tok-vault", "tokenGroupName": "vault"]
            ]
        ])

        let tokens = try XCTUnwrap(record.tokens?["card_number"])
        XCTAssertEqual(tokens.count, 2)
        XCTAssertEqual(Set(tokens.map { $0.token }), ["tok-deterministic", "tok-vault"])
    }

    func testTokensParsesMultipleColumns() {
        let record = collectRecord(fields: [
            "card_number": [["token": "tok-1", "tokenGroupName": "vault"]],
            "cvv": [["token": "tok-2", "tokenGroupName": "vault"]]
        ])

        XCTAssertEqual(record.tokens?["card_number"]?.first?.token, "tok-1")
        XCTAssertEqual(record.tokens?["cvv"]?.first?.token, "tok-2")
    }

    func testTokensOmitsTokenGroupNameWhenAbsent() {
        let record = collectRecord(fields: [
            "card_number": [["token": "tok-1"]]
        ])

        XCTAssertEqual(record.tokens?["card_number"]?.first?.token, "tok-1")
        XCTAssertNil(record.tokens?["card_number"]?.first?.tokenGroupName)
    }

    func testTokensParsesPathWhenPresent() {
        let record = collectRecord(fields: [
            "card_number": [["token": "tok-1", "tokenGroupName": "vault", "path": "card_number"]]
        ])

        XCTAssertEqual(record.tokens?["card_number"]?.first?.path, "card_number")
    }

    func testTokensOmitsPathWhenAbsent() {
        let record = collectRecord(fields: [
            "card_number": [["token": "tok-1"]]
        ])

        XCTAssertNil(record.tokens?["card_number"]?.first?.path)
    }

    func testTokensDropsEntryMissingTokenKey() throws {
        let record = collectRecord(fields: [
            "card_number": [
                ["tokenGroupName": "vault"],
                ["token": "tok-1", "tokenGroupName": "deterministic"]
            ]
        ])

        let tokens = try XCTUnwrap(record.tokens?["card_number"])
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens.first?.token, "tok-1")
    }

    func testTokensDropsEntryWithNonStringTokenValue() {
        let record = collectRecord(fields: [
            "card_number": [["token": 12345]]
        ])

        XCTAssertEqual(record.tokens?["card_number"]?.count, 0)
    }

    func testTokensDropsColumnWithWrongShape() {
        // "fields" is expected to be a dict of column -> [token dict]; a column whose
        // value isn't an array of dictionaries at all is dropped rather than crashing.
        let record = collectRecord(fields: [
            "card_number": "not an array"
        ])

        XCTAssertNil(record.tokens?["card_number"])
    }

    func testTokensNilWhenFieldsIsJSONNull() {
        // JSONSerialization represents a JSON `null` as NSNull, not Swift nil/absence.
        let record = collectRecord(fields: NSNull())

        XCTAssertNil(record.tokens)
    }

    func testTokensDropsColumnWhenArrayContainsNonDictionaryEntry() {
        // A conditional cast to [[String: Any]] fails for the whole array if even one
        // element isn't a dictionary - the column is dropped, not partially parsed.
        let mixedArray: [Any] = [["token": "tok-1"], "not a dict"]
        let record = collectRecord(fields: ["card_number": mixedArray])

        XCTAssertNil(record.tokens?["card_number"])
    }

    // MARK: - CollectRecordHashedData

    func testHashedDataPublicInit() {
        let hashedData = CollectRecordHashedData(data: "abc123", hashName: "hash1")

        XCTAssertEqual(hashedData.data, "abc123")
        XCTAssertEqual(hashedData.hashName, "hash1")
    }

    // MARK: - CollectRecord.hashedData parsing

    func testHashedDataNilWhenKeyAbsent() {
        XCTAssertNil(collectRecord(hashedData: nil).hashedData)
    }

    func testHashedDataEmptyDictWhenTopLevelValueIsEmptyDict() {
        // "hashedData": {} (present but empty) is NOT the same as the key being absent -
        // compactMapValues on an empty dict returns an empty (non-nil) dict.
        let record = collectRecord(hashedData: [String: Any]())

        XCTAssertNotNil(record.hashedData)
        XCTAssertEqual(record.hashedData?.isEmpty, true)
    }

    func testHashedDataEmptyArrayWhenColumnValueIsEmptyArray() {
        // A column present with an empty array value keeps the key with an empty array,
        // rather than being dropped or treated as nil.
        let record = collectRecord(hashedData: ["cvv": [] as [Any]])

        XCTAssertNotNil(record.hashedData?["cvv"])
        XCTAssertEqual(record.hashedData?["cvv"]?.isEmpty, true)
    }

    func testHashedDataOnlyPresentForSomeColumns() {
        // If the vault only returns hashedData for a subset of collected columns (e.g. only
        // some columns have a hash configured), the other columns are simply absent as keys -
        // not present-with-nil, not present-with-empty-array.
        let record = collectRecord(hashedData: [
            "card_number": [["data": "hash-1", "hashName": "hash1"]]
        ])

        XCTAssertNotNil(record.hashedData?["card_number"])
        XCTAssertNil(record.hashedData?["cvv"])
        XCTAssertFalse(record.hashedData?.keys.contains("cvv") ?? true)
    }

    func testHashedDataParsesSingleEntryPerColumn() throws {
        let record = collectRecord(hashedData: [
            "card_number": [["data": "hash-value", "hashName": "hash1"]]
        ])

        let hashedData = try XCTUnwrap(record.hashedData)
        XCTAssertEqual(hashedData["card_number"]?.count, 1)
        XCTAssertEqual(hashedData["card_number"]?.first?.data, "hash-value")
        XCTAssertEqual(hashedData["card_number"]?.first?.hashName, "hash1")
    }

    func testHashedDataParsesMultipleEntriesForSameColumn() throws {
        let record = collectRecord(hashedData: [
            "card_number": [
                ["data": "hash-1", "hashName": "hash1"],
                ["data": "hash-2", "hashName": "hash2"]
            ]
        ])

        let hashedData = try XCTUnwrap(record.hashedData?["card_number"])
        XCTAssertEqual(hashedData.count, 2)
        XCTAssertEqual(Set(hashedData.map { $0.data }), ["hash-1", "hash-2"])
    }

    func testHashedDataParsesMultipleColumns() {
        let record = collectRecord(hashedData: [
            "card_number": [["data": "hash-1", "hashName": "hash1"]],
            "cvv": [["data": "hash-2", "hashName": "hash1"]]
        ])

        XCTAssertEqual(record.hashedData?["card_number"]?.first?.data, "hash-1")
        XCTAssertEqual(record.hashedData?["cvv"]?.first?.data, "hash-2")
    }

    func testHashedDataDropsEntryMissingHashNameKey() throws {
        let record = collectRecord(hashedData: [
            "card_number": [
                ["data": "hash-1"],
                ["data": "hash-2", "hashName": "hash1"]
            ]
        ])

        let hashedData = try XCTUnwrap(record.hashedData?["card_number"])
        XCTAssertEqual(hashedData.count, 1)
        XCTAssertEqual(hashedData.first?.data, "hash-2")
    }

    func testHashedDataDropsEntryWithNonStringDataValue() {
        let record = collectRecord(hashedData: [
            "card_number": [["data": 12345, "hashName": "hash1"]]
        ])

        XCTAssertEqual(record.hashedData?["card_number"]?.count, 0)
    }

    func testHashedDataDropsColumnWithWrongShape() {
        // hashedData is expected to be a dict of column -> [hash dict]; a column whose
        // value isn't an array of dictionaries at all is dropped rather than crashing.
        let record = collectRecord(hashedData: [
            "card_number": "not an array"
        ])

        XCTAssertNil(record.hashedData?["card_number"])
    }

    func testHashedDataNilWhenValueIsJSONNull() {
        // JSONSerialization represents a JSON `null` as NSNull, not Swift nil/absence.
        let record = collectRecord(hashedData: NSNull())

        XCTAssertNil(record.hashedData)
    }

    func testHashedDataDropsColumnWhenArrayContainsNonDictionaryEntry() {
        // A conditional cast to [[String: Any]] fails for the whole array if even one
        // element isn't a dictionary - the column is dropped, not partially parsed.
        let mixedArray: [Any] = [["data": "hash-1", "hashName": "hash1"], "not a dict"]
        let record = collectRecord(hashedData: ["card_number": mixedArray])

        XCTAssertNil(record.hashedData?["card_number"])
    }

    // MARK: - Whole record / whole response missing or malformed

    func testCollectRecordFromEmptyDictionaryHasAllNilFields() {
        let record = CollectResponse(["records": [[:] as [String: Any]]])!.records[0]

        XCTAssertNil(record.tableName)
        XCTAssertNil(record.skyflowId)
        XCTAssertNil(record.tokens)
        XCTAssertNil(record.hashedData)
        XCTAssertEqual(record.httpCode, 0)
        XCTAssertNil(record.error)
    }

    func testCollectResponseNilWhenRecordsKeyAbsent() {
        XCTAssertNil(CollectResponse(["norecords": []]))
    }

    func testCollectResponseNilWhenTopLevelIsNotADictionary() {
        XCTAssertNil(CollectResponse("not a dictionary"))
        XCTAssertNil(CollectResponse(["just", "an", "array"]))
        XCTAssertNil(CollectResponse(NSNull()))
    }

    func testCollectResponseNilWhenRecordsContainsNonDictionaryEntry() {
        // Same whole-array-cast-fails behavior as the per-column tokens array: one
        // non-dictionary entry in "records" fails the entire response, not just that entry.
        let mixedRecords: [Any] = [["tableName": "persons"], "not a dict"]
        XCTAssertNil(CollectResponse(["records": mixedRecords]))
    }

    func testCollectResponseEmptyRecordsArray() {
        XCTAssertEqual(CollectResponse(["records": [] as [[String: Any]]])?.records.count, 0)
    }
}
