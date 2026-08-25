/*
 * Copyright (c) 2022 Skyflow
*/

// Shared storage for the container options (composable layout/styles). Each
// SDK product defines its own public `BaseContainerOptions` struct exposing that
// contract's initializers (identical in both contracts today).

import Foundation

package struct BaseContainerOptions {
    package var layout: [Int]
    package var styles: Styles?
    package var errorTextStyles: Styles?

    package init(){
        layout = [0]
    }

    package init(layout: [Int], styles: Styles? = Styles(), errorTextStyles: Styles? = Styles()) {
        self.layout = layout
        self.styles = styles
        self.errorTextStyles = errorTextStyles
    }

}
