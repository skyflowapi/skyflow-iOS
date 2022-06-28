/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation
import Skyflow


public class ExampleAPICallback: Skyflow.Callback {
    
    public func onSuccess(_ responseBody: Any) {
        print("Invoke gateway success ", responseBody)
    }
    
    public func onFailure(_ error: Any) {
        print("Invoke gateway failure ", error)
    }
}

