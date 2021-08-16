//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 12/08/21.
//

import Foundation
import UIKit

public class SkyflowLabel: UIView {
    
    internal var label = FormatLabel(frame: .zero)
    internal var revealInput: RevealElementInput!
    internal var options: RevealElementOptions!
    
    internal init(input: RevealElementInput, options: RevealElementOptions){
        super.init(frame: CGRect())
        self.revealInput = input
        self.options = options
        buildLabel()
    }
    
    override internal init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    internal func updateVal(value: String){
        self.label.secureText = value
    }
    
    internal func buildLabel(){
        self.label.secureText = self.revealInput.id
        self.label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(self.label)
    }
}
