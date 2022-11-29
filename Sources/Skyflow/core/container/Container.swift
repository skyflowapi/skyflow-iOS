/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

public class Container<T: ContainerProtocol> {
    internal var skyflow: Client
    internal var elements: [TextField] = []
    internal var revealElements: [Label] = []

    internal init(skyflow: Client) {
        self.skyflow = skyflow
    }
}
