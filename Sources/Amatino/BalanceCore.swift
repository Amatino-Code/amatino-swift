//
//  BalanceCore.swift
//  Amatino
//
//  Created by Hugh Jeremy on 18/7/18.
//

import Foundation

class BalanceError: AmatinoObjectError {}

internal class BalanceCore: Decodable {
    
    public let accountId: Int
    public let balanceTime: Date
    public let generatedTime: Date
    public let recursive: Bool
    public let globalUnitDenomination: Int?
    public let customUnitDenomination: Int?
    public let magnitude: Decimal
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try container.decode(Int.self, forKey: .accountId)
        let formatter = DateFormatter()
        formatter.dateFormat = RequestData.dateStringFormat
        let rawBalanceTime = try container.decode(
            String.self,
            forKey: .balanceTime
        )
        guard let bTime: Date = formatter.date(from: rawBalanceTime) else {
            throw BalanceError(.incomprehensibleResponse)
        }
        balanceTime = bTime
        let rawGeneratedTime = try container.decode(
            String.self,
            forKey: .generatedTime
        )
        guard let gTime: Date = formatter.date(from: rawGeneratedTime) else {
            throw BalanceError(.incomprehensibleResponse)
        }
        generatedTime = gTime
        globalUnitDenomination = try container.decode(
            Int?.self,
            forKey: .globalUnitDenomination
        )
        customUnitDenomination = try container.decode(
            Int?.self,
            forKey: .customUnitDenomination
        )
        let rawMagnitude = try container.decode(String.self, forKey: .balance)
        let negative: Bool = rawMagnitude.contains("(")
        let parseMagnitude: String
        if negative == true {
            var magnitudeToStrip = rawMagnitude
            magnitudeToStrip.removeFirst()
            magnitudeToStrip.removeLast()
            parseMagnitude = "-" + magnitudeToStrip
        } else {
            parseMagnitude = rawMagnitude
        }
        guard let decimalMagnitude = Decimal(string: parseMagnitude) else {
            throw BalanceError(.incomprehensibleResponse)
        }
        magnitude = decimalMagnitude
        recursive = try container.decode(Bool.self, forKey: .recursive)
        return
    }
    
    internal enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case balanceTime = "balance_time"
        case generatedTime = "generated_time"
        case globalUnitDenomination = "global_unit_denomination"
        case customUnitDenomination = "custom_unit_denomination"
        case recursive
        case balance
    }
    
}