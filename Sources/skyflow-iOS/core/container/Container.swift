//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 27/07/21.
//

import Foundation

public class Container<T:ContainerProtocol> {
    internal var skyflow: Skyflow
    internal var elements: [SkyflowTextField] = []
    internal var revealElements: [SkyflowLabel] = []
    
    internal init(skyflow: Skyflow){
        self.skyflow = skyflow
    }
}

