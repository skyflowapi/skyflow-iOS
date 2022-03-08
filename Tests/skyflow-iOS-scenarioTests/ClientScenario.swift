import Foundation
@testable import Skyflow

enum MethodsUnderTest {
    case PUREINSERT
    case PUREREVEAL
    case GETBYID
    case COLLECT
    case REVEAL
    case INVOKECONNECTION
}



class ClientScenario {
    private var config: Configuration
    
    init(tokenProvider: TokenProvider) {
        self.config = Configuration(tokenProvider: tokenProvider)
    }
    
    func setVaultUrl(vaultURL: String) -> ClientScenario{
        self.config.vaultURL = vaultURL
        
        return self
    }
    
    func setVaultID(vaultId: String) -> ClientScenario{
        self.config.vaultID = vaultId
        return self
    }
    
    func insert(records: [String: Any], callback: Callback) {
        let client = Client(config)
        client.insert(records: records, callback: callback)
    }
    
    func detokenize(tokens: [String], callback: Callback) {
        let client = Client(self.config)
        client.detokenize(records: detokenizeRequestBody(tokens), callback: callback)
    }
    
    private func detokenizeRequestBody(_ tokens: [String]) -> [String: [[String: String]]]{
        var records = [] as [[String: String]]
        
        for token in tokens {
            let newRecord = ["token": token]
            records.append(newRecord)
        }
        
        return ["records": records]
    }
}

