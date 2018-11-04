//
//  RecursiveBalance.swift
//  Amatino
//
//  Created by Hugh Jeremy on 18/7/18.
//

import Foundation

class RecursiveBalance: AccountBalance {
    
    internal static let path = "/accounts/balance/recursive"
    
    public static func retrieve(
        entity: Entity,
        account: Account,
        callback: @escaping (Error?, RecursiveBalance?) -> Void
        ) throws {
        
        let arguments = Balance.RetrieveArguments(account: account)
        let _ = try RecursiveBalance.retrieve(
            entity: entity,
            arguments: arguments,
            callback: callback
        )
        return
    }
    
    public static func retrieve(
        entity: Entity,
        account: Account,
        balanceTime: Date,
        callback: @escaping (Error?, RecursiveBalance?) -> Void
        ) throws {
        
        let arguments = Balance.RetrieveArguments(
            account: account,
            balanceTime: balanceTime
        )
        let _ = try RecursiveBalance.retrieve(
            entity: entity,
            arguments: arguments,
            callback: callback
        )
        return
    }
    
    public static func retrieve(
        entity: Entity,
        arguments: Balance.RetrieveArguments,
        callback: @escaping (Error?, RecursiveBalance?) -> Void
        ) throws {
        
        let urlParameters = UrlParameters(singleEntity: entity)
        let requestData = try RequestData(data: arguments)
        let _ = try AmatinoRequest(
            path: path,
            data: requestData,
            session: entity.session,
            urlParameters: urlParameters,
            method: .GET,
            callback: { (error, data) in
                let _ = loadResponse(error, data, callback)
                return
        })
        return
    }
    
    private static func loadResponse(
        _ responseError: Error?,
        _ data: Data?,
        _ callback: (Error?, RecursiveBalance?) -> Void
        ) {
        guard responseError == nil else {callback(responseError, nil); return}
        let decoder = JSONDecoder()
        let balance: RecursiveBalance
        do {
            balance = try decoder.decode(
                [RecursiveBalance].self,
                from: data!
                )[0]
            callback(nil, balance)
            return
        } catch {
            callback(error, nil)
        }
    }
    
}
