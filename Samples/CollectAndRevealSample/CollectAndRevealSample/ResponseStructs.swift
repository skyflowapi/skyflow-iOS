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
    let cardholder_name: String
    let card_number: String
    let expiry_month: String
    let expiry_year: String
    let cvv: String
    let skyflow_id: String
}

