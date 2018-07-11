//
//  TransactionTests.swift
//  CheckmarksKitTests
//
//  Created by Tim Ekl on 7/10/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import XCTest
@testable import CheckmarksKit

class TransactionTests: XCTestCase {
    func withNoopGraph(havingTransactionNames names: [String], perform block: ((TransactionGraph) -> Void)) {
        let temporaryGraphURL = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent("TransactionOrderingTests-\(UUID().uuidString).checkmarks")
        
        do {
            try FileManager.default.createDirectory(at: temporaryGraphURL, withIntermediateDirectories: true, attributes: nil)
        } catch let e {
            XCTFail("Failed to create test graph: \(e)")
            return
        }
        defer { try? FileManager.default.removeItem(at: temporaryGraphURL) }
        
        for name in names {
            let url = temporaryGraphURL.appendingPathComponent(name).appendingPathExtension(Transaction.pathExtension)
            let contents = "{\"taskChanges\":[]}".data(using: .utf8)
            if !FileManager.default.createFile(atPath: url.path, contents: contents, attributes: nil) {
                XCTFail("Failed to create transaction named \(name)")
                return
            }
        }
        
        do {
            let temporaryGraph = try TransactionGraph(url: temporaryGraphURL)
            block(temporaryGraph)
        } catch let e {
            XCTFail("Failed to build graph with transactions: \(e)")
        }
    }
}
