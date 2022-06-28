/*
 * Copyright (c) 2022 Skyflow
*/

//
//  ExampleTokenProvider.swift
//  Validations
//
//  Created by Akhil Anil Mangala on 24/11/21.
//

import Foundation
import Skyflow

public class ExampleTokenProvider : TokenProvider {
    
    
    public func getBearerToken(_ apiCallback: Skyflow.Callback) {
        if let url = URL(string: "<YOUR_TOKEN_PROVIDER_ENDPOINT>") {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url){ data, response, error in
                if(error != nil){
                    print(error!)
                    return
                }
                if let safeData = data {
                    do{
                        let x = try JSONSerialization.jsonObject(with: safeData, options:[]) as? [String: String]
                        if let accessToken = x?["accessToken"]{
                            apiCallback.onSuccess(accessToken)
                        }
                    }
                    catch{
                        print("access token wrong format")
                    }
                }
            }
            task.resume()
        }
    }
}

