//
//  TransactionReplayTests.swift
//  CheckmarksKitTests
//
//  Created by Tim Ekl on 7/12/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import XCTest
@testable import CheckmarksKit

class TransactionReplayTests: DatabaseOwningTestCase {
    
    func testReplayAddTask() {
        do {
            let recorder = TransactionRecorder()
            try recorder.captureGroup(named: "initial", from: dataStore)
            
            let addedTask = try dataStore.addTask()
            addedTask.name = "Foo"
            try dataStore.save()
            try recorder.captureGroup(named: "added", from: dataStore)
            
            destroyDataStore(deleteFiles: true)
            try createNewDataStore()
            
            try recorder.replayGroup(named: "added", into: dataStore)
            
            let tasks = try dataStore.fetchTasks()
            XCTAssertEqual(1, tasks.count)
            XCTAssertEqual("Foo", tasks.first?.name)
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }
    
}
