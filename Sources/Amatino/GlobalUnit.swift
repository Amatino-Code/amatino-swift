//
//  Amatino Swift
//  GlobalUnit.swift
//
//  author: hugh@amatino.io
//


import Foundation

public class GlobalUnitError: AmatinoError {}

public class GlobalUnit: AmatinoObject, Denomination {
    
    internal static let urlKey = "global_unit_id"
    internal static let path = "/units"
    
    public let code: String
    public let id: Int
    public let name: String
    public let priority: Int
    public let description: String
    public let exponent: Int
    
    public static func retrieve(
        withId unitId: Int,
        authenticatedBy session: Session,
        then callback: @escaping (_: Error?, _: GlobalUnit?) -> Void
    ) -> Void {
        
        let target = UrlTarget(integerValue: unitId, key: urlKey)
        let urlParameters = UrlParameters(targetsOnly: [target])
        
        do {
            let _ = try AmatinoRequest(
                path: path,
                data: nil,
                session: session,
                urlParameters: urlParameters,
                method: .GET,
                callback: {(error: Error?, data: Data?) in
                    let _ = loadResponse(error, data, callback)
            })
        } catch {
            callback(error, nil)
            return
        }
    }
    
    public static func retrieve(
        withId unitId: Int,
        authenticatedBy session: Session,
        then callback: @escaping (Result<GlobalUnit, Error>) -> Void
    ) {
        GlobalUnit.retrieve(
            withId: unitId,
            authenticatedBy: session
        ) { (error, unit) in
            guard let unit = unit else {
                callback(.failure(error ?? AmatinoError(.inconsistentState)))
                return
            }
            callback(.success(unit))
            return
        }
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        name = try container.decode(String.self, forKey: .name)
        priority = try container.decode(Int.self, forKey: .priority)
        description = try container.decode(String.self, forKey: .description)
        exponent = try container.decode(Int.self, forKey: .exponent)
        return
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "global_unit_id"
        case code
        case name
        case priority
        case description
        case exponent
    }
}

