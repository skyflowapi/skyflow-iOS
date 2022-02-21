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
}

