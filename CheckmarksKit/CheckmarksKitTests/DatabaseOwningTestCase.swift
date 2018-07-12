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
    
    // MARK: DataStore managing API
    
    func createNewDataStore() throws {
        precondition(dataStore == nil)
        dataStoreURL = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent("DatabaseOwningTestCase-\(UUID().uuidString).checkmarks")
        dataStore = try DataStore.createDataStore(at: dataStoreURL, owner: self)
        clearExpectations()
    }
    
    func openExistingDataStore(at url: URL) throws {
        precondition(dataStore == nil)
        dataStoreURL = url
        dataStore = try DataStore(url: url, owner: self)
        clearExpectations()
    }
    
    func destroyDataStore(deleteFiles: Bool) {
        precondition(dataStore != nil)
        dataStore = nil
        clearExpectations()
        defer { dataStoreURL = nil }
        
        if deleteFiles {
            try? FileManager.default.removeItem(at: dataStoreURL)
        }
    }
    
    // MARK: Expectations API
    
    private var seenTaskIdentifiers: Set<String> = []
    private var pendingCreationExpectations: [XCTestExpectation] = []
    private var pendingUpdateExpectations: [String: [XCTestExpectation]] = [:]
    
    func taskCreationExpectation() -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "Create a new task")
        pendingCreationExpectations.append(expectation)
        return expectation
    }
    
    func taskUpdateExpectation(identifier: String) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "Update task with identifier “\(identifier)”")
        pendingUpdateExpectations[identifier] = (pendingUpdateExpectations[identifier] ?? []) + [expectation]
        return expectation
    }
    
    private func clearExpectations() {
        seenTaskIdentifiers = []
        pendingCreationExpectations = []
        pendingUpdateExpectations = [:]
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
        
        let identifiers = Set<String>(tasks.map { $0.identifier })
        
        for identifier in identifiers {
            if !seenTaskIdentifiers.contains(identifier) {
                pendingCreationExpectations.forEach { $0.fulfill() }
                pendingCreationExpectations = []
            }
            
            if let updateExpectations = pendingUpdateExpectations[identifier] {
                updateExpectations.forEach { $0.fulfill() }
                pendingUpdateExpectations[identifier] = nil
            }
            
            seenTaskIdentifiers.insert(identifier)
        }
    }
    
    func dataStoreDidIncorporateTransactions(_ dataStore: DataStore) {
        assert(dataStore == self.dataStore)
        // Nothing more for now
    }

}
