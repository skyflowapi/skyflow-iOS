/*
 * Copyright (c) 2026 Skyflow
*/

import Foundation
import SkyflowCore

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
