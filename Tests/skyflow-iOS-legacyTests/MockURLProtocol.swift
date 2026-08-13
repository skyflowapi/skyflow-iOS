/*
 * Copyright (c) 2022 Skyflow
*/

// Minimal URLProtocol-based network mock. Register via URLProtocol.registerClass(MockURLProtocol.self)
// before the request fires (URLSession(configuration: .default) consults globally registered
// protocol classes), and unregister afterward. Used for tests that need to exercise real
// URLSession.dataTask call sites (e.g. FlowVaultCollectAPICallback's insert+update merge), where
// bypassing the network layer entirely (as most other tests do via processResponse(data:response:error:))
// wouldn't exercise the merge logic itself.

import Foundation

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "No requestHandler configured"]))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
