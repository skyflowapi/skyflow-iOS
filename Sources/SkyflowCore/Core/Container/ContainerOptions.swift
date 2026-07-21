/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

public struct ContainerOptions {
    public var layout: [Int]
    public var styles: Styles?
    public var errorTextStyles: Styles?

    public init(){
        layout = [0]
    }

    public init(layout: [Int], styles: Styles? = Styles(), errorTextStyles: Styles? = Styles()) {
        self.layout = layout
        self.styles = styles
        self.errorTextStyles = errorTextStyles
    }

}
