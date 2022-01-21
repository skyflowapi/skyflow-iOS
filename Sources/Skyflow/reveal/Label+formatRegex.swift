import Foundation

extension Label {
    
    internal func setClient(client: Client) {
        self.client = client
    }
    
    internal func getFormattedValue() throws -> String {
        if self.options.formatRegex.isEmpty {
            throw NSError(domain: "", code: 400, userInfo: ["Error": "No format Regex"])
        }
        
        if self.client == nil {
            throw NSError(domain: "", code: 400, userInfo: ["Error": "No Client"])
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        let group = DispatchGroup()
        let callback = DetokenizeCallback(lock: semaphore, group: group)
        
        DispatchQueue.global().sync {
            self.client?.detokenize(records: ["records": [["token": self.getToken()]]], callback: callback)
            group.leave()
        }
        if callback.error != nil {
            print("err:", callback.error)
            throw callback.error!
        }
        print("===", callback.result)
        return callback.result.getFirstRegexMatch(of: self.options.formatRegex)
    }
    
}

fileprivate class DetokenizeCallback: Callback {
    
    private var lock: DispatchSemaphore;
    private var group: DispatchGroup;
    public var error: NSError? = nil;
    public var result: String = "";

    init(lock: DispatchSemaphore, group: DispatchGroup) {
        self.lock = lock
        self.group = group
    }
    
    
    func onSuccess(_ responseBody: Any) {
        print("====success")
        if responseBody is String {
            result = responseBody as! String
        } else {
            self.error = NSError(domain: "", code: 400, userInfo: ["Error" :"TODO: Error for invalid response type"])
        }
        group.leave()
        lock.signal()
    }
    
    func onFailure(_ error: Any) {
        print("===failed")
        self.error = error as? NSError
        group.leave()
        lock.signal()
    }
}
