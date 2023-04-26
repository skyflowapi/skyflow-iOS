/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 20/07/21.
//

public protocol TokenProvider {
    func getBearerToken(_ apiCallback: Callback)
}
