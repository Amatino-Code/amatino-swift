//
//  Position.swift
//  Amatino
//
//  Created by Hugh Jeremy on 4/8/18.
//

import Foundation

public final class Position: EntityObject, Denominated {
    
    internal init(
        _ entity: Entity,
        _ attributes: Position.Attributes
        ) {
        self.entity = entity
        self.attributes = attributes
        return
    }
    
    internal let attributes: Position.Attributes
    
    private static let path = "/positions"
    
    public let entity: Entity
    public var session: Session { get { return entity.session} }
    
    public var balanceTime: Date { get { return attributes.balanceTime } }
    public var generatedTime: Date { get { return attributes.generatedTime } }
    public var globalUnitId: Int? { get { return attributes.globalUnitId } }
    public var customUnitId: Int? { get { return attributes.customUnitId } }
    public var liabilityAccounts: Array<Node> {
        get { return attributes.liabilityAccounts }
    }
    public var assetAccounts: Array<Node> {
        get { return attributes.assetAccounts }
    }
    public var equityAccounts: Array<Node> {
        get { return attributes.equityAccounts }
    }
    public var depth: Int { get { return attributes.depth } }
    
    private var entityId: String { get { return attributes.entityId } }
    
    public static func retrieve(
        for entity: Entity,
        at balanceTime: Date? = nil,
        denominatedIn denomination: Denomination,
        toDepth depth: Int? = nil,
        then callback: @escaping (Error?, Position?) -> Void
    ) {
        let arguments = Position.RetrievalArguments(
            denomination: denomination,
            balanceTime: balanceTime,
            depth: depth
        )
        Position.executeRetrieval(entity, arguments, callback)
        return
    }
    
    public static func retrieve(
        for entity: Entity,
        at balanceTime: Date? = nil,
        denominatedIn denomination: Denomination,
        toDepth depth: Int? = nil,
        then callback: @escaping (Result<Position, Error>) -> Void
    ) {
        Position.retrieve(
            for: entity,
            at: balanceTime,
            denominatedIn: denomination,
            toDepth: depth
        ) { (error, position) in
            guard let position = position else {
                callback(.failure(error ?? AmatinoError(.inconsistentState)))
                return
            }
            callback(.success(position))
            return
        }
    }
    
    private static func executeRetrieval(
        _ entity: Entity,
        _ arguments: Position.RetrievalArguments,
        _ callback: @escaping (Error?, Position?) -> Void
        ) {
        do {
            let _ = try AmatinoRequest(
                path: Position.path,
                data: try RequestData(data: arguments, overrideListing: true),
                session: entity.session,
                urlParameters: UrlParameters(singleEntity: entity),
                method: .GET
            ) { (error, data) in
                let _ = asyncInitSolo(
                    entity,
                    callback,
                    error,
                    data
                )
                return
            }
        } catch {
            callback(error, nil)
        }
    }
    
    internal struct Attributes: Decodable {
        let balanceTime: Date
        let generatedTime: Date
        let globalUnitId: Int?
        let customUnitId: Int?
        let liabilityAccounts: Array<Node>
        let assetAccounts: Array<Node>
        let equityAccounts: Array<Node>
        let depth: Int
        let entityId: String
        
        internal init(from decoder: Decoder) throws {
            let container = try decoder.container(
                keyedBy: JSONObjectKeys.self
            )
            entityId = try container.decode(String.self, forKey: .entityId)
            balanceTime = try AmatinoDate(
                fromString: container.decode(
                    String.self,
                    forKey: .balanceTime
                )
                ).decodedDate
            generatedTime = try AmatinoDate(
                fromString: container.decode(
                    String.self,
                    forKey: .generatedTime
                )
                ).decodedDate
            globalUnitId = try container.decode(Int?.self, forKey: .globalUnit)
            customUnitId = try container.decode(Int?.self, forKey: .customUnit)
            liabilityAccounts = try TreeNode.decodeNodes(
                container: container, key: .liabilities
            )
            assetAccounts = try TreeNode.decodeNodes(
                container: container, key: .assets
            )
            equityAccounts = try TreeNode.decodeNodes(
                container: container, key: .equities
            )
            depth = try container.decode(Int.self, forKey: .depth)
            return
        }
        
        enum JSONObjectKeys: String, CodingKey {
            case entityId = "entity_id"
            case balanceTime = "balance_time"
            case generatedTime = "generated_time"
            case globalUnit = "global_unit_denomination"
            case customUnit = "custom_unit_denomination"
            case liabilities
            case assets
            case equities
            case depth
        }
    }
    
    internal struct RetrievalArguments: Encodable {
        let balanceTime: Date?
        let globalUnitId: Int?
        let customUnitId: Int?
        let depth: Int?
        
        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JSONObjectKeys.self)
            try container.encode(balanceTime, forKey: .balanceTime)
            try container.encode(globalUnitId, forKey: .globalUnitId)
            try container.encode(customUnitId, forKey: .customUnitId)
            try container.encode(depth, forKey: .depth)
            return
        }
        
        public init(
            denomination: Denomination,
            balanceTime: Date? = nil,
            depth: Int? = nil
        ) {
            if let customUnit = denomination as? CustomUnit {
                self.customUnitId = customUnit.id
                self.globalUnitId = nil
            } else if let globalUnit = denomination as? GlobalUnit {
                self.globalUnitId = globalUnit.id
                self.customUnitId = nil
            } else {
                fatalError("Unknown Denomination type")
            }
            self.balanceTime = balanceTime
            self.depth = depth
            return
        }
        
        enum JSONObjectKeys: String, CodingKey {
            case balanceTime = "balance_time"
            case globalUnitId = "global_unit_denomination"
            case customUnitId = "custom_unit_denomination"
            case depth
        }
    }
}
