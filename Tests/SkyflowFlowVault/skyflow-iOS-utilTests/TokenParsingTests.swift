/*
 * Copyright (c) 2022 Skyflow
*/

// Tests for the typed Token model and CollectRecord.tokens parsing
// ([String: [Token]]?, keyed by column name).

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class TokenParsingTests: XCTestCase {

    private func collectRecord(fields: Any?) -> CollectRecord {
        var dict: [String: Any] = ["tableName": "persons", "skyflowID": "id1", "httpCode": 200]
        if let fields = fields {
            dict["fields"] = fields
        }
        return CollectResponse(["records": [dict]])!.records[0]
    }

    // MARK: - Token

    func testTokenPublicInit() {
        let token = Token(token: "tok-1", tokenGroupName: "deterministic")

        XCTAssertEqual(token.token, "tok-1")
        XCTAssertEqual(token.tokenGroupName, "deterministic")
    }

    func testTokenPublicInitDefaultsTokenGroupNameToNil() {
        XCTAssertNil(Token(token: "tok-1").tokenGroupName)
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
