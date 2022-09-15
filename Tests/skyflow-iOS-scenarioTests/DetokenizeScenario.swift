/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation
@testable import Skyflow

class DetokenizeScenario {
    private var tokens: [String] = []
    private var callback: Callback
    private var client: ClientScenario
    
    init(client: ClientScenario, callback: Callback) {
        self.client = client
        self.callback = callback
    }
    
    func addToken(_ token: String) -> DetokenizeScenario {
        self.tokens.append(token)
        return self
    }
    
    func setTokens(_ tokens: [String]) -> DetokenizeScenario {
        self.tokens = tokens
        return self
    }
    
    func execute() {
        self.client.detokenize(tokens: self.tokens, callback: self.callback)
    }
}
