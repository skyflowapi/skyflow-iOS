//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 11/08/21.
//

import Foundation

public struct RevealElementInput {
    internal var table: String?
    internal var column: String?
    internal var id: String
    internal var styles: SkyflowStyles?
    internal var label: String
    internal var type: String
    
    internal init(table: String?, column: String?, id: String, styles: SkyflowStyles?, label: String, type: String) {
        self.table = table
        self.column = column
        self.id = id
        self.styles = styles
        self.label = label
        self.type = type
    }
}
