/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation


struct SuccessResponse: Codable {
    let records: [Records]
}


struct Records: Codable {
    let fields: Fields
    let table: String
}

struct Fields: Codable {
    let cardnumber: String
    let cvv: String
    let skyflow_id: String
}

import Foundation
