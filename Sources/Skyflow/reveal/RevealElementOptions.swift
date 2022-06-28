/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 10/08/21.
//

import Foundation

public struct RevealElementOptions {
    var formatRegex: String
    var replaceText: String?
    public init(formatRegex: String = "", replaceText: String? = nil) {
        self.formatRegex = formatRegex
        self.replaceText = replaceText
    }
}
