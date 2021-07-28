//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 22/07/21.
//

import Foundation
#if os(iOS)
import UIKit
#endif



/// Delegates produced by `SkyflowTextField` instance.
@objc
public protocol SkyflowTextFieldDelegate {
    
    // MARK: - Handle user ineraction with SkyflowTextField
    
    /// `SkyflowTextField` did become first responder.
    @objc optional func SkyflowTextFieldDidBeginEditing(_ textField: SkyflowTextField)
    
    /// `SkyflowTextField` did resign first responder.
    @objc optional func SkyflowTextFieldDidEndEditing(_ textField: SkyflowTextField)
    
    /// `SkyflowTextField` did resign first responder on Return button pressed.
    @objc optional func SkyflowTextFieldDidEndEditingOnReturn(_ textField: SkyflowTextField)
    
    /// `SkyflowTextField` input changed.
    @objc optional func SkyflowTextFieldDidChange(_ textField: SkyflowTextField)
}
