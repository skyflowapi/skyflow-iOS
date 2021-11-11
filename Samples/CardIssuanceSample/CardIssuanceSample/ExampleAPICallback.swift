import Foundation
import Skyflow


public class ExampleAPICallback: Skyflow.Callback {
    
    public func onSuccess(_ responseBody: Any) {
        print("Invoke connection success ", responseBody)
    }
    
    public func onFailure(_ error: Any) {
        print("Invoke connection failure ", error)
    }
}

