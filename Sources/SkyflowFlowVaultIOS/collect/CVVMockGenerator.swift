/*
 * Copyright (c) 2022 Skyflow
*/

// Generates a mock CVV placeholder used to mask the real CVV token in collect responses (FlowDB v2).

import Foundation

internal enum CVVMockGenerator {
    internal static func generateMockCVV(length: Int, actualValue: String) -> String {
        guard length > 0 else { return "" }
        var mock: String
        repeat {
            mock = randomNumericString(length: length)
        } while mock == actualValue
        return mock
    }

    private static func randomNumericString(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        if status != errSecSuccess {
            var generator = SystemRandomNumberGenerator()
            for i in 0..<length {
                bytes[i] = UInt8.random(in: 0...255, using: &generator)
            }
        }
        return bytes.map { String($0 % 10) }.joined()
    }
}
