/*
 * Copyright (c) 2022 Skyflow
 */

//  Created by Bharti Sagar on 26/04/23.
//

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
    let ssn: String
    let phone_number: String
    let license_number: String
    let skyflow_id: String
}
