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

public struct ContainerOptions {
    var layout: [Int]
    var styles: Styles?
    var errorTextStyles: Styles?

    public init(){
        layout = [0]
    }

    public init(layout: [Int], styles: Styles? = Styles(), errorTextStyles: Styles? = Styles()) {
        self.layout = layout
        self.styles = styles
        self.errorTextStyles = errorTextStyles
    }

}
