/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 29/11/21.
//

import Foundation

internal enum InterfaceName {
    case COLLECT_CONTAINER
    case REVEAL_CONTAINER
    case COMPOSABLE_CONTAINER
    case CLIENT
    case INSERT
    case DETOKENIZE
    case GETBYID
    case GET
    case EMPTY
    
    var description: String {
        switch self {
        case .COLLECT_CONTAINER: return "collect container"
        case .REVEAL_CONTAINER: return "reveal container"
        case .CLIENT: return "client"
        case .INSERT: return "client insert"
        case .DETOKENIZE: return "client detokenize"
        case .GETBYID: return "client getById"
        case .EMPTY: return ""
        case .GET: return "client get"
        case .COMPOSABLE_CONTAINER: return "composable container"
        }
    }
}
