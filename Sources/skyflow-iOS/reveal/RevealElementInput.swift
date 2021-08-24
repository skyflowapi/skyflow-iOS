//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 11/08/21.
//

import Foundation

public struct RevealElementInput {
    internal var id: String
    internal var styles: SkyflowStyles?
    internal var label: String
    internal var redaction: String
    
    public init(id: String, styles: SkyflowStyles?, label: String, redaction: RedactionTypes) {
        self.id = id
        self.styles = styles
        self.label = label
        self.redaction = redaction.rawValue
    }
}
