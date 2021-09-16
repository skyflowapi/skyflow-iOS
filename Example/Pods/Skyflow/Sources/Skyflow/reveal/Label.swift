//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 12/08/21.
//

import Foundation
import UIKit

public class Label: UIView {
    
    internal var skyflowLabelView: SkyflowLabelView!
    internal var revealInput: RevealElementInput!
    internal var options: RevealElementOptions!
    internal var stackView = UIStackView()
    internal var labelField = UILabel(frame: .zero)
  
    internal var horizontalConstraints = [NSLayoutConstraint]()
    
    internal var verticalConstraint = [NSLayoutConstraint]()
    
    internal init(input: RevealElementInput, options: RevealElementOptions){
        self.skyflowLabelView = SkyflowLabelView(input: input, options: options)
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
        self.skyflowLabelView.updateVal(value: value)
    }
    
    internal func buildLabel(){
        self.translatesAutoresizingMaskIntoConstraints = false
        
        labelField.text = revealInput.label

        stackView.axis = .vertical
//        stackView.distribution = .equalSpacing
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        
        stackView.addArrangedSubview(labelField)
        stackView.addArrangedSubview(skyflowLabelView)
        
        addSubview(stackView);
        
        setMainPaddings();
    }
    
    func setMainPaddings() {
                
        let views = ["view": self, "stackView": stackView]
        
        horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(0)-[stackView]-\(0)-|",
                                                               options: .alignAllCenterY,
                                                               metrics: nil,
                                                               views: views)
        NSLayoutConstraint.activate(horizontalConstraints)
        
    }
}
