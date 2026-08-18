/*
 * Copyright (c) 2022 Skyflow
*/

// Options for composable containers (layout/styles). Contract-identical in
// both SDKs today; declared per SDK so either product can evolve
// independently.

import Foundation

public struct ContainerOptions {
    package var data: BaseContainerOptions

    public init(){
        self.data = BaseContainerOptions()
    }

    public init(layout: [Int], styles: Styles? = Styles(), errorTextStyles: Styles? = Styles()) {
        self.data = BaseContainerOptions(layout: layout, styles: styles, errorTextStyles: errorTextStyles)
    }

}
