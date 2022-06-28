/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation


/// For decoding response JSON

struct SuccessResponse: Codable {
    let records: [Records]
}

struct Records: Codable {
    let fields: Fields
    let table: String
}

struct Fields: Codable {
    let name: NameField
    let cvv: String
    let cardExpiration: String
    let cardNumber: String
    let skyflow_id: String
}

struct NameField: Codable {
    let skyflow_id: String
    let first_name: String
}
