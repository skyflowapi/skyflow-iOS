//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 20/07/21.
//
public protocol Callback {
    func onSuccess(_ responseBody: String) -> Void
    func onFailure(_ error: Error) -> Void
}

