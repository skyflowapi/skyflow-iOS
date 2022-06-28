/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation
import Skyflow


public class ExampleAPICallback: Skyflow.Callback {
    
    private var updateSuccess: ((SuccessResponse) -> Void)?
    private var updateFailure: (() -> Void)?
    private var decoder: JSONDecoder?
    
    internal init(updateSuccess: @escaping (SuccessResponse) -> Void, updateFailure: @escaping () -> Void) {
        self.updateSuccess = updateSuccess
        self.updateFailure = updateFailure
        self.decoder = JSONDecoder()
    }
    
    internal init() {
    }
    
    public func onSuccess(_ responseBody: Any) {
        if updateSuccess == nil {
            print("success:", responseBody)
            return
        }
        do {
            
            let dataString = String(data: try! JSONSerialization.data(withJSONObject: responseBody), encoding: .utf8)
            let responseData = Data(dataString!.utf8)
            let jsonResponse = try decoder!.decode(SuccessResponse.self, from: responseData)
            
            updateSuccess!(jsonResponse)

            print("success:", jsonResponse)
            
        }
        catch {
            print("error deserializing", error)
        }
    }
    
    public func onFailure(_ error: Any) {
        if updateFailure != nil {
            print("faiure:", error)
            return
        }
        updateFailure!()
        print("onfailure", error)
    }
    
}
