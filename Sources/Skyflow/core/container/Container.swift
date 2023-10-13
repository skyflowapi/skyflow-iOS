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

public class Container<T: ContainerProtocol> {
    internal var skyflow: Client
    internal var elements: [TextField] = []
    internal var revealElements: [Label] = []
    internal var containerOptions: ContainerOptions? = nil

    internal init(skyflow: Client) {
        self.skyflow = skyflow
    }
    internal init(skyflow: Client, options: ContainerOptions? = nil){
        self.containerOptions = options
        self.skyflow = skyflow
    }
}
