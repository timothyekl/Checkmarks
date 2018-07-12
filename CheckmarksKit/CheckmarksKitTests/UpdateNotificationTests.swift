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
    
    private var notified: Bool = false
    
    override func setUp() {
        super.setUp()
        notified = false
    }
    
    func testTaskCreationNotification() {
        XCTAssertNoThrow(try dataStore.addTask())
        XCTAssertTrue(notified)
    }
    
    func testTaskEditNotification() {
        do {
            let task = try dataStore.addTask()
            notified = false
            
            task.name = "Updated name"
            XCTAssertTrue(notified)
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }
    
    override func dataStore(_ dataStore: DataStore, didUpdateTasks tasks: Set<Task>) {
        super.dataStore(dataStore, didUpdateTasks: tasks)
        notified = true
    }
    
}
