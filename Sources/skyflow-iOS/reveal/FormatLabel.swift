//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 12/08/21.
//

import Foundation
import UIKit

public class FormatLabel: UILabel {
    internal var secureText: String? {
        set {
            print("tried to set securetext")
            super.text = newValue
        }
        get {
            return super.text
        }
    }
    
    
}
