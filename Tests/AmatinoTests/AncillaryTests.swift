
//
//  AmatinoTests.swift
//  PrimaryTests
//
//  Created by Hugh Jeremy on 16/7/18.
//

import XCTest
@testable import Amatino

class AncillaryTests: AmatinoTest {

    var session: Session? = nil
    
    func testCreateSession() {
        
        let expectation = XCTestExpectation(description: "Create Session")
        let _ = Session.create(
            email: dummyUserEmail(),
            secret: dummyUserSecret(),
            callback: { (error, session) in
                XCTAssertNil(error)
                XCTAssertNotNil(session)
                expectation.fulfill()
                self.session = session
            }
        )
        wait(for: [expectation], timeout: 8)
        
        return
    }

    func testRetrieveGlobalUnitsList() {
        
        let expectation = XCTestExpectation(description: "Retrieve units")
        
        func retrieveList(session: Session) {
            do {
                let _ = try GlobalUnitList.retrieve(
                    session: session,
                    callback: { (error, units) in
                        guard error == nil else {
                            XCTFail()
                            expectation.fulfill()
                            return
                        }
                        guard units != nil else {
                            XCTFail()
                            expectation.fulfill()
                            return
                        }
                        expectation.fulfill()
                        return
                })
            } catch {
                XCTFail()
                expectation.fulfill()
            }

        }
        
        if let existingSession: Session = self.session {
            retrieveList(session: existingSession)
        } else {
            let _ = Session.create(
                email: dummyUserEmail(),
                secret: dummyUserSecret(),
                callback: { (error, session) in
                    if let newSession: Session = session {
                        retrieveList(session: newSession)
                        return
                    }
                    XCTFail()
                    expectation.fulfill()
                    return
            })
        }

        wait(for: [expectation], timeout: 8)
        return
    }

}
