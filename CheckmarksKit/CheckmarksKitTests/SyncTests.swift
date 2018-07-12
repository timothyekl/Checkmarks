//
//  SyncTests.swift
//  CheckmarksKitTests
//
//  Created by Tim Ekl on 7/12/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import XCTest
@testable import CheckmarksKit

class SyncTests: XCTestCase {
    
    func testSyncNewTask() {
        do {
            let alice = try Pseudoclient(name: "Alice")
            let bob = try alice.clone(named: "Bob")
            
            try alice.recordGroup(named: "add") { (dataStore) in
                let task = try dataStore.addTask()
                task.name = "Foo"
                try dataStore.save()
            }
            
            try bob.applyGroup(named: "add", from: alice)
            
            let tasks = try bob.dataStore.fetchTasks()
            XCTAssertEqual(1, tasks.count)
            XCTAssertEqual("Foo", tasks.first?.name)
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }
    
}
