/*
 * Copyright (c) 2022 Skyflow
*/

// Reveal container marker type and the shared element factory.
// The public create(input:options:) and the contract-specific reveal()
// operation are defined per SDK target; create() forwards here.

import Foundation

public class RevealContainer: ContainerProtocol {
}

extension Container {
    package func makeRevealElement(input: BaseRevealElementInput, options: BaseRevealElementOptions? = BaseRevealElementOptions()) -> Label where T: RevealContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .REVEAL_CONTAINER
        let revealElement = Label(input: input, options: options!)
        revealElements.append(revealElement)
        let uuid = NSUUID().uuidString
        self.skyflow.elementLookup[uuid] = revealElement
        revealElement.uuid = uuid
        Log.info(message: .CREATED_ELEMENT, values: [input.label == "" ? "reveal" : input.label], contextOptions: tempContextOptions)
        return revealElement
    }
}
