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
    package var skyflow: ClientBase
    package var elements: [TextField] = []
    package var revealElements: [Label] = []
    package var containerOptions: BaseContainerOptions? = nil

    package init(skyflow: ClientBase) {
        self.skyflow = skyflow
    }
    package init(skyflow: ClientBase, options: BaseContainerOptions? = nil){
        self.containerOptions = options
        self.skyflow = skyflow
    }
}
