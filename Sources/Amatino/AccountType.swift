//
//  AmType.swift
//  Amatino
//
//  Created by Hugh Jeremy on 4/7/18.
//

import Foundation

public enum AccountType: Int, Codable {
    
    case income = 4
    case expense = 5
    case asset = 1
    case liability = 2
    case equity = 3
}

extension AccountType {
    
    public static func nameFor(_ accountType: AccountType) -> String {
        switch accountType {
        case .income:
            return "Income"
        case .expense:
            return "Expense"
        case .asset:
            return "Asset"
        case .equity:
            return "Equity"
        case .liability:
            return "Liability"
        }
    }
    
    static let allNames = ["Asset", "Liability", "Equity", "Income", "Expense"]
    static let allCases: [AccountType] = [
        .asset, .liability, .income, .expense, .equity
    ]
    
    public static func typeWith(name: String) -> AccountType? {
        
        let normalisedName = name.lowercased()
        switch normalisedName {
        case "income":
            return .income
        case "expense":
            return .expense
        case "asset":
            return .asset
        case "equity":
            return .equity
        case "liability":
            return .liability
        default:
            return nil
        }
    }

}
