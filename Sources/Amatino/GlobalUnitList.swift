//
//  GlobalUnitList.swift
//  Amatino
//
//  Created by Hugh Jeremy on 18/7/18.
//

import Foundation

class GlobalUnitList: Sequence {
    
    private static let path = "/units/list"
    
    public let units: [GlobalUnit]
    public let count: Int
    
    private init (units: [GlobalUnit]) {
        self.units = units
        count = units.count
        return
    }
    
    public static func retrieve(
        authenticatedBy session: Session,
        then callback: @escaping (Error?, GlobalUnitList?) -> Void
        ) {

        do {
            let _ = try AmatinoRequest(
                path: path,
                data: nil,
                session: session,
                urlParameters: nil,
                method: .GET,
                callback: { (error, data) in
                    guard error == nil else { callback(error, nil); return }
                    let decodedUnits: [GlobalUnit]
                    let decoder = JSONDecoder()
                    do {
                        decodedUnits = try decoder.decode(
                            [GlobalUnit].self,
                            from: data!
                        )
                    } catch {
                        callback(error, nil)
                        return
                    }
                    let nameSortedUnits = decodedUnits.sorted {
                        ($0.priority, $0.name) < ($1.priority, $1.name)
                    }
                    let globalUnitList = GlobalUnitList(units: nameSortedUnits)
                    callback(nil, globalUnitList)
            })
        } catch {
            callback(error, nil)
        }

        return

    }
    
    public static func retrieve(
        authenticatedBy session: Session,
        then callback: @escaping (Result<GlobalUnitList, Error>) -> Void
    ) {
        GlobalUnitList.retrieve(authenticatedBy: session) { (error, list) in
            guard let list = list else {
                callback(.failure(error ?? AmatinoError(.inconsistentState)))
                return
            }
            callback(.success(list))
            return
        }
    }

    public func unitWith(code: String) -> GlobalUnit? {
        let searchTerm = code.uppercased()
        for unit in units {
            if unit.code == searchTerm {
                return unit
            }
        }
        return nil
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(units)
    }
    
    public struct Iterator: IteratorProtocol {
        let units: [GlobalUnit]
        var index = 0
        
        init(_ units: [GlobalUnit]) {
            self.units = units
        }
        
        public mutating func next() -> GlobalUnit? {
            guard index + 1 <= units.count else {
                return nil
            }
            let unitToReturn = units[index]
            index += 1
            return unitToReturn
        }
    }

}
