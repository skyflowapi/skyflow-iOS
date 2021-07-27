//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 20/07/21.
//

public protocol TokenProvider {
    func getAccessToken(_ apiCallback: APICallback)
}
