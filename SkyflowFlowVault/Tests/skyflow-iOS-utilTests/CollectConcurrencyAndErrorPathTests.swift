/*
 * Copyright (c) 2022 Skyflow
*/

// Closes the three test-suite blind spots that let the collect-path bugs ship. Each gap was a
// CATEGORY of test that did not exist, not a scenario someone forgot:
//
//   1. No test ever made request/response handling THROW, so the `catch` arms in the
//      insert+update merge were never executed - and both stuffed a String into the errors array
//      where SkyflowError.wrap expects an NSError, collapsing the real reason into code:0.
//   2. No test anywhere in the suite ran anything CONCURRENTLY, so CollectRequestBuilder's
//      static mutable state and the merge's shared accumulators were structurally unreachable.
//   3. Producer and consumer were only ever tested in isolation, so nobody noticed
//      getCollectResponseBody always emitted the token-map key while CollectRecord treated it as
//      optional. (Covered in CollectResponseWireKeyContractTests - kept separate because it's a
//      key-contract concern rather than a concurrency/error-path one.)

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class CollectConcurrencyAndErrorPathTests: XCTestCase {

    private func mixedRecords() -> [String: Any] {
        // Both buckets populated - the only shape that triggers the two-parallel-request merge.
        return [
            "records": [["table": "cards", "fields": ["card_number": "4111"]]],
            "update": ["id1": ["table": "persons", "fields": ["name": "John"]]]
        ]
    }

    private func makeCallback(records: [String: Any], callback: Callback) -> FlowVaultCollectAPICallback {
        FlowVaultCollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: records,
            upsert: nil,
            contextOptions: ContextOptions()
        )
    }

    private func withMockedSession(_ body: () -> Void) {
        let mockConfiguration = URLSessionConfiguration.ephemeral
        mockConfiguration.protocolClasses = [MockURLProtocol.self]
        let original = FlowVaultCollectAPICallback.urlSessionConfiguration
        FlowVaultCollectAPICallback.urlSessionConfiguration = mockConfiguration
        defer { FlowVaultCollectAPICallback.urlSessionConfiguration = original }
        body()
    }

    // MARK: - Gap 1: the catch arms in the merge were never executed by any test

    /// The reachable route into those catch arms is a malformed response body: processResponse ->
    /// getCollectResponseBody -> JSONSerialization.jsonObject throws a real (catchable) NSError.
    /// Pre-fix that NSError was flattened to .localizedDescription, so SkyflowError.wrap could not
    /// recognise it and fell through to `code: 0` with a raw interpolation of the whole internal
    /// {"records":…, "errors":…} merge container. This asserts the caller gets a real error instead.
    func testMalformedBodyInOneMergeHalfSurfacesARealErrorNotAGenericCodeZeroDump() {
        withMockedSession {
            MockURLProtocol.requestHandler = { request in
                let url = request.url!.absoluteString
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                if url.contains("v2/records/insert") {
                    let body: [String: Any] = ["records": [["skyflowID": "insertedId", "tableName": "cards", "httpCode": 200]]]
                    return (response, try! JSONSerialization.data(withJSONObject: body))
                }
                // Update half returns bytes that are not valid JSON at all -> throws inside the
                // dataTask completion handler, landing in the catch arm under test.
                return (response, Data("{ this is not json".utf8))
            }

            let expectation = XCTestExpectation(description: "malformed update body surfaces a real error")
            var received: SkyflowError?
            let callback = CollectCallback(
                onSuccess: { _ in
                    XCTFail("a malformed body in one half must not report success")
                    expectation.fulfill()
                },
                onFailure: { error in
                    received = error
                    expectation.fulfill()
                }
            )

            makeCallback(records: mixedRecords(), callback: callback).onSuccess("dummy-token")
            wait(for: [expectation], timeout: 10.0)

            guard let error = received else { return XCTFail("no error delivered") }
            XCTAssertFalse(error.message.isEmpty, "the failure reason must not be empty")
            // The pre-fix signature: code 0 plus a Swift-interpolated dump of the merge container.
            XCTAssertNotEqual(error.httpCode, 0, "code 0 means wrap() could not recognise the payload - the NSError was flattened again")
            XCTAssertFalse(error.message.contains("\"errors\""), "the message is dumping the internal merge container instead of the real reason")
            XCTAssertFalse(error.message.hasPrefix("["), "the message is a raw collection dump, not a real error description")
        }
    }

    // MARK: - Gap 2a: the merge itself, repeated - shared accumulators used to race here

    /// A race is not reproducible in one run, so this repeats the merge and asserts the result is
    /// byte-stable. It also pins the post-fix guarantee that insert records precede update records
    /// (a shared accumulator produced whichever-finished-first ordering).
    func testMergedInsertAndUpdateIsStableAndDeterministicAcrossRepeatedRuns() {
        withMockedSession {
            MockURLProtocol.requestHandler = { request in
                let url = request.url!.absoluteString
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                let body: [String: Any]
                if url.contains("v2/records/insert") {
                    body = ["records": [
                        ["skyflowID": "ins-1", "tableName": "cards", "httpCode": 200],
                        ["skyflowID": "ins-2", "tableName": "cards", "httpCode": 200]
                    ]]
                } else {
                    body = ["records": [["skyflowID": "upd-1", "tableName": "persons", "httpCode": 200]]]
                }
                return (response, try! JSONSerialization.data(withJSONObject: body))
            }

            var signatures: [String] = []
            for run in 1...12 {
                let expectation = XCTestExpectation(description: "merge run \(run)")
                let callback = CollectCallback(
                    onSuccess: { response in
                        signatures.append(response.records.map { "\($0.tableName ?? "-"):\($0.skyflowId ?? "-")" }.joined(separator: "|"))
                        expectation.fulfill()
                    },
                    onFailure: { error in
                        signatures.append("FAILURE:\(error.message)")
                        expectation.fulfill()
                    }
                )
                makeCallback(records: mixedRecords(), callback: callback).onSuccess("dummy-token")
                wait(for: [expectation], timeout: 10.0)
            }

            XCTAssertEqual(signatures.count, 12)
            XCTAssertEqual(Set(signatures).count, 1,
                           "merged output varied across runs - records were lost, duplicated or reordered: \(Set(signatures))")
            XCTAssertEqual(signatures.first, "cards:ins-1|cards:ins-2|persons:upd-1",
                           "inserts must precede updates; anything else means the ordering is not deterministic")
        }
    }

    // MARK: - Gap 2b: CollectRequestBuilder under genuine concurrency

    /// The builder previously held tableSet/mergedDict/callback/breakFlag in `static var`s, so two
    /// overlapping calls shared them. This is the test category that did not exist at all: every
    /// prior builder test called it sequentially, which can never expose shared state.
    ///
    /// Note this reaches the builder directly rather than via collect(), because a UIKit button tap
    /// serialises on the main thread - the shared-state bug needed off-main callers to bite. The
    /// invariant asserted is per-call isolation: each result must contain only its own column.
    func testCollectRequestBuilderKeepsCallsIsolatedUnderConcurrentUse() {
        let client = Client(Configuration(vaultID: "id", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()))
        guard let containerA = client.container(type: ContainerType.COLLECT),
              let containerB = client.container(type: ContainerType.COLLECT) else {
            return XCTFail("could not create containers")
        }

        // Elements are built on the main thread, as a real app would, before any fan-out.
        let window = UIWindow()
        let elementA = containerA.create(input: CollectElementInput(tableName: "tableA", column: "colA", type: .CVV),
                                        options: CollectElementOptions(required: false))
        let elementB = containerB.create(input: CollectElementInput(tableName: "tableB", column: "colB", type: .CVV),
                                         options: CollectElementOptions(required: false))
        window.addSubview(elementA)
        window.addSubview(elementB)
        elementA.setValue(value: "111")
        elementB.setValue(value: "222")

        let lock = NSLock()
        var contaminated: [String] = []
        var failures: [String] = []

        final class RecordingCallback: Callback {
            let onFail: (String) -> Void
            init(onFail: @escaping (String) -> Void) { self.onFail = onFail }
            func onSuccess(_ responseBody: Any) {}
            func onFailure(_ error: Any) { onFail("\(error)") }
        }

        DispatchQueue.concurrentPerform(iterations: 40) { iteration in
            let useA = iteration % 2 == 0
            let element = useA ? elementA : elementB
            let expectedColumn = useA ? "colA" : "colB"
            let foreignColumn = useA ? "colB" : "colA"

            let callback = RecordingCallback { message in
                lock.lock(); failures.append(message); lock.unlock()
            }

            guard let built = CollectRequestBuilder.createCollectRecords(
                elements: [element], additionalFields: nil, callback: callback, contextOptions: ContextOptions()
            ) else { return }

            let payload = (built["records"] as? [[String: Any]]) ?? []
            let fields = payload.first?["fields"] as? [String: Any] ?? [:]

            if fields[foreignColumn] != nil {
                lock.lock(); contaminated.append("iteration \(iteration) saw \(foreignColumn)"); lock.unlock()
            }
            if fields[expectedColumn] == nil {
                lock.lock(); contaminated.append("iteration \(iteration) lost its own \(expectedColumn)"); lock.unlock()
            }
        }

        XCTAssertTrue(contaminated.isEmpty, "calls leaked state into each other: \(contaminated)")
        // A duplicate error here would mean the shared tableSet was being reused across calls.
        let duplicateErrors = failures.filter { $0.lowercased().contains("duplicate") }
        XCTAssertTrue(duplicateErrors.isEmpty, "spurious duplicate-column errors from shared builder state: \(duplicateErrors)")
    }
}
