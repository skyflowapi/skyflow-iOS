/*
 * Copyright (c) 2022 Skyflow
 */


import Foundation

internal enum InterfaceName {
    case COLLECT_CONTAINER
    case REVEAL_CONTAINER
    case CLIENT
    case INSERT
    case DETOKENIZE
    case GETBYID
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
        }
    }
}
