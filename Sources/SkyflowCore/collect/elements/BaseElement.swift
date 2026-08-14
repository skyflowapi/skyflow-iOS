/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 07/12/21.
//

import Foundation

public protocol BaseElement {
    func setError(_ error: String)
    func resetError()
    func getID() -> String
}
