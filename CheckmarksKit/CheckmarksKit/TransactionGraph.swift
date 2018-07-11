//
//  TransactionGraph.swift
//  CheckmarksKit
//
//  Created by Tim Ekl on 7/10/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import Foundation

enum TransactionError: Error {
    case invalidURL
    case malformedGraph
    case writeFailed
}

struct Transaction: Equatable, Hashable {
    static let rootIdentifier: String = "ROOT"
    static let identifierSeparator: String = "+"
    static let pathExtension: String = "cmtxn"
    
    static let comparator: ((Transaction, Transaction) -> Bool) = { (lhs, rhs) -> Bool in
        if lhs.timestamp < rhs.timestamp { return true }
        if lhs.timestamp > rhs.timestamp { return false }
        return lhs.identifier < rhs.identifier
    }
    
    static func makeIdentifier() -> String {
        return UUID().uuidString.components(separatedBy: "-").first!
    }
    
    static func makeRootTransaction() -> Transaction {
        var result = Transaction(parentIdentifiers: [], contents: Contents(taskChanges: []))
        result.identifier = Transaction.rootIdentifier
        return result
    }
    
    static func ==(lhs: Transaction, rhs: Transaction) -> Bool {
        guard lhs.timestamp == rhs.timestamp else { return false }
        guard lhs.identifier == rhs.identifier else { return false }
        guard lhs.parentIdentifiers == rhs.parentIdentifiers else { return false }
        return true
    }
    
    var hashValue: Int {
        return parentIdentifiers.reduce(Int(timestamp) ^ identifier.hashValue) { hash, parentIdentifier in hash ^ parentIdentifier.hash }
    }
    
    private(set) var timestamp: UInt
    private(set) var identifier: String
    private(set) var parentIdentifiers: [String]
    
    struct Contents: Codable {
        struct TaskChange: Codable {
            var identifier: String
            var name: String
            var completed: Bool
        }
        var taskChanges: [TaskChange]
    }
    
    private(set) var contents: Contents
    
    init(url: URL) throws {
        guard url.pathExtension == Transaction.pathExtension else { throw TransactionError.invalidURL }
        
        let name = url.deletingPathExtension().lastPathComponent
        let parts = name.components(separatedBy: Transaction.identifierSeparator)
        guard parts.count >= 2 else { throw TransactionError.invalidURL }
        
        guard let timestamp = UInt(parts.first!) else { throw TransactionError.invalidURL }
        self.timestamp = timestamp
        
        self.identifier = parts.last!
        if (self.identifier == Transaction.rootIdentifier) {
            guard parts.count == 2 else { throw TransactionError.invalidURL }
            self.parentIdentifiers = []
        } else {
            guard parts.count >= 3 else { throw TransactionError.invalidURL }
            self.parentIdentifiers = Array(parts.dropLast().dropFirst())
        }
        
        let data = try Data(contentsOf: url)
        contents = try JSONDecoder().decode(Contents.self, from: data)
    }
    
    init(parentIdentifiers: [String], contents: Contents) {
        self.timestamp = UInt(Date().timeIntervalSince1970)
        self.identifier = Transaction.makeIdentifier()
        self.parentIdentifiers = parentIdentifiers
        self.contents = contents
    }
    
    var filename: String {
        var components = parentIdentifiers
        components.insert("\(timestamp)", at: 0)
        components.append(identifier)
        return (components.joined(separator: Transaction.identifierSeparator) as NSString).appendingPathExtension(Transaction.pathExtension)!
    }
    
    func write(in container: URL) throws {
        let url = container.appendingPathComponent(filename)
        let data = try JSONEncoder().encode(contents)
        if !FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil) {
            throw TransactionError.writeFailed
        }
    }
}

struct TransactionGraph {
    
    private(set) var url: URL
    private var transactions: [String: Transaction]
    
    var orderedTransactions: [Transaction] {
        var transactionsByParent: [String: [Transaction]] = [:]
        for (_, transaction) in transactions {
            for parentIdentifier in transaction.parentIdentifiers {
                transactionsByParent[parentIdentifier] = (transactionsByParent[parentIdentifier] ?? []) + [transaction]
            }
        }
        
        let rootTransaction = transactions[Transaction.rootIdentifier]!
        var result: [Transaction] = []
        var queue: Set<Transaction> = [rootTransaction]
        var seen: Set<Transaction> = [rootTransaction]
        while !queue.isEmpty {
            let next = queue.sorted(by: Transaction.comparator).first!
            queue.remove(next)
            let children = transactionsByParent[next.identifier] ?? []
            
            let newChildren = children.filter({ !seen.contains($0) })
            seen.formUnion(newChildren)
            queue.formUnion(newChildren)
            result.append(next)
        }
        
        return result
    }
    
    var tailTransactions: [Transaction] {
        var tails: Set<Transaction> = []
        var seenParentIdentifiers: Set<String> = []
        for transaction in orderedTransactions.reversed() {
            if !seenParentIdentifiers.contains(transaction.identifier) {
                tails.insert(transaction)
            }
            seenParentIdentifiers.formUnion(transaction.parentIdentifiers)
        }
        return tails.sorted(by: Transaction.comparator)
    }
    
    init(url: URL) throws {
        guard url.isFileURL else { throw TransactionError.invalidURL }
        self.url = url
        
        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        let transactionURLs = contents.filter { $0.pathExtension == Transaction.pathExtension }
        let transactions = try transactionURLs.map { try Transaction(url: $0) }
        self.transactions = Dictionary(uniqueKeysWithValues: transactions.map({ ($0.identifier, $0) }))
        
        guard self.transactions[Transaction.rootIdentifier] != nil else { throw TransactionError.malformedGraph }
    }
    
    func addingTransaction(updating tasks: [Task]) throws -> TransactionGraph {
        let changes = tasks.map { task in
            return Transaction.Contents.TaskChange(identifier: task.identifier, name: task.name, completed: task.completed)
        }
        
        let tailTransactionIdentifiers = tailTransactions.map { $0.identifier }
        let transaction = Transaction(parentIdentifiers: tailTransactionIdentifiers, contents: Transaction.Contents(taskChanges: changes))
        try transaction.write(in: url)
        return try TransactionGraph(url: url)
    }
    
}
