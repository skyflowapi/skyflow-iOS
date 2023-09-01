/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 18/11/21.
//

import Foundation

/// Defines a validation rule for input validation.
public protocol ValidationRule {
    var error: String { get }
}
