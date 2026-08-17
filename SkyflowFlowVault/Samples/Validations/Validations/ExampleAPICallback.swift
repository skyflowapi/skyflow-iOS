/*
 * Copyright (c) 2022 Skyflow
 */

//
//  ExampleAPICallback.swift
//  Validations
//
//  Created by Akhil Anil Mangala on 24/11/21.
//

import Foundation
import SkyflowFlowVault

public class ExampleAPICallback: SkyflowFlowVault.Callback {
    internal init() {
    }

    public func onSuccess(_ responseBody: Any) {
        print("success:", responseBody)
    }

    public func onFailure(_ error: Any) {
        print("failure:", error)
    }
}
