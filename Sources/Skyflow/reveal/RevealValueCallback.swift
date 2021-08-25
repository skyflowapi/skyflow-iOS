//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 13/08/21.
//

import Foundation

internal class RevealValueCallback : Callback {
    var clientCallback: Callback
    var revealElements: [Label]
    
    internal init(callback: Callback, revealElements: [Label]){
        self.clientCallback = callback
        self.revealElements = revealElements
    }
    
    func onSuccess(_ responseBody: String) {
        var tokens: [String: String] = [:]
        
        let responseData = Data(responseBody.utf8)
        let responseJson = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String:Any]
        
        let records = responseJson["records"] as! [Any]
        var response: [String: Any] = [:]
        var successResponses: [Any] = []
        
        for record in records {
            let dict = record as! [String: Any]
            let fields = dict["fields"] as! [String: Any]
            let token = dict["id"] as! String
            for (_, value) in fields {
                tokens[token] = value as? String ?? token
            }
            var successEntry: [String: String] = [:]
            successEntry["id"] = token
            successResponses.append(successEntry)
        }
        
        DispatchQueue.main.async {
            for revealElement in self.revealElements {
                revealElement.updateVal(value: tokens[revealElement.revealInput.id] ?? revealElement.revealInput.id)
            }
        }
        
        response["success"] = successResponses
        response["errors"] = responseJson["errors"] as! [Any]
        
        let dataString = String(data: try! JSONSerialization.data(withJSONObject: response), encoding: .utf8)
        
        clientCallback.onSuccess(dataString!)
    }
    
    func onFailure(_ error: Error) {
        print(error)
        clientCallback.onFailure(error)
    }
    
    
}