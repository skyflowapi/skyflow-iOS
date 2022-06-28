/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation
@testable import Skyflow

class GetByIdScenario {
    private var records: [String: [[String: Any]]] = [:]
    private var callback: Callback
    private var client: ClientScenario
    
    init(client: ClientScenario, callback: Callback) {
        self.client = client
        self.callback = callback
    }
    
    func initiatializeRecords() -> GetByIdScenario {
        self.records = ["records": []]
        
        return self
    }
    
    func addIds(_ id: [String: Any]) -> GetByIdScenario {
        self.records["records"]?.append(id)
        return self
    }
    
    func execute() {
        self.client.getById(ids: self.records, callback: self.callback)
    }
}
