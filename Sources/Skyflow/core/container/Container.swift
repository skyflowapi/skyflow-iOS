/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 27/07/21.
//

import Foundation

/// This is the description for Container Class
public class Container<T: ContainerProtocol> {
    internal var skyflow: Client
    internal var elements: [TextField] = []
    internal var revealElements: [Label] = []

    internal init(skyflow: Client) {
        self.skyflow = skyflow
    }
}
