
import Foundation
@testable import Skyflow

class InsertScenario {
    private var records: [String: [[String: Any]]] = [:]
    private var callback: Callback
    private var client: ClientScenario
    init(client: ClientScenario, callback: Callback) {
        self.client = client
        self.callback = callback
    }
    
    func initiateRecords() -> InsertScenario{
        self.records = ["records": []]
        return self
    }
    
    func addRecord(record: [String: Any]) -> InsertScenario {
        self.records["records"]?.append(record)
        
        return self
    }
    
    func execute() {
        client.insert(records: self.records, callback: self.callback)
    }
}
