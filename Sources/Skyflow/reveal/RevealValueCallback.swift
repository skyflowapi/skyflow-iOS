//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 13/08/21.
//

import Foundation

internal class RevealValueCallback: Callback {
    var clientCallback: Callback
    var revealElements: [Label]
    var contextOptions: ContextOptions

    internal init(callback: Callback, revealElements: [Label], contextOptions: ContextOptions) {
        self.clientCallback = callback
        self.revealElements = revealElements
        self.contextOptions = contextOptions
    }

    func onSuccess(_ responseBody: Any) {
        var tokens: [String: String] = [:]


        let responseJson = responseBody as! [String: Any]
        var response: [String: Any] = [:]
        var tempSuccessResponses: [[String: String]] = []

        if let records = responseJson["records"] as? [Any] {
            for record in records {
                let dict = record as! [String: Any]
                let token = dict["token"] as! String
                let value = dict["value"] as? String
                tokens[token] = value ?? token
                
                var successEntry: [String: String] = [:]
                successEntry["token"] = token
                tempSuccessResponses.append(successEntry)
            }
        }
        
        var regexFails = [String: Any]()
        var successResponses: [[String: String]] = []
        for revealElement in self.revealElements {
            if let v = tokens[revealElement.revealInput.token]{
                if !revealElement.options.formatRegex.isEmpty {
                    do {
                        let formattedVal = try v.getFirstRegexMatch(of: revealElement.options.formatRegex, contextOptions: contextOptions)
                        tokens[revealElement.revealInput.token] = formattedVal
                    } catch {
                        regexFails[revealElement.revealInput.token] = error
                        tokens[revealElement.revealInput.token] = revealElement.revealInput.token
                    }
                }
            }
        }
        for entry in tempSuccessResponses {
            if let token = entry["token"] {
                if !regexFails.keys.contains(token) {
                    successResponses.append(entry)
                }
            }
        }

        if successResponses.count != 0 {
            response["success"] = successResponses
        }
        var errors =  [] as [[String: Any]]
        if let responseErrors = response["errors"] as? [[String: Any]] {
            errors = responseErrors
        }
        for (token, error) in regexFails {
            let entry = ["token": token, "error": (error as! NSError).localizedDescription]
            errors.append(entry)
        }
        let tokensToErrors = getTokensToErrors(errors)
        if errors.count != 0 {
            response["errors"] = errors
        }

        DispatchQueue.main.async {
            for revealElement in self.revealElements {
                if let v = tokens[revealElement.revealInput.token]{
                    revealElement.updateVal(value: v)
                }
            
                let inputToken = revealElement.revealInput.token
                revealElement.hideError()
                
                if let errorMessage = tokensToErrors[inputToken] {
                    revealElement.showError(message: errorMessage)
                } else {
                    Log.info(message: .ELEMENT_REVEALED, values: [revealElement.revealInput.label], contextOptions: self.contextOptions)
                }
            }
        }
        self.clientCallback.onSuccess(response)
    }

    func onFailure(_ error: Any) {
        if error is [String: Any] {
            var tokens: [String: String] = [:]

            let responseJson = error as! [String: Any]
            var response: [String: Any] = [:]
            var tempSuccessResponses: [[String: String]] = []

            if let records = responseJson["records"] as? [Any] {
                for record in records {
                    let dict = record as! [String: Any]
                    let token = dict["token"] as! String
                    let value = dict["value"] as? String
                    tokens[token] = value ?? token
                    
                    var successEntry: [String: String] = [:]
                    successEntry["token"] = token
                    tempSuccessResponses.append(successEntry)
                }
            }
            
            var regexFails = [String: Any]()
            var successResponses: [[String: String]] = []
            for revealElement in self.revealElements {
                if let v = tokens[revealElement.revealInput.token]{
                    if !revealElement.options.formatRegex.isEmpty {
                        do {
                            let formattedVal = try v.getFirstRegexMatch(of: revealElement.options.formatRegex, contextOptions: contextOptions)
                            tokens[revealElement.revealInput.token] = formattedVal
                        } catch {
                            regexFails[revealElement.revealInput.token] = error
                            tokens[revealElement.revealInput.token] = revealElement.revealInput.token
                        }
                    }
                }
            }
            for entry in tempSuccessResponses {
                if let token = entry["token"] {
                    if !regexFails.keys.contains(token) {
                        successResponses.append(entry)
                    }
                }
            }

            if successResponses.count != 0 {
                response["success"] = successResponses
            }
            var errors =  [[:]] as [[String: Any]]
            if let responseErrors = response["errors"] as? [[String: Any]] {
                errors = responseErrors
            }
            for (token, error) in regexFails {
                let entry = ["token": token, "error": (error as! NSError).localizedDescription]
                errors.append(entry)
            }
            let tokensToErrors = getTokensToErrors(errors)
            if errors.count != 0 {
                response["errors"] = errors
            }
            
            DispatchQueue.main.async {
                for revealElement in self.revealElements {
                    if let v = tokens[revealElement.revealInput.token]{
                        revealElement.updateVal(value: v)
                    }
                    
                    let inputToken = revealElement.revealInput.token
                    revealElement.hideError()
                    if let errorMessage = tokensToErrors[inputToken] {
                        revealElement.showError(message: errorMessage)
                    }
                }
            }
        }
        self.clientCallback.onFailure(error)
    }

    func getTokensToErrors(_ errors: [[String: Any]]?) -> [String: String] {
        var result = [String: String]()
        if let errorsObj = errors {
            for error in errorsObj {
                if let token = error["token"] as? String {
                    result[token] = "Invalid Token"
                }
            }
        }
        return result
    }
}
