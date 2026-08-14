/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes Options parameter for SkyflowInputField.
// Contract-identical in both SDKs today; declared per SDK so either product
// can add or remove options independently in the future.

import Foundation
#if os(iOS)
import UIKit
#endif

public struct CollectElementOptions {
    package var data: BaseCollectElementOptions

    public init(required: Bool? = false, enableCardIcon: Bool = true, format: String = "mm/yy", translation: [ Character: String ]? = nil, enableCopy: Bool = false, cardMetaData: [ String: Any]? = nil) {
        self.data = BaseCollectElementOptions(required: required!, enableCardIcon: enableCardIcon, format: format, translation: translation, enableCopy: enableCopy, cardMetaData: cardMetaData)
    }
}

public extension TextField {
    func update(updateOptions: CollectElementOptions) {
        self.update(optionsData: updateOptions.data)
    }
}
