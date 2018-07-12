//
//  Pseudoclient.swift
//  CheckmarksKitTests
//
//  Created by Tim Ekl on 7/12/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import Foundation
@testable import CheckmarksKit

class Pseudoclient: DataStoreOwner {
    
    private(set) var name: String
    private(set) var dataStore: DataStore!
    private var recorder: TransactionRecorder
    
    convenience init(name: String) throws {
        try self.init(name: name, sourceURL: nil)
    }
    
    func clone(named name: String) throws -> Pseudoclient {
        return try Pseudoclient(name: name, sourceURL: dataStore.url)
    }
    
    func recordGroup(named name: String, _ actions: ((DataStore) throws -> Void)) throws {
        try actions(dataStore)
        try recorder.captureGroup(named: name, from: dataStore)
    }
    
    func applyGroup(named name: String, from other: Pseudoclient) throws {
        try other.recorder.replayGroup(named: name, into: dataStore)
        try recorder.captureGroup(named: name, from: dataStore)
    }
    
    private init(name: String, sourceURL: URL?) throws {
        self.name = name
        self.recorder = TransactionRecorder()
        
        let dataStoreURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Pseudoclient-\(UUID().uuidString).checkmarks")
        
        if let sourceURL = sourceURL {
            try FileManager.default.copyItem(at: sourceURL, to: dataStoreURL)
            dataStore = try DataStore(url: dataStoreURL, owner: self)
        } else {
            dataStore = try DataStore.createDataStore(at: dataStoreURL, owner: self)
        }
        
        try recorder.captureGroup(named: "initial", from: dataStore)
    }
    
    deinit {
        try? FileManager.default.removeItem(at: dataStore.url)
    }
    
    // MARK: DataStoreOwner
    
    func dataStore(_ dataStore: DataStore, didUpdateTasks tasks: Set<Task>) {
        // Nothing
    }
    
    func dataStoreDidIncorporateTransactions(_ dataStore: DataStore) {
        // Nothing
    }
    
}
