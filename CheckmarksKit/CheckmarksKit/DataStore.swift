//
//  DataStore.swift
//  CheckmarksKit
//
//  Created by Tim Ekl on 7/10/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import UIKit

public protocol DataStoreOwner: class {
    func dataStore(_ dataStore: DataStore, didUpdateTasks tasks: Set<Task>)
}

public class DataStore: NSObject {
    
    public static func createDataStore(at url: URL, owner: DataStoreOwner) throws -> DataStore {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        let rootTransaction = Transaction.makeRootTransaction()
        try rootTransaction.write(in: url)
        return try DataStore(url: url, owner: owner)
    }
    
    private var tasks: [String: Task]
    private var recentlyChanged: Set<Task> = []
    private var graph: TransactionGraph
    
    private weak var owner: DataStoreOwner?
    
    public init(url: URL, owner: DataStoreOwner) throws {
        self.graph = try TransactionGraph(url: url)
        
        self.tasks = [:]
        self.owner = owner
        
        super.init()
        
        // Throw away the updates on init? Seems unlikely the owner will care this early
        let _ = graph.orderedTransactions.reduce(Set<Task>()) { (alreadyUpdated, transaction) -> Set<Task> in
            let transactionUpdated = applyChanges(from: transaction)
            return alreadyUpdated.union(transactionUpdated)
        }
    }
    
    public func addTask() throws -> Task {
        let identifier = UUID().uuidString
        let task = Task(identifier: identifier, dataStore: self)
        
        tasks[identifier] = task
        recentlyChanged.insert(task)
        owner?.dataStore(self, didUpdateTasks: [task])
        
        return task
    }
    
    public func fetchTasks(filter: ((Task) -> Bool) = { _ in true }, sort: ((Task, Task) -> Bool)? = nil) throws -> [Task] {
        let filteredTasks = Array(tasks.values).filter(filter)
        guard let sort = sort else { return filteredTasks }
        return filteredTasks.sorted(by: sort)
    }
    
    public func save() throws {
        graph = try graph.addingTransaction(updating: Array(recentlyChanged))
        recentlyChanged = []
    }
    
    func recordChange(to task: Task) {
        recentlyChanged.insert(task)
        owner?.dataStore(self, didUpdateTasks: [task])
    }
    
    private func applyChanges(from transaction: Transaction) -> Set<Task> {
        var updated: Set<Task> = []
        for taskChange in transaction.contents.taskChanges {
            let identifier = taskChange.identifier
            let task = tasks[identifier] ?? Task(identifier: identifier, dataStore: self)
            task.name = taskChange.name
            task.completed = taskChange.completed
            tasks[identifier] = task
            updated.insert(task)
        }
        return updated
    }
}
