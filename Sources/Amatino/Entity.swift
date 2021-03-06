//
//  Amatino Swift
//  Entity.swift
//
//  author: hugh@amatino.io
//
import Foundation

public class Entity: Equatable {
    
    internal init(
        _ session: Session,
        _ attributes: Entity.Attributes
    ) {
        self.session = session
        self.attributes = attributes
        return
    }

    private static let path = "/entities"
    private static let listPath = "/entities/list"
    
    public static let maxNameLength = 1024
    public static let maxDescriptionLength = 4096
    public static let minNameSearchLength = 3;
    public static let maxNameSearchLength = 64;
    
    public let session: Session

    private let attributes: Entity.Attributes
    
    public var id: String { get { return attributes.id} }
    public var ownerId: Int { get { return attributes.ownerId } }
    public var name: String { get { return attributes.name } }
    internal var permissionsGraph: [String:[String:[String:Bool]]]? {
        get { return attributes.permissionsGraph }
    }
    public var description: String? { get { return attributes.description } }
    public var regionId: Int { get { return attributes.regionId } }
    public var active: Bool { get { return attributes.active} }
    public var disposition: Disposition { get {
        return attributes.disposition
    } }
    
    public static func create(
        authenticatedBy session: Session,
        withName name: String,
        inRegion region: Region? = nil,
        then callback: @escaping (_: Error?, _: Entity?) -> Void
    ) {
        do {
            let arguments = try Entity.CreateArguments(name: name)
            Entity.create(session, arguments, callback)
        } catch {
            callback(error, nil)
            return
        }
        return
    }
    
    public static func create(
        authenticatedBy session: Session,
        withName name: String,
        inRegion region: Region? = nil,
        then callback: @escaping (Result<Entity, Error>) -> Void
    ) {
        Entity.create(
            authenticatedBy: session,
            withName: name,
            inRegion: region
        ) { (error, entity) in
            guard let entity = entity else {
                callback(.failure(error ?? AmatinoError(.inconsistentState)))
                return
            }
            callback(.success(entity))
        }
    }
    
    private static func create(
        _ session: Session,
        _ arguments: Entity.CreateArguments,
        _ callback: @escaping (_: Error?, _: Entity?) -> Void
        ) {
        do {
            let requestData = try RequestData(data: arguments)
            let _ = try AmatinoRequest(
                path: path,
                data: requestData,
                session: session,
                urlParameters: nil,
                method: .POST,
                callback: {(error, data) in
                    let _ = Entity.asyncInit(
                        session: session,
                        error: error,
                        data: data,
                        callback: callback
                    )
            })
        } catch {
            callback(error, nil)
            return
        }
        return
    }
    
    public static func retrieve(
        authenticatedBy session: Session,
        withId entityId: String,
        then callback: @escaping (_: Error?, _: Entity?) -> Void
    ) {
        let target = UrlTarget(forEntityId: entityId)
        do {
            let _ = try AmatinoRequest(
                path: Entity.path,
                data: nil,
                session: session,
                urlParameters: UrlParameters(targetsOnly: [target]),
                method: .GET,
                callback: { (error, data) in
                    let _ = Entity.asyncInit(
                        session: session,
                        error: error,
                        data: data,
                        callback: callback
                    )
            })
        } catch {
            callback(error, nil)
            return
        }
    }
    
    public static func retrieve(
        authenticatedBy session: Session,
        withId entityId: String,
        then callback: @escaping (Result<Entity, Error>) -> Void
    ) {
        Entity.retrieve(
            authenticatedBy: session,
            withId: entityId) { (error, entity) in
                guard let entity = entity else {
                    callback(
                        .failure(error ?? AmatinoError(.inconsistentState))
                    )
                    return
                }
                callback(.success(entity))
                return
        }
    }
    
    public static func retrieveList(
        authenticatedBy session: Session,
        offset: Int = 0,
        limit: Int = 10,
        withName name: Optional<String> = nil,
        inState state: State = State.all,
        then callback: @escaping (_: Error?, _: Array<Entity>?) -> Void
    ) {
        
        var targets = [
            UrlTarget(integerValue: offset, key: "offset"),
            UrlTarget(integerValue: limit, key: "limit"),
            UrlTarget(stringValue: state.rawValue, key: "state")
        ]
        
        if let name = name {
            if name.count < Self.minNameSearchLength {
                callback(AmatinoError(.constraintViolated), nil);
                return;
            }
            if name.count > Self.maxNameSearchLength {
                callback(AmatinoError(.constraintViolated), nil);
                return;
            }
            targets.append(UrlTarget(stringValue: name, key: "name"))
        }
        
        do {
            let _ = try AmatinoRequest(
                path: Self.listPath,
                data: nil,
                session: session,
                urlParameters: UrlParameters(targetsOnly: targets),
                method: .GET,
                callback: { (error, data) in
                    Entity.asyncInitMany(session, error, data, callback)
                }
            )
        } catch { callback(error, nil); return; }
        
    }
    
    public static func retrieveList(
        authenticatedBy session: Session,
        offset: Int = 0,
        limit: Int = 10,
        withName name: Optional<String> = nil,
        inState state: State = State.all,
        then callback: @escaping (Result<Array<Entity>, Error>) -> Void
    ) {
        
        Entity.retrieveList(
            authenticatedBy: session,
            offset: offset,
            limit: limit,
            withName: name,
            inState: state
        ) { (error, entities) in
                guard let entities = entities else {
                    callback(
                        .failure(error ?? AmatinoError(.inconsistentState))
                    );
                    return;
                }
                callback(.success(entities));
                return;
        }
        
    }
    
    public func delete(then callback: @escaping (Error?, Entity?) -> Void) {
        let parameters = UrlParameters(singleEntity: self)
        do {
            let _ = try AmatinoRequest(
                path: Entity.path,
                data: nil,
                session: session,
                urlParameters: parameters,
                method: .DELETE,
                callback: { (error, data) in
                    Entity.asyncInit(
                        session: self.session,
                        error: error,
                        data: data,
                        callback: callback
                    )
                }
            )
        } catch {
            callback(error, nil); return
        }

        return
    }
    
    public func delete(
        then callback: @escaping (Result<Entity, Error>) -> Void
    ) {
        self.delete { (error, entity) in
            guard let entity = entity else {
                callback(.failure(error ?? AmatinoError(.inconsistentState)))
                return
            }
            callback(.success(entity))
            return
        }
    }
    
    internal static func decodeMany(
        _ session: Session,
        _ data: Data
    ) throws -> [Entity] {

        let decoder = JSONDecoder()
        let attributes = try decoder.decode(
            [Entity.Attributes].self,
            from: data
        )
        let entities = attributes.map({Entity(session, $0)})
        return entities
    }
    
    internal static func asyncInitMany(
        _ session: Session,
        _ error: Error?,
        _ data: Data?,
        _ callback: @escaping (Error?, [Entity]?) -> Void
    ) {

        guard let data = data else {
            callback(
                (error ?? AmatinoError(.inconsistentState)),
                nil
            ); return
        }
        
        let entities: [Entity]
        
        do {
            entities = try Entity.decodeMany(session, data)
        } catch {
            callback(error, nil); return
        }

        callback(nil, entities)
        
        return
    }
    
    internal static func asyncInit(
        session: Session,
        error: Error?,
        data: Data?,
        callback: @escaping (Error?, Entity?) -> Void
    ) {
        
        let _ = Entity.asyncInitMany(
            session, error, data, { (error, entities) in
                guard let entities = entities else {
                    callback(
                        error ?? AmatinoError(.inconsistentState),
                        nil
                    ); return
                }
                callback(nil, entities[0])
                return
            }
        )
    }
    
    internal static func decode(
        session: Session,
        data: Data
        ) throws -> Entity {
        return try Entity.decodeMany(session, data)[0]
    }

    internal struct Attributes: Decodable {
        
        let id: String
        let ownerId: Int
        let name: String
        internal let permissionsGraph: [String:[String:[String:Bool]]]?
        let description: String?
        let regionId: Int
        let active: Bool
        let disposition: Disposition

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JSONObjectKeys.self)
            id = try container.decode(String.self, forKey: .id)
            ownerId = try container.decode(Int.self, forKey: .ownerId)
            name = try container.decode(String.self, forKey: .name)
            permissionsGraph = try container.decode(
                [String:[String:[String:Bool]]]?.self,
                forKey: .permissionsGraph
            )
            description = try container.decode(
                String?.self,
                forKey: .description
            )
            regionId = try container.decode(Int.self, forKey: .regionId)
            active = true
            disposition = try container.decode(
                Disposition.self,
                forKey: .disposition
            )
            return
        }
        
        enum JSONObjectKeys: String, CodingKey {
            case id = "entity_id"
            case ownerId = "owner"
            case name
            case permissionsGraph = "permissions_graph"
            case description
            case regionId = "region_id"
            case disposition = "disposition"
        }
        
    }

    public struct CreateArguments: Encodable {
        
        let name: Name
        let description: Description
        let regionId: Int?
        
        public init(
            name: String,
            description: String? = nil,
            region: Region? = nil
        ) throws {
            self.name = try Name(name)
            self.description = try Description(description ?? "")
            regionId = region?.id
            return
        }
        
        enum JSONObjectKeys: String, CodingKey {
            case name
            case description
            case regionId = "region_id"
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JSONObjectKeys.self)
            try container.encode(name.rawValue, forKey: .name)
            try container.encode(description.rawValue, forKey: .description)
            try container.encode(regionId, forKey: .regionId)
            return
        }
    }
    
    internal struct Name {
        let rawValue: String
        private var maxNameError: String { get {
            return "Max name length \(Entity.maxNameLength) characters"
        }}
        
        init(_ name: String) throws {
            rawValue = name
            guard name.count < Entity.maxNameLength else {
                throw ConstraintError(.nameLength, maxNameError)
            }
            return
        }
    }
    
    internal struct Description {
        let rawValue: String?
        private var maxDescriptionError: String { get {
            return "Max descrip. length \(Entity.maxDescriptionLength) char"
        }}
        
        init(_ description: String) throws {
            rawValue = description
            guard description.count < Entity.maxDescriptionLength else {
                throw ConstraintError(.descriptionLength, maxDescriptionError)
            }
            return
        }
        
        init() {
            rawValue = nil
            return
        }
    }
    
    public class ConstraintError: AmatinoError {
        public let constraint: Constraint
        public let constraintDescription: String
        
        internal init(_ cause: Constraint, _ description: String? = nil) {
            constraint = cause
            constraintDescription = description ?? cause.rawValue
            super.init(.constraintViolated)
            return
        }
        
        public enum Constraint: String {
            case descriptionLength = "Maximum description length exceeded"
            case nameLength = "Maximum name length exceeded"
        }
    }
    
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id == rhs.id
    }
}
