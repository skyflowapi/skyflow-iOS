//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 07/10/21.
//

import Foundation

internal class Log {
    internal static func log(logLevel: LogLevel, message: Message, values: [String] = [], contextOptions: ContextOptions) {
        if(contextOptions.logLevel == logLevel){
            print("\(logLevel.rawValue): \(message.getDescription(values: values))")
        }
    }
}
