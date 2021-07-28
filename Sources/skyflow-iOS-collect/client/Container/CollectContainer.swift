//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 26/07/21.
//

import Foundation
import UIKit

public class CollectContainer : Container{
    internal var skyflow: Skyflow
    internal var elements: [SkyflowTextField] = []
    
    internal init(skyflow: Skyflow){
        self.skyflow = skyflow
    }
    
    public func createElement(type: SkyflowElementType, tableName: String, columnName: String) -> SkyflowTextField {
        let skyflowTextField = SkyflowTextField()
        skyflowTextField.tableName = tableName
        skyflowTextField.columnName = columnName
        elements.append(skyflowTextField)
        return skyflowTextField
    }
    
    public func printElements(){
        for element in elements {
            print(element.getOutputText()!)
            print(element.tableName!)
        }
    }
    
    public func insert(callback: APICallback){

        let records = RequestBody.createRequestBody(elements: self.elements)
        print(records)
        self.skyflow.insert(records: records, callback: callback)
    }
}
