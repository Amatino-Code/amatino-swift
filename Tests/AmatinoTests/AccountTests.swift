//
//  AccountTests.swift
//  AmatinoTests
//
//  Created by Hugh Jeremy on 16/7/18.
//

import Foundation
import XCTest
@testable import Amatino

class AccountTests: AmatinoTest {
    
    var session: Session? = nil
    var entity: Entity? = nil
    var unit: GlobalUnit? = nil
    
    override func setUp() {
        
        continueAfterFailure = false

        let sessionExpectation = XCTestExpectation(description: "Session")
        let entityExpectation = XCTestExpectation(description: "Entity")
        let unitExpectation = XCTestExpectation(description: "Unit")
        let expectations = [
            sessionExpectation,
            entityExpectation,
            unitExpectation
        ]
        
        func retrieveUnit(_: Session, _: Entity) {
            let _ = GlobalUnit.retrieve(
                withId: 5,
                authenticatedBy: session!,
                then: { (error, globalUnit) in
                    do {
                        let _ = try self.assertNil(error)
                        let _ = try self.assertNotNil(globalUnit)
                    } catch {
                        self.failWith(error, expectations)
                        return
                    }
                    self.unit = globalUnit!
                    unitExpectation.fulfill()
                    return
            })
        }
        
        func createEntity(_: Session) {
            let _ = Entity.create(
                authenticatedBy: session!,
                withName: "Amatino Swift test entity") { (error, entity) in
                    do {
                        let _ = try self.assertNil(error)
                        let _ = try self.assertNotNil(entity)
                    } catch {
                        self.failWith(error, expectations)
                        return
                    }
                    self.entity = entity
                    entityExpectation.fulfill()
                    retrieveUnit(self.session!, self.entity!)
            }
        }
        
        let _ = Session.create(
            email: dummyUserEmail(),
            secret: dummyUserSecret(),
            then: { (error, session) in
                do {
                    let _ = try self.assertNil(error)
                    let _ = try self.assertNotNil(session)
                } catch {
                    self.failWith(error, expectations)
                    return
                }
                self.session = session
                sessionExpectation.fulfill()
                createEntity(session!)
        })

        wait(for: expectations, timeout: 8, enforceOrder: false)
        return
    }
    
    func testCreateAccount() throws {
        let _ = try assertNotNil(session)
        let _ = try assertNotNil(entity)
        let _ = try assertNotNil(unit)
        let expectation = XCTestExpectation(description: "Create Account")
        
        let _ = Account.create(
            in: entity!,
            named: "Amatino Swift test account",
            type: .asset,
            description: "Testing account creation",
            denominatedIn: unit!,
            then: { (error, account) in
                do {
                    let _ = try self.assertNil(error)
                    let _ = try self.assertNotNil(account)
                } catch {
                    self.failWith(error, [expectation])
                    return
                }
                expectation.fulfill()
                return
        })

        wait(for: [expectation], timeout: 5)
        return
    }
    
    func testRetrieveAccount() throws {
        let _ = try assertNotNil(session)
        let _ = try assertNotNil(entity)
        let _ = try assertNotNil(unit)

        let expectation = XCTestExpectation(description: "Retrieve Account")
        
        func retrieveAccount(_ accountId: Int) {
            let _ = Account.retrieve(
                from: entity!,
                withId: accountId,
                then: { (error, account) in
                    do {
                        let _ = try self.assertNil(error)
                        let _ = try self.assertNotNil(account)
                    } catch {
                        self.failWith(error, [expectation])
                        return
                    }
                    expectation.fulfill()
                    return
            })
        }
        
        let _ = Account.create(
            in: entity!,
            named: "Amatino Swift test account",
            type: .asset,
            description: "Testing account retrieval",
            denominatedIn: unit!,
            then: { (error, account) in
                do {
                    let _ = try self.assertNil(error)
                    let _ = try self.assertNotNil(account)
                } catch {
                    self.failWith(error, [expectation])
                    return
                }
                let _ = retrieveAccount(account!.id)
                return
        })

        wait(for: [expectation], timeout: 5)
        return
    }
    
    func testUpdateAccount() {
        
        let expectation = XCTestExpectation(description: "Update Account")
        
        let replacementName = "Updated Account"
        
        func updateAccount(_ account: Account) {
            let _ = account.update(
                name: "Updated Account",
                description: account.description,
                parent: nil,
                type: account.type,
                colour: nil,
                denomination: unit!,
                then: { (error, account) in
                    guard error == nil else {
                        let cast = error as? AmatinoError
                        print(cast?.description ?? "Unknown Error")
                        XCTFail(); expectation.fulfill(); return
                    }
                    guard let updatedAccount: Account = account else {
                        XCTFail(); expectation.fulfill(); return
                    }
                    guard updatedAccount.name == replacementName else {
                        print("Account name: \(updatedAccount.name)")
                        XCTFail(); expectation.fulfill(); return
                    }
                    expectation.fulfill(); return
            })
        }
        
        func executeProcedure() {
            let _ = Account.create(
                in: entity!,
                named: "Amatino Swift test account",
                type: .asset,
                description: "Testing account update",
                denominatedIn: unit!,
                then: { (error, account) in
                    do {
                        let _ = try self.assertNil(error)
                        let _ = try self.assertNotNil(account)
                    } catch {
                        self.failWith(error, [expectation])
                        return
                    }
                    updateAccount(account!)
                    return
            })
        }
        
        executeProcedure()
        wait(for: [expectation], timeout: 5)
        return
        
    }
    
    func testDeleteAccount() {
        
        let expectation = XCTestExpectation(description: "Delete Account")
        
        func lookupDeletedAccount(_ account: Account) {
            let _ = Account.retrieve(
                from: entity!,
                withId: account.id,
                then: { (error, account) in
                    guard account == nil else {
                        XCTFail(); expectation.fulfill(); return
                    }
                    guard let amError = error as? AmatinoError else {
                        XCTFail(); expectation.fulfill(); return
                    }
                    guard amError.kind == .notFound else {
                        XCTFail(); expectation.fulfill(); return
                    }
                    expectation.fulfill()
                    return
            })
        }
        
        func deleteAccount(_ cash: Account, _ bank: Account) {
            do {
                let _ = try cash.delete(
                    entryReplacement: bank,
                    callback: { (error) in
                        guard error == nil else {
                            let cast = error as? AmatinoError
                            print(cast?.description ?? "Unknown Error")
                            XCTFail(); expectation.fulfill(); return
                        }
                        let _ = lookupDeletedAccount(cash)
                })
            } catch {
                print((error as? AmatinoError)?.description ?? "Unknown Err.")
                XCTFail(); expectation.fulfill(); return
            }
        }
        
        func executeProcedure() {
            do {
                let cashAccountArguments = try Account.CreateArguments(
                    name: "[Deletion] T1A Cash",
                    type: .asset,
                    description: "Test asset account for deletion",
                    denomination: unit!
                )
                let revenueAccountArguments = try Account.CreateArguments(
                    name: "[Deletion] T1B Bank",
                    type: .asset,
                    description: "Test bank account for deletion",
                    denomination: unit!
                )
                let arguments = [cashAccountArguments, revenueAccountArguments]
                let _ = Account.createMany(
                    in: entity!,
                    arguments: arguments,
                    then: { (error, accounts) in
                        guard accounts != nil else {
                            XCTFail(); expectation.fulfill(); return
                        }
                        guard accounts!.count == 2 else {
                            XCTFail(); expectation.fulfill(); return
                        }
                        let _ = deleteAccount(accounts![0], accounts![1])
                })
            } catch {
                print((error as? AmatinoError)?.description ?? "Unknown Err.")
                XCTFail(); expectation.fulfill(); return
            }
        }
        
        executeProcedure()
        wait(for: [expectation], timeout: 5)
        return
    }
    
}
