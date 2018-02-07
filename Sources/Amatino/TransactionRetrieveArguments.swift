//
//  Amatino Swift
//  TransactionRetrieveArguments.swift
//
//  author: hugh@blinkybeach.com
//

import Foundation

internal struct TransactionRetrieveArguments: Encodable {

    let id: Int
    let customUnit: CustomUnit?
    let globalUnit: GlobalUnit?
    let version: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "transaction_id"
        case customUnit = "custom_unit_denomination"
        case globalUnit = "global_unit_denomination"
        case version
    }
    
}
