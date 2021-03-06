//
//  DerivedObjectTest.swift
//  AmatinoTests
//
//  Created by Hugh Jeremy on 18/7/18.
//

import Foundation
import XCTest
@testable import Amatino

class DerivedObjectTest: AmatinoTest {
    
    var session: Session? = nil
    var entity: Entity? = nil
    var unit: GlobalUnit? = nil
    var cashAccount: Account? = nil
    var revenueAccount: Account? = nil
    var liabilityAccount: Account? = nil
    
    override func setUp() {
        
        continueAfterFailure = false
        
        let sessionExpectation = XCTestExpectation(description: "Session")
        let entityExpectation = XCTestExpectation(description: "Entity")
        let unitExpectation = XCTestExpectation(description: "Unit")
        let accountExpectation = XCTestExpectation(description: "Accounts")
        let transactionExpectation = XCTestExpectation(
            description: "Transactions"
        )
        let expectations = [
            sessionExpectation,
            entityExpectation,
            unitExpectation,
            accountExpectation,
            transactionExpectation
        ]
        
        func createTransactions(
            _ session: Session,
            _ entity: Entity,
            _ cashAccount: Account,
            _ revenueAccount: Account,
            _ usd: GlobalUnit
            ) {
            do {
                let tx1Arguments = try Transaction.CreateArguments(
                    transactionTime: Date(timeIntervalSinceNow: (-3600*24*2)),
                    description: "Test transaction 1",
                    denomination: usd,
                    entries: [
                        Entry(
                            side: .debit,
                            account: cashAccount,
                            amount: Decimal(20)
                        ),
                        Entry(
                            side: .credit,
                            account: revenueAccount,
                            amount: Decimal(20)
                        )
                    ]
                )
                let tx2Arguments = try Transaction.CreateArguments(
                    transactionTime: Date(timeIntervalSinceNow: (-3600*24)),
                    description: "Test transaction 2",
                    denomination: usd,
                    entries: [
                        Entry(
                            side: .debit,
                            account: cashAccount,
                            amount: Decimal(10)
                        ),
                        Entry(
                            side: .credit,
                            account: revenueAccount,
                            amount: Decimal(10)
                        )
                    ]
                )
                let tx3Arguments = try Transaction.CreateArguments(
                    transactionTime: Date(),
                    description: "Test transaction 3",
                    denomination: usd,
                    entries: [
                        Entry(
                            side: .debit,
                            account: cashAccount,
                            amount: Decimal(5)
                        ),
                        Entry(
                            side: .credit,
                            account: revenueAccount,
                            amount: Decimal(5)
                        )
                    ]
                )
                let _ = Transaction.createMany(
                    in: entity,
                    arguments: [tx1Arguments, tx2Arguments, tx3Arguments],
                    then: { (error, transactions) in
                        guard self.responsePassing(
                            error,
                            transactions,
                            expectations
                            ) else {
                                return
                        }
                        transactionExpectation.fulfill()
                        return
                })

            } catch {
                XCTFail()
                transactionExpectation.fulfill()
                return
            }
        }
        
        func createAccounts(
            _ session: Session,
            _ entity: Entity,
            _ unit: GlobalUnit
            ) {
            do {
                let cashAccountArguments = try Account.CreateArguments(
                    name: "T1 Cash",
                    type: .asset,
                    description: "Test asset account",
                    denomination: unit
                )
                let revenueAccountArguments = try Account.CreateArguments(
                    name: "T4 Revenue",
                    type: .income,
                    description: "Test income account",
                    denomination: unit
                )
                let liabilityAccountArguments = try Account.CreateArguments(
                    name: "T2 Liability",
                    type: .liability,
                    description: "Test liability account",
                    denomination: unit
                )
                let arguments = [
                    revenueAccountArguments,
                    cashAccountArguments,
                    liabilityAccountArguments
                ]
                let _ = Account.createMany(
                    in: entity,
                    arguments: arguments,
                    then: { (error, accounts) in
                        guard self.responsePassing(
                            error,
                            accounts,
                            expectations
                        ) else {
                            return
                        }
                        self.revenueAccount = accounts![0]
                        self.cashAccount = accounts![1]
                        self.liabilityAccount = accounts![2]
                        accountExpectation.fulfill()
                        createTransactions(
                            session,
                            entity,
                            self.cashAccount!,
                            self.revenueAccount!,
                            self.unit!
                        )
                        return
                })
            } catch {
                XCTFail()
                accountExpectation.fulfill()
                return
            }
            
            return
            
        }
        
        func retrieveUnit(_ : Session, _: Entity) {
            let _ = GlobalUnit.retrieve(
                withId: 5,
                authenticatedBy: session!,
                then: { (error, globalUnit) in
                    guard self.responsePassing(
                        error,
                        globalUnit,
                        expectations
                    ) else {
                        return
                    }
                    self.unit = globalUnit!
                    unitExpectation.fulfill()
                    createAccounts(self.session!, self.entity!, self.unit!)
                    return
            })
        }
        
        func createEntity(_ session: Session) {
            let _ = Entity.create(
                authenticatedBy: session,
                withName: "Amatino Swift test entity") { (error, entity) in
                    guard self.responsePassing(
                        error,
                        entity,
                        expectations
                    ) else {
                        return
                    }
                    self.entity = entity
                    entityExpectation.fulfill()
                    retrieveUnit(session, entity!)
            }
        }
        
        let _ = Session.create(
            email: dummyUserEmail(),
            secret: dummyUserSecret(),
            then: { (error, session) in
                guard self.responsePassing(error, session, expectations) else {
                    return
                }
                self.session = session
                sessionExpectation.fulfill()
                createEntity(session!)
        })
        
        wait(for: expectations, timeout: 12, enforceOrder: false)
        return
    }
    
}
