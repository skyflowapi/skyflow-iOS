/*
 * Copyright (c) 2022 Skyflow
*/

// Collect container marker type and the shared element factory.
// The public create(input:options:) and the contract-specific collect()
// operation are defined per SDK target; create() forwards here.

import Foundation
import UIKit

public class CollectContainer: ContainerProtocol {}

extension Container {
    package func makeCollectElement(input: BaseCollectElementInput, options: BaseCollectElementOptions? = BaseCollectElementOptions()) -> TextField where T: CollectContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .COLLECT_CONTAINER
         let skyflowElement = TextField(input: input, options: options ?? BaseCollectElementOptions(), contextOptions: tempContextOptions, elements: elements)
        elements.append(skyflowElement)
        let uuid = NSUUID().uuidString
        self.skyflow.elementLookup[uuid] = skyflowElement
        skyflowElement.uuid = uuid
         Log.info(message: .CREATED_ELEMENT, values: [input.label == "" ? "collect" : input.label], contextOptions: tempContextOptions)
        return skyflowElement
    }
}
