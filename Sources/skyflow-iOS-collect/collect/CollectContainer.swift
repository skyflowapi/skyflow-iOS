//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 26/07/21.
//

import Foundation
import UIKit

public class CollectContainer:ContainerProtocol {}

public extension Container {
    
    func create(type: SkyflowElementType, table: String, column: String) -> SkyflowTextField where T:CollectContainer {
        let skyflowTextField = SkyflowTextField()
        skyflowTextField.tableName = table
        skyflowTextField.columnName = column
        elements.append(skyflowTextField)
        return skyflowTextField
    }
    
    func insert(callback: SkyflowCallback, options: InsertOptions? = InsertOptions()) where T:CollectContainer {
        let records = CollectRequestBody.createRequestBody(elements: self.elements)
        print(records)
        self.skyflow.insert(records: records, options: options, callback: callback)
    }
    
}
