//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 26/07/21.
//

import Foundation

public class SkyflowForm
{
    public init(){
        
    }
    
    public func createElement(fieldname:String) -> (view:SkyflowTextField,configuration:SkyflowConfiguration)
    {
        let config = SkyflowConfiguration(fieldName: fieldname)
        let tx = SkyflowTextField()
        //tx.configuration = config
        return (tx,config)
    }
}
