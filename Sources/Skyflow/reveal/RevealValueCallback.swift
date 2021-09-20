//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 13/08/21.
//

import Foundation
/* For reference
struct ErrorStruct {
    var errors: [String: String]
    var token: String
}

struct SkyflowError {
    var code: Int
    var description: String
}
*/

internal class RevealValueCallback : Callback {
    var clientCallback: Callback
    var revealElements: [Label]
    
    internal init(callback: Callback, revealElements: [Label]){
        self.clientCallback = callback
        self.revealElements = revealElements
    }
    
    func onSuccess(_ responseBody: Any) {
        var tokens: [String: String] = [:]
        
        let responseJson = responseBody as! [String: Any]
        let records = responseJson["records"] as! [Any]
        var response: [String: Any] = [:]
        var successResponses: [Any] = []
        
        for record in records {
            let dict = record as! [String: Any]
            let fields = dict["fields"] as! [String: Any]
            let token = dict["token"] as! String
            for (_, value) in fields {
                tokens[token] = value as? String ?? token
            }
            var successEntry: [String: String] = [:]
            successEntry["token"] = token
            successResponses.append(successEntry)
        }
        
        response["success"] = successResponses
        let errors = responseJson["errors"] as! [[String: Any]]
        let tokensToErrors = getTokensToErrors(errors)

        response["errors"] = errors
        DispatchQueue.main.async {

            for revealElement in self.revealElements {
                let inputToken = revealElement.revealInput.token
                revealElement.hideError()
                revealElement.updateVal(value: tokens[inputToken] ?? inputToken)
                if let errorMessage = tokensToErrors[inputToken] {
                    revealElement.showError(message: errorMessage)
                }
            }
            
            let dataString = String(data: try! JSONSerialization.data(withJSONObject: response), encoding: .utf8)

            self.clientCallback.onSuccess(dataString!)
        }

    }
    
    func onFailure(_ error: Error) {
        print(error)
        clientCallback.onFailure(error)
    }
    
    
    func getTokensToErrors(_ errors: [[String: Any]]) -> [String: String]{
        var result = [String: String]()
        for error in errors {
            print("error is:", error)
            let token = error["token"] as! String
            
            result[token] = "Invalid Token"
        }
        
        return result
    }
    
    
}
