//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 24/12/21.
//

import Foundation
import AEXML

class SoapRequestHelpers {
    static func matches(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            return []
        }
    }

    static func replaceElementsInXML(xml: String, skyflow: Client, contextOptions: ContextOptions, detokenizedValues: [String: String] = [:]) throws -> String {
        
        var tempXML = xml
        let matched = matches(for: "<skyflow>([\\s\\S]*?)<\\/skyflow>", in: xml)
        
        for match in matched {
            var temp = match
            temp.removeFirst(9)
            temp.removeLast(10)
            temp = temp.trimmingCharacters(in: .whitespacesAndNewlines)
            var res = ""
            if skyflow.elementLookup[temp] != nil {
                let element = skyflow.elementLookup[temp]
                if let textfield = element as? TextField {
                    if (!textfield.isValid()) {
                        //throw invalid error
                        let errorCode = ErrorCodes.INVALID_ELEMENT_INVOKE_CONNECTION(value: textfield.collectInput.label)
                        throw errorCode.getErrorObject(contextOptions: contextOptions)
                    }
                    else if (!textfield.isMounted()){
                        //throw unmounted error
                        let errorCode = ErrorCodes.UNMOUNTED_ELEMENT_INVOKE_CONNECTION(value: textfield.collectInput.label)
                        throw errorCode.getErrorObject(contextOptions: contextOptions)
                    }
                    else {
                        res = textfield.getValue()
                    }
                }
                else if let label = element as? Label {
                    if (!label.isMounted()) {
                        //throw unmounted error
                        let errorCode = ErrorCodes.UNMOUNTED_ELEMENT_INVOKE_CONNECTION(value: label.revealInput.label)
                        throw errorCode.getErrorObject(contextOptions: contextOptions)
                    }
                    else {
                        if label.options.formatRegex.isEmpty {
                            res = label.getValueForConnections()
                        } else {
                            res = (detokenizedValues[label.getID()]?
                                    .getFormattedText(with: label.options.formatRegex,
                                                      replacementString: label.options.replaceText,
                                                      contextOptions: contextOptions)) ?? ""
                        }
                    }
                }
            }
            else {
                if temp.isEmpty {
                    //throw empty id error
                    let errorCode = ErrorCodes.EMPTY_ELEMENT_ID_REQUEST_XML()
                    throw errorCode.getErrorObject(contextOptions: contextOptions)
                }
                else {
                    //throw invalid id error
                    let errorCode = ErrorCodes.INVALID_ELEMENT_ID_REQUEST_XML(value: temp)
                    throw errorCode.getErrorObject(contextOptions: contextOptions)
                }
            }
            tempXML = tempXML.replacingFirstOccurrence(of: match, with: res)
        }
        return tempXML
    }
    
    static func handleXMLResponse(responseXML: String, actualResponse: String, skyflow: Client, contextOptions: ContextOptions) throws -> String {

        var actualValues: [String: String] = [:]
        
        func checkAndUpdateElements() throws {
            for (key, val) in actualValues {
                let element = skyflow.elementLookup[key]
                if let label = element as? Label {
                    if !label.isMounted() {
                        //throw label not mounted error
                        let errorCode = ErrorCodes.UNMOUNTED_ELEMENT_INVOKE_CONNECTION(value: label.revealInput.label)
                        throw errorCode.getErrorObject(contextOptions: contextOptions)
                    }
                    else {
                        var formattedValue = val
                        if !label.options.formatRegex.isEmpty {
                            formattedValue = val.getFormattedText(with: label.options.formatRegex, replacementString: label.options.replaceText, contextOptions: contextOptions)
                        }
                        DispatchQueue.main.async {
                            label.updateVal(value: formattedValue)
                        }
                    }
                }
                else if let textfield = element as? TextField {
                    if !textfield.isMounted() {
                        //throw textfield not mounted error
                        let errorCode = ErrorCodes.UNMOUNTED_ELEMENT_INVOKE_CONNECTION(value: textfield.collectInput.label)
                        throw errorCode.getErrorObject(contextOptions: contextOptions)
                    }
                    else {
                        DispatchQueue.main.async {
                            textfield.textField.secureText = val
                            textfield.updateActualValue()
                        }
                    }
                }
            }
        }
        
        var lookup: [String: Any] = [:]
        var lookupEntry: [String: Any] = [:]
        
        func addLookupEntry(element: AEXMLElement, path: String, pathFromParent: String) {
            for child in element.children {
                if(!matches(for: "skyflow", in: child.name).isEmpty) {
                    if lookupEntry["values"] != nil {
                        var valuesDict: [String: String] = lookupEntry["values"] as! [String : String]
                        var pathFromParentArr = pathFromParent.components(separatedBy: ".")
                        pathFromParentArr.remove(at: 0)
                        var pathFromParentTemp = pathFromParentArr.joined(separator: ".")
                        pathFromParentTemp = pathFromParentTemp == "" ? element.name : pathFromParentTemp + "." + element.name
                        valuesDict[pathFromParentTemp] = child.value
                        lookupEntry["values"] = valuesDict
                    }
                    else {
                        var valuesDict: [String: String] = [:]
                        var pathFromParentArr = pathFromParent.components(separatedBy: ".")
                        pathFromParentArr.remove(at: 0)
                        var pathFromParentTemp = pathFromParentArr.joined(separator: ".")
                        pathFromParentTemp = pathFromParentTemp == "" ? element.name : pathFromParentTemp + "." + element.name
                        valuesDict[pathFromParentTemp] = child.value
                        lookupEntry["values"] = valuesDict
                    }
                }
                else if (child.children.isEmpty){
                    if lookupEntry["identifiers"] != nil {
                        var identifiersDict: [String: String] = lookupEntry["identifiers"] as! [String : String]
                        let pathFromParentTemp = pathFromParent == "" ? child.name : pathFromParent + "." + child.name
                        identifiersDict[pathFromParentTemp] = child.value
                        lookupEntry["identifiers"] = identifiersDict
                    }
                    else {
                        var identifiersDict: [String: String] = [:]
                        let pathFromParentTemp = pathFromParent == "" ? child.name : pathFromParent + "." + child.name
                        identifiersDict[pathFromParentTemp] = child.value
                        lookupEntry["identifiers"] = identifiersDict
                    }
                }
                else {
                    let pathFromParentTemp = pathFromParent == "" ? element.name : pathFromParent + "." + element.name
                    addLookupEntry(element: child, path: path, pathFromParent: pathFromParentTemp)
                }
            }
        }
        
        func constructLookup(element: AEXMLElement, path: String){
            if(!element.children.isEmpty){
                let pathTemp = path == "" ? element.name : path + "." + element.name
                for child in element.children {
                    if(!matches(for: "skyflow", in: child.name).isEmpty) {
                        addLookupEntry(element: element, path: path, pathFromParent: "")
                        if var entryArr = lookup[path] as? [Any] {
                            lookupEntry["isFound"] = false
                            entryArr.append(lookupEntry)
                            lookup[path] = entryArr
                        }
                        else {
                            lookupEntry["isFound"] = false
                            lookup[path] = [lookupEntry]
                        }
                        lookupEntry = [:]
                        return
                    }
                    else if child.children.isEmpty {
                        addLookupEntry(element: element, path: pathTemp, pathFromParent: "")
                        if var entryArr = lookup[pathTemp] as? [Any] {
                            lookupEntry["isFound"] = false
                            entryArr.append(lookupEntry)
                            lookup[pathTemp] = entryArr
                        }
                        else {
                            lookupEntry["isFound"] = false
                            lookup[pathTemp] = [lookupEntry]
                        }
                        lookupEntry = [:]
                        return
                    }

                }
                for child in element.children {
                    constructLookup(element: child, path: pathTemp)
                }
            }
        }
        
        func checkIfDictIsSubset(subDict: [String: String], dict: [String: String], withValues: Bool) -> Bool {
            for (key, _) in subDict {
                if(withValues){
                    if(subDict[key] != dict[key]) {
                        return false
                    }
                }
                else{
                    if dict[key] == nil {
                        return false
                    }
                }

            }
            return true
        }
    
        var tempDict: [String: String] = [:]
        var elementMap: [String: Any] = [:]
        
        func removeElements(dict: [String: String], valuesDict: [String: String], elementMap: [String: Any]) {
            for (key, _) in valuesDict {
                if dict[key] != nil && valuesDict[key] != nil {
                    let xml: AEXMLElement = elementMap[key] as! AEXMLElement
                    xml.removeFromParent()
                    let temp = valuesDict[key]!
                    actualValues[temp] = xml.value
                }
            }
        }
        
        func constructElementMap(element: AEXMLElement, path: String, parent: Bool) {
            for child in element.children {
                var pathTemp = ""
                if(!parent){
                   pathTemp = path == "" ? element.name : path + "." + element.name
                }
                if(!child.children.isEmpty){
                    constructElementMap(element: child, path: pathTemp, parent: false)
                }
                else{
                    elementMap[pathTemp == "" ? child.name : pathTemp + "." + child.name] = child
                }
            }
        }
        
        func constructDict(element: AEXMLElement, path: String, parent: Bool) {
            for child in element.children {
                var pathTemp = ""
                if(!parent){
                   pathTemp = path == "" ? element.name : path + "." + element.name
                }

                if(!child.children.isEmpty){
                    constructDict(element: child, path: pathTemp, parent: false)
                }
                else{
                    tempDict[pathTemp == "" ? child.name : pathTemp + "." + child.name] = child.value
                }
            }
        }
        
        func comparisonHelper(element: AEXMLElement, identifiersDict: [String: String], valuesDict: [String: String]) -> Bool {
            tempDict = [:]
            var result: Bool = false
            constructDict(element: element, path: "", parent: true)
            result = checkIfDictIsSubset(subDict: identifiersDict, dict: tempDict, withValues: true)
            constructDict(element: element, path: "", parent: true)
            result = result && checkIfDictIsSubset(subDict: valuesDict, dict: tempDict, withValues: false)
            return result
        }
        
        func newHelper(element: AEXMLElement, completePath: String) throws {
            let detailsArr: [Any] = lookup[completePath] as? [Any] ?? []
            for (index, details) in detailsArr.enumerated() {
                var detailsDict: [String: Any] = details as? [String: Any] ?? [:]
                let identifiersDict: [String: String] = detailsDict["identifiers"] as? [String : String] ?? [:]
                let valuesDict: [String: String] = detailsDict["values"] as? [String : String] ?? [:]
                if comparisonHelper(element: element, identifiersDict: identifiersDict, valuesDict: valuesDict) {
                    if detailsDict["isFound"] as! Bool {
                        //throw error
                        let errorCode = ErrorCodes.AMBIGUOUS_ELEMENT_FOUND_IN_RESPONSE_XML()
                        throw errorCode.getErrorObject(contextOptions: contextOptions)
                    }
                    else {
                        detailsDict["isFound"] = true
                        var tempArr: [Any] = lookup[completePath] as! [Any]
                        tempArr[index] = detailsDict
                        lookup[completePath] = tempArr
                        constructElementMap(element: element, path: "", parent: true)
                        constructDict(element: element, path: "", parent: true)
                        removeElements(dict: tempDict, valuesDict: valuesDict, elementMap: elementMap)
                        elementMap = [:]
                    }
                }
            }
        }
        
        func parseActualResponse(element: AEXMLElement, targetPath: String, completePath: String) throws {
            var targetPathArr = targetPath.components(separatedBy: ".")
            if !targetPathArr.isEmpty && targetPathArr[0] == element.name {
                targetPathArr.remove(at: 0)
                let targetPathTemp = targetPathArr.joined(separator: ".")
                if(targetPathTemp.isEmpty) {
                    try newHelper(element: element, completePath: completePath)
                }
                else {
                    if !element.children.isEmpty {
                        for child in element.children {
                            try parseActualResponse(element: child, targetPath: targetPathTemp, completePath: completePath)
                        }
                    }
                }
            }
        }
        
        var userInputXML: AEXMLElement
        var actualXML: AEXMLElement
        
        if responseXML.isEmpty {
            return actualResponse
        }
        
        do {
            userInputXML = try AEXMLDocument(xml: responseXML)
        }
        catch {
            //throw responseXML invalid error
            let userInfo = (error as NSError).userInfo
            var errorCode = ErrorCodes.INVALID_RESPONSE_XML(value : userInfo.description)
            if userInfo.isEmpty {
                errorCode = ErrorCodes.INVALID_RESPONSE_XML(value: (error as NSError).description)
            }
            throw errorCode.getErrorObject(contextOptions: contextOptions)
        }
        do {
            actualXML = try AEXMLDocument(xml: actualResponse)
        }
        catch {
            //throw actualResponseXML invalid error
            let userInfo = (error as NSError).userInfo
            var errorCode = ErrorCodes.INVALID_ACTUAL_RESPONSE_XML(value : userInfo.description)
            if userInfo.isEmpty {
                errorCode = ErrorCodes.INVALID_ACTUAL_RESPONSE_XML(value: (error as NSError).description)
            }
            throw errorCode.getErrorObject(contextOptions: contextOptions)
        }

        constructLookup(element: userInputXML, path: "")
        
        
        do {
            for (key, _) in lookup {
                try parseActualResponse(element: actualXML, targetPath: key, completePath: key)
            }
            for (key, val) in lookup {
                let entries = val as! [[String: Any]]
                for entry in entries {
                    let entryDict = entry as? [String: Any]
                    let isFound = entryDict?["isFound"] as? Bool
                    let identifiersDict = entryDict?["identifiers"]
                    if isFound != nil && !isFound! {
                        if identifiersDict != nil {
                            let errorCode = ErrorCodes.INVALID_IDENTIFIERS_IN_SOAP_CONNECTION(value: key.replacingFirstOccurrence(of: "AEXMLDocument.", with: ""))
                            throw errorCode.getErrorObject(contextOptions: contextOptions)
                        }
                        else {
                            let errorCode = ErrorCodes.INVALID_PATH_IN_SOAP_CONNECTION(value: key.replacingFirstOccurrence(of: "AEXMLDocument.", with: ""))
                            throw errorCode.getErrorObject(contextOptions: contextOptions)
                        }
                    }
                }
            }
            try checkAndUpdateElements()
        }
        catch {
            throw error
        }
    
        return actualXML.xml
    }
    
    static func getElementTokensWithFormatRegex(xml: String, skyflow: Client, contextOptions: ContextOptions) throws -> [String: String] {
        let matched = matches(for: "<skyflow>([\\s\\S]*?)<\\/skyflow>", in: xml)
        var res = [String: String]()

        for match in matched {
            var temp = match
            temp.removeFirst(9)
            temp.removeLast(10)
            temp = temp.trimmingCharacters(in: .whitespacesAndNewlines)
            if skyflow.elementLookup[temp] != nil {
                let element = skyflow.elementLookup[temp]
                if let label = element as? Label {
                    if !label.options.formatRegex.isEmpty {
                        res[label.getID()] = label.getToken()
                    }
                }
            }
        }
        return res
    }
    
}
