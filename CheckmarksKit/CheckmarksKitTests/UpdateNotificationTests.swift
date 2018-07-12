//
//  UpdateNotificationTests.swift
//  CheckmarksKitTests
//
//  Created by Tim Ekl on 7/12/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import XCTest
@testable import CheckmarksKit

class UpdateNotificationTests: DatabaseOwningTestCase {
    
    func testTaskCreationNotification() {
        let expectation = taskCreationExpectation()
        XCTAssertNoThrow(try dataStore.addTask())
        wait(for: [expectation], timeout: 1)
    }
    
    func testTaskEditNotification() {
        let task: Task
        do {
            task = try dataStore.addTask()
        } catch let e {
            XCTFail(e.localizedDescription)
            return
        }

        let expectation = taskUpdateExpectation(identifier: task.identifier)
        task.name = "Updated name"
        wait(for: [expectation], timeout: 1)
    }
    
}
