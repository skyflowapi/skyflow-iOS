//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 13/08/21.
//

import Foundation

internal class RevealValueCallback : SkyflowCallback {
    var clientCallback: SkyflowCallback
    var revealElements: [SkyflowLabel]
    
    internal init(callback: SkyflowCallback, revealElements: [SkyflowLabel]){
        self.clientCallback = callback
        self.revealElements = revealElements
    }
    
    func onSuccess(_ responseBody: String) {
        var tokens: [String: String] = [:]
        
        let responseData = Data(responseBody.utf8)
        let responseJson = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String:Any]
        
        let records = responseJson["records"] as! [Any]
        
        for record in records {
            let dict = record as! [String: Any]
            let fields = dict["fields"] as! [String: Any]
            let token = dict["id"] as! String
            for (_, value) in fields {
                tokens[token] = value as? String ?? token
            }
            
        }
        
        DispatchQueue.main.async {
            for revealElement in self.revealElements {
                revealElement.updateVal(value: tokens[revealElement.revealInput.id] ?? revealElement.revealInput.id)
            }
        }
        
        clientCallback.onSuccess(responseBody)
    }
    
    func onFailure(_ error: Error) {
        print(error)
        clientCallback.onFailure(error)
    }
    
    
}
