/*
 * Copyright (c) 2022 Skyflow
*/

// Covers FlowVault paths a coverage audit found had NO test exercising them. Each test here
// pins behaviour that was previously unobserved - several of these are silent-failure paths
// (data quietly dropped, or an error reported as success), which is exactly the shape of bug
// that survives a large-but-uneven suite.
//
// Where current behaviour looks wrong rather than merely untested, the test asserts what the
// code ACTUALLY does today and says so, so the test documents reality instead of pretending
// the gap is fixed. Those are marked "DOCUMENTS CURRENT BEHAVIOUR".

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class FlowVaultUncoveredPathTests: XCTestCase {

    private func makeCollectCallback(records: [String: Any] = ["records": []]) -> FlowVaultCollectAPICallback {
        FlowVaultCollectAPICallback(
            callback: DemoAPICallback(expectation: XCTestExpectation()),
            apiClient: APIClient(vaultID: "v", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: records,
            upsert: nil,
            contextOptions: ContextOptions()
        )
    }

    private func makeRevealCallback() -> FlowVaultRevealAPICallback {
        FlowVaultRevealAPICallback(
            callback: DemoAPICallback(expectation: XCTestExpectation()),
            apiClient: APIClient(vaultID: "v", vaultURL: "", tokenProvider: DemoTokenProvider()),
            connectionUrl: "",
            records: [],
            contextOptions: ContextOptions()
        )
    }

    // MARK: - flattenUpdates: had ZERO tests, and every failure mode is silent

    // A malformed update entry is `continue`d, so the record is dropped with no error. If that
    // was the only update record, hasUpdate goes false and collect() silently degrades to an
    // insert-only call - the caller is never told their update was discarded.

    func testFlattenUpdatesKeepsAWellFormedEntry() {
        let result = makeCollectCallback().flattenUpdates([
            "id1": ["table": "persons", "fields": ["name": "John"]]
        ])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["skyflowID"] as? String, "id1")
        XCTAssertEqual(result[0]["tableName"] as? String, "persons")
        XCTAssertEqual(result[0]["data"] as? [String: String], ["name": "John"])
    }

    func testFlattenUpdatesSilentlyDropsEntryMissingTableKey() {
        // DOCUMENTS CURRENT BEHAVIOUR: dropped, not surfaced as an error.
        let result = makeCollectCallback().flattenUpdates([
            "id1": ["fields": ["name": "John"]]
        ])
        XCTAssertTrue(result.isEmpty, "entry with no \"table\" is discarded silently")
    }

    func testFlattenUpdatesSilentlyDropsEntryMissingFieldsKey() {
        let result = makeCollectCallback().flattenUpdates([
            "id1": ["table": "persons"]
        ])
        XCTAssertTrue(result.isEmpty, "entry with no \"fields\" is discarded silently")
    }

    func testFlattenUpdatesSilentlyDropsEntryWithNonDictValue() {
        let result = makeCollectCallback().flattenUpdates(["id1": "not a dict"])
        XCTAssertTrue(result.isEmpty)
    }

    func testFlattenUpdatesSilentlyDropsEntryWithWrongTypedTableOrFields() {
        let result = makeCollectCallback().flattenUpdates([
            "id1": ["table": 123, "fields": ["name": "John"]],
            "id2": ["table": "persons", "fields": "not a dict"]
        ])
        XCTAssertTrue(result.isEmpty, "wrong-typed table/fields are both discarded")
    }

    func testFlattenUpdatesKeepsGoodEntriesAlongsideBadOnes() {
        // The important one: a partially malformed update map must not lose the valid rows too.
        let result = makeCollectCallback().flattenUpdates([
            "good": ["table": "persons", "fields": ["name": "John"]],
            "bad": ["table": "persons"]
        ])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["skyflowID"] as? String, "good")
    }

    func testFlattenUpdatesOnEmptyMapYieldsNoRecords() {
        XCTAssertTrue(makeCollectCallback().flattenUpdates([:]).isEmpty)
    }

    // MARK: - collect with neither bucket populated: no network call at all

    func testCollectWithNoInsertAndNoUpdateReportsEmptySuccessWithoutHittingTheNetwork() {
        let expectation = XCTestExpectation(description: "empty collect completes")
        var records: [CollectRecord]?
        let callback = CollectCallback(
            onSuccess: { response in records = response.records; expectation.fulfill() },
            onFailure: { _ in XCTFail("empty payload should not fail"); expectation.fulfill() }
        )
        // vaultURL is deliberately unusable - proving no request was attempted.
        FlowVaultCollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "v", vaultURL: "not a url at all", tokenProvider: DemoTokenProvider()),
            records: ["records": [], "update": [:]],
            upsert: nil,
            contextOptions: ContextOptions()
        ).onSuccess("dummy-token")

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(records?.count, 0)
    }

    // MARK: - CVV capture: the unmasked-real-token risk

    private func makeCVVElement(tableName: String, skyflowId: String? = nil,
                                returnMockValue: Bool, type: ElementType = .CVV,
                                column: String = "cvv", value: String = "123") -> TextField {
        let client = Client(Configuration(vaultID: "id", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()))
        let container = client.container(type: ContainerType.COLLECT)!
        let input = CollectElementInput(tableName: tableName, column: column, type: type, skyflowId: skyflowId)
        let element = container.create(input: input, options: CollectElementOptions(returnMockValue: returnMockValue))
        UIWindow().addSubview(element)
        // Not setValue(value:) - that is gated on env == .DEV (see the test below), so it is a
        // no-op for a default-env client. This is the pattern the rest of the suite uses.
        element.textField.secureText = value
        element.updateActualValue()
        return element
    }

    /// Pins the DEV gating on the public setValue(value:). It is easy to assume it always works -
    /// it silently does nothing outside the DEV environment, which is exactly how the first draft
    /// of the CVV tests above ended up capturing "" instead of the value they thought they set.
    func testSetValueIsANoOpOutsideDevEnvironmentButWorksInDev() {
        func element(env: Env) -> TextField {
            let client = Client(Configuration(vaultID: "id", vaultURL: "https://example.org/",
                                              tokenProvider: DemoTokenProvider(), options: Options(env: env)))
            let container = client.container(type: ContainerType.COLLECT)!
            let field = container.create(input: CollectElementInput(tableName: "cards", column: "cvv", type: .CVV),
                                         options: CollectElementOptions(required: false))
            UIWindow().addSubview(field)
            return field
        }

        let devElement = element(env: .DEV)
        devElement.setValue(value: "123")
        XCTAssertEqual(devElement.getValue(), "123", "setValue must work in DEV")

        let prodElement = element(env: .PROD)
        prodElement.setValue(value: "123")
        XCTAssertEqual(prodElement.getValue(), "", "setValue is intentionally inert outside DEV - programmatic injection into a secure field is a DEV-only affordance")
    }

    func testCaptureCVVMapUsesRecordIdBranchWhenSkyflowIdPresent() {
        let map = CVVTokenReplacer.captureCVVMap(elements: [
            makeCVVElement(tableName: "cards", skyflowId: "row-1", returnMockValue: true)
        ])
        XCTAssertEqual(map.byRecordId["row-1"]?["cvv"], "123")
        XCTAssertTrue(map.byTable.isEmpty, "an element with a skyflowId must not also land in byTable")
    }

    func testCaptureCVVMapFallsBackToTableBranchWhenSkyflowIdIsEmptyString() {
        // An empty-string skyflowId is not a real row id; capture must still happen via byTable,
        // otherwise the element is skipped and its REAL vault token reaches the app unmasked.
        let map = CVVTokenReplacer.captureCVVMap(elements: [
            makeCVVElement(tableName: "cards", skyflowId: "", returnMockValue: true)
        ])
        XCTAssertTrue(map.byRecordId.isEmpty)
        XCTAssertEqual(map.byTable["cards"]?["cvv"], "123", "empty skyflowId must fall through to the table branch, not drop the element")
    }

    func testCaptureCVVMapCapturesEvenWhenTableNameIsEmptyString() {
        // tableName "" is still non-nil, so the element is captured under the "" key rather than
        // skipped. Pinning this because skipping would silently leak the real token.
        let map = CVVTokenReplacer.captureCVVMap(elements: [
            makeCVVElement(tableName: "", returnMockValue: true)
        ])
        XCTAssertEqual(map.byTable[""]?["cvv"], "123")
        XCTAssertFalse(map.isEmpty, "an empty table name must not make the whole map empty - that would disable masking")
    }

    func testCaptureCVVMapIgnoresNonCVVAndNonMockingElements() {
        let map = CVVTokenReplacer.captureCVVMap(elements: [
            makeCVVElement(tableName: "cards", returnMockValue: true, type: .PIN, column: "pin"),
            makeCVVElement(tableName: "cards", returnMockValue: false, column: "cvv2")
        ])
        XCTAssertTrue(map.isEmpty, "only CVV elements with returnMockValue == true may be captured")
    }

    // MARK: - Reveal response body: silent success on a malformed error body

    func testDetokenizeBodyWithNonArrayResponseKeyYieldsNoRecords() throws {
        // DOCUMENTS CURRENT BEHAVIOUR (and a sharp edge): processResponse only checks that
        // "response" is non-nil before routing here, so a 4xx body like {"response": null}
        // becomes an empty SUCCESS - the failure is swallowed rather than raised.
        for malformed in [NSNull(), "a string", [] as [Any], ["not", "dicts"]] as [Any] {
            let data = try JSONSerialization.data(withJSONObject: ["response": malformed], options: .fragmentsAllowed)
            let result = try makeRevealCallback().getDetokenizeResponseBody(data: data)
            XCTAssertEqual((result["records"] as? [[String: Any]])?.count, 0,
                           "malformed \"response\" value \(malformed) yields zero records instead of an error")
        }
    }

    func testDetokenizeBodyTreatsNonStringErrorAsSuccessEntry() throws {
        // DOCUMENTS CURRENT BEHAVIOUR: `entry["error"] as? String` fails for a nested dict, so the
        // entry takes the success branch and is reported as revealed despite carrying an error.
        let data = try JSONSerialization.data(withJSONObject: ["response": [
            ["token": "tok-1", "error": ["message": "boom"], "httpCode": 400]
        ]], options: .fragmentsAllowed)

        let result = try makeRevealCallback().getDetokenizeResponseBody(data: data)
        let records = try XCTUnwrap(result["records"] as? [[String: Any]])
        XCTAssertEqual(records.count, 1)
        XCTAssertNil(records[0]["error"], "a non-String error is not carried through as an error today")
        XCTAssertEqual(records[0]["token"] as? String, "tok-1")
    }

    func testDetokenizeBodySplitsErrorAndSuccessEntries() throws {
        let data = try JSONSerialization.data(withJSONObject: ["response": [
            ["token": "ok-1", "value": "4111", "tokenGroupName": "det", "httpCode": 200,
             "metadata": ["tableName": "cards", "skyflowID": "row-1"]],
            ["token": "bad-1", "error": "Invalid Token", "httpCode": 404]
        ]], options: .fragmentsAllowed)

        let records = try XCTUnwrap(try makeRevealCallback().getDetokenizeResponseBody(data: data)["records"] as? [[String: Any]])
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[0]["value"] as? String, "4111")
        XCTAssertNotNil(records[0]["metadata"])
        XCTAssertEqual(records[1]["error"] as? String, "Invalid Token")
        XCTAssertNil(records[1]["value"], "an error entry must not carry a revealed value")
    }

    func testDetokenizeBodyWithMissingResponseKeyYieldsNoRecords() throws {
        let data = try JSONSerialization.data(withJSONObject: ["unexpected": []], options: .fragmentsAllowed)
        let result = try makeRevealCallback().getDetokenizeResponseBody(data: data)
        XCTAssertEqual((result["records"] as? [[String: Any]])?.count, 0)
    }

    // MARK: - RevealResponse: one bad entry discards every good record

    func testRevealResponseReturnsNilWhenRecordsContainsANonDictionaryEntry() {
        // Mirrors the CollectResponse case already covered in CollectRecordTokenParsingTests: the
        // whole-array cast fails, so a single junk entry loses all the valid records with it.
        let mixed: [Any] = [["token": "tok-1"], "not a dict"]
        XCTAssertNil(RevealResponse(["records": mixed]))
    }

    func testRevealResponseDropsOnlyUnparseableEntriesWhenAllAreDictionaries() {
        // compactMap at the RevealRecord level: an entry missing "token" is dropped individually
        // while its well-formed siblings survive.
        let response = RevealResponse(["records": [
            ["token": "tok-1", "httpCode": 200],
            ["httpCode": 200],
            ["token": "tok-2", "httpCode": 200]
        ]])
        XCTAssertEqual(response?.records.count, 2)
        XCTAssertEqual(response?.records.map { $0.token }, ["tok-1", "tok-2"])
    }

    // MARK: - Validator inconsistency: whitespace handling differs between validators

    func testWhitespaceOnlyTableNameIsAcceptedByUpsertAndRecordValidators() {
        // DOCUMENTS CURRENT BEHAVIOUR + a real inconsistency worth knowing about:
        // checkTokenGroupRedactions TRIMS before rejecting, but these two only check == "" /
        // isEmpty, so "  " sails through and reaches the wire.
        XCTAssertNil(RequestValidators.checkUpsertOptions([UpsertOptions(tableName: "  ", uniqueColumns: ["c"])]),
                     "whitespace-only tableName is accepted by checkUpsertOptions")
        XCTAssertNil(RequestValidators.checkRecord(record: AdditionalFieldsRecord(tableName: "  ", data: ["c": "v"]), index: 0),
                     "whitespace-only tableName is accepted by checkRecord")

        // Contrast: the redaction validator does trim, and rejects.
        XCTAssertNotNil(RequestValidators.checkTokenGroupRedactions([TokenGroupRedaction(tokenGroupName: "  ", redaction: "MASKED")]),
                        "checkTokenGroupRedactions trims and rejects - the inconsistency this test pins")
    }

    func testEmptyTokenGroupRedactionsArrayIsAcceptedUnlikeEmptyUpsertArray() {
        // Another asymmetry: [] is fine for redactions but an error for upsert.
        XCTAssertNil(RequestValidators.checkTokenGroupRedactions([]))
        XCTAssertNotNil(RequestValidators.checkUpsertOptions([]))
    }

    // MARK: - Insert request body: silent upsert no-op and force-cast crash surface

    func testInsertRequestBodyOmitsTableNameAndUpsertWhenTableIsMissing() {
        // DOCUMENTS CURRENT BEHAVIOUR: no tableName emitted AND the upsert option is silently
        // skipped, so an upsert-intent request degrades to a plain insert with no warning.
        let body = CollectRequestBuilder.createInsertRequestBody(
            vaultID: "v",
            records: ["records": [["fields": ["c": "v"]]]],
            upsert: [UpsertOptions(tableName: "cards", uniqueColumns: ["c"])]
        )
        let records = body["records"] as? [[String: Any]]
        XCTAssertNil(records?[0]["tableName"])
        XCTAssertNil(records?[0]["upsert"], "upsert is dropped when the record has no table")
    }

    func testInsertRequestBodyIgnoresUpsertOptionThatMatchesNoRecordTable() {
        let body = CollectRequestBuilder.createInsertRequestBody(
            vaultID: "v",
            records: ["records": [["table": "cards", "fields": ["c": "v"]]]],
            upsert: [UpsertOptions(tableName: "typo_table", uniqueColumns: ["c"])]
        )
        let records = body["records"] as? [[String: Any]]
        XCTAssertEqual(records?[0]["tableName"] as? String, "cards")
        XCTAssertNil(records?[0]["upsert"], "a non-matching upsert tableName is a silent no-op")
    }

    func testInsertRequestBodyAttachesUpsertWithUpdateTypeWhenTableMatches() {
        let body = CollectRequestBuilder.createInsertRequestBody(
            vaultID: "v",
            records: ["records": [["table": "cards", "fields": ["c": "v"]]]],
            upsert: [UpsertOptions(tableName: "cards", uniqueColumns: ["c"])]
        )
        let records = body["records"] as? [[String: Any]]
        let upsert = records?[0]["upsert"] as? [String: Any]
        XCTAssertEqual(upsert?["uniqueColumns"] as? [String], ["c"])
    }
}
