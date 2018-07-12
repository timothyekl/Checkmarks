//
//  DatabaseOwningTestCase.swift
//  CheckmarksKitTests
//
//  Created by Tim Ekl on 7/11/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import XCTest
@testable import CheckmarksKit

class DatabaseOwningTestCase: XCTestCase, DataStoreOwner {
    
    private(set) var dataStoreURL: URL!
    private(set) var dataStore: DataStore!
    
    func createNewDataStore() throws {
        precondition(dataStore == nil)
        dataStoreURL = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent("DatabaseOwningTestCase-\(UUID().uuidString).checkmarks")
        dataStore = try DataStore.createDataStore(at: dataStoreURL, owner: self)
    }
    
    func openExistingDataStore(at url: URL) throws {
        precondition(dataStore == nil)
        dataStoreURL = url
        dataStore = try DataStore(url: url, owner: self)
    }
    
    func destroyDataStore(deleteFiles: Bool) {
        precondition(dataStore != nil)
        dataStore = nil
        defer { dataStoreURL = nil }
        
        if deleteFiles {
            try? FileManager.default.removeItem(at: dataStoreURL)
        }
    }
    
    // MARK: XCTestCase subclass
    
    override func setUp() {
        super.setUp()
        XCTAssertNoThrow(try createNewDataStore())
    }
    
    override func tearDown() {
        destroyDataStore(deleteFiles: true)
        super.tearDown()
    }
    
    // MARK: DataStoreOwner
    
    func dataStore(_ dataStore: DataStore, didUpdateTasks tasks: Set<Task>) {
        assert(dataStore == self.dataStore)
    }
    
    func dataStoreDidIncorporateTransactions(_ dataStore: DataStore) {
        assert(dataStore == self.dataStore)
        // Nothing more for now
    }

}
