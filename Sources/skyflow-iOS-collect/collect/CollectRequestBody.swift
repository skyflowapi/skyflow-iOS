//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 27/07/21.
//

import Foundation

internal class CollectRequestBody {
    internal static func createRequestBody(elements: [SkyflowTextField]) -> [String: Any]{
        var tableMap: [String: Int] = [:]
        var payload: [[String: Any]] = []
        var index: Int = 0
        for element in elements {
            if tableMap[(element.tableName)!] != nil{
                var temp = payload[tableMap[(element.tableName)!]!]
                temp[keyPath: "fields." + (element.columnName)!] = element.getOutput()
                payload[tableMap[(element.tableName)!]!] = temp
            }
            else{
                tableMap[(element.tableName)!] = index
                index += 1
                var temp:[String:Any] = [
                    "tableName": element.tableName!,
                    "fields": [:]
                ]
                temp[keyPath: "fields." + element.columnName!] = element.getOutput()
                payload.append(temp)
            }
        }
        
        return ["records": payload]
    }
}

