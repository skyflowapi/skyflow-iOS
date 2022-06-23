/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 20/07/21.
//
public protocol Callback {
    func onSuccess(_ responseBody: Any)
    func onFailure(_ error: Any)
}
