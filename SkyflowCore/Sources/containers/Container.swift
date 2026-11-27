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
    package var skyflow: Client
    package var elements: [TextField] = []
    package var revealElements: [Label] = []
    // FileInputElement lives in the Skyflow target only (FlowDB has no file API), so core
    // cannot name its type; the Skyflow target stores and casts its own instances here.
    package var fileElements: [AnyObject] = []
    package var containerOptions: BaseContainerOptions? = nil

    package init(skyflow: Client) {
        self.skyflow = skyflow
    }
    package init(skyflow: Client, options: BaseContainerOptions? = nil){
        self.containerOptions = options
        self.skyflow = skyflow
    }
}
