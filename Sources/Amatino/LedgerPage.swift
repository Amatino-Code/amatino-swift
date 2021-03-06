//
//  LedgerPage.swift
//  Amatino
//
//  Created by Hugh Jeremy on 28/7/18.
//

import Foundation

public class LedgerPage: AmatinoObject, Sequence {

    internal static let path = "/accounts/ledger"
    
    public let accountId: Int
    public let start: Date
    public let end: Date
    public let generated: Date
    public let recursive: Bool
    public let globalUnitDenominationId: Int?
    public let customUnitDenominationId: Int?
    public let rows: [LedgerRow]
    public let page: Int
    public let numberOfPages: Int
    public let order: LedgerOrder
    
    public var totalRows: Int {
        get {
            return rows.count
        }
    }
    
    subscript(index: Int) -> LedgerRow {
        return rows[index]
    }

    public var earliest: LedgerRow? {
        get {
            switch order {
            case .oldestFirst:
                return rows.first
            case .youngestFirst:
                return rows.last
            }
        }
    }
    
    public var latest: LedgerRow? {
        get {
            switch order {
            case .oldestFirst:
                return rows.last
            case .youngestFirst:
                return rows.first
            }
        }
    }

    public static func retrieve(
        session: Session,
        entity: Entity,
        arguments: LedgerPage.RetrievalArguments,
        callback: @escaping (Error?, LedgerPage?) -> Void
    ) throws {
        
        let urlParameters = UrlParameters(singleEntity: entity)
        let requestData = try RequestData(
            data: arguments,
            overrideListing: true
        )
        let _ = try AmatinoRequest(
            path: LedgerPage.path,
            data: requestData,
            session: session,
            urlParameters: urlParameters,
            method: .GET,
            callback: { (error, data) in
                let _ = loadObjectResponse(
                    error,
                    data,
                    callback
                )
        })
    }
    
    required public init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try container.decode(Int.self, forKey: .accountId)
        let rawstart = try container.decode(
            String.self,
            forKey: .start
        )
        start = try AmatinoDate(fromString: rawstart).decodedDate
        let rawend = try container.decode(String.self, forKey: .end)
        end = try AmatinoDate(fromString: rawend).decodedDate
        let rawgenerated = try container.decode(
            String.self,
            forKey: .generated
        )
        generated = try AmatinoDate(fromString: rawgenerated).decodedDate
        recursive = try container.decode(Bool.self, forKey: .recursive)
        globalUnitDenominationId = try container.decode(
            Int?.self,
            forKey: .globalUnitDenominationId
        )
        customUnitDenominationId = try container.decode(
            Int?.self,
            forKey: .customUnitDenominationId
        )
        rows = try container.decode([LedgerRow].self, forKey: .ledgerRows)
        page = try container.decode(Int.self, forKey: .page)
        numberOfPages = try container.decode(
            Int.self,
            forKey: .numberOfPages
        )
        let oldestFirst = try container.decode(
            Bool.self,
            forKey: .oldestFirst
        )
        if oldestFirst == true {
            order = .oldestFirst
        } else {
            order = .youngestFirst
        }
        return
    }

    public func makeIterator() -> Ledger.Iterator {
        return Ledger.Iterator(rows)
    }

    internal enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case start = "start_time"
        case end = "end_time"
        case generated = "generated_time"
        case recursive
        case globalUnitDenominationId = "global_unit_denomination"
        case customUnitDenominationId = "custom_unit_denomination"
        case ledgerRows = "ledger_rows"
        case numberOfPages = "number_of_pages"
        case page
        case oldestFirst = "ordered_oldest_first"
    }

    public struct RetrievalArguments: Encodable {
        
        let accountId: Int
        let start: Date?
        let end: Date?
        let page: Int?
        let globalUnitDenominationId: Int?
        let customUnitDenominationId: Int?
        let order: LedgerOrder
        
        public init (
            account: AccountRepresentative,
            denominatedIn denomination: Denomination? = nil,
            startingAt start: Date? = nil,
            endingAt end: Date? = nil,
            page: Int? = nil,
            inOrder order: LedgerOrder = .oldestFirst
        ) {
            accountId = account.accountId
            self.start = start
            self.end = end
            self.page = page
            self.order = order
            
            if denomination == nil {
                globalUnitDenominationId = nil
                customUnitDenominationId = nil
                return
            }
            
            let customUnitId: Int?
            let globalUnitId: Int?
            
            if let customUnit = denomination as? CustomUnit {
                globalUnitId = nil
                customUnitId = customUnit.id
            } else if let globalUnit = denomination as? GlobalUnit {
                customUnitId = nil
                globalUnitId = globalUnit.id
            } else {
                fatalError("Unknown denominating type")
            }
            globalUnitDenominationId = globalUnitId
            customUnitDenominationId = customUnitId
            return
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(accountId, forKey: .accountId)
            try container.encode(start, forKey: .start)
            try container.encode(end, forKey: .end)
            try container.encode(page, forKey: .page)
            try container.encode(
                globalUnitDenominationId,
                forKey: .globalUnitDenominationId
            )
            try container.encode(
                customUnitDenominationId,
                forKey: .customUnitDenominationId
            )
            if order == .oldestFirst {
                try container.encode(true, forKey: .order)
            } else {
                try container.encode(false, forKey: .order)
            }
            return
        }
        
        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case start = "start_time"
            case end = "end_time"
            case page
            case globalUnitDenominationId = "global_unit_denomination"
            case customUnitDenominationId = "custom_unit_denomination"
            case order = "order_oldest_first"
        }
    }
    
}
