//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 07/10/21.
//

import Foundation

internal struct ContextOptions {
    var logLevel: LogLevel = .DEBUG
    
    internal init(logLevel: LogLevel){
        self.logLevel = logLevel
    }
}
