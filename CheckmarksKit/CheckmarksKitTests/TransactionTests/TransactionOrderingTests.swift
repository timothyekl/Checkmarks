//
//  TransactionOrderingTests.swift
//  CheckmarksKitTests
//
//  Created by Tim Ekl on 7/10/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import XCTest
@testable import CheckmarksKit

class TransactionOrderingTests: TransactionTests {
    
    func testRootOnlyGraph() {
        withNoopGraph(havingTransactionNames: ["1000+ROOT"]) { (graph) in
            XCTAssertEqual(["ROOT"], graph.orderedTransactions.map({ $0.identifier }))
        }
    }
    
    func testLinearGraph() {
        let names = ["1000+ROOT", "2000+ROOT+abcd", "3000+abcd+efgh"]
        withNoopGraph(havingTransactionNames: names) { (graph) in
            XCTAssertEqual(["ROOT", "abcd", "efgh"], graph.orderedTransactions.map({ $0.identifier }))
        }
    }
    
    func testDiamond() {
        let names = ["1000+ROOT", "2000+ROOT+a", "2000+ROOT+b", "3000+a+b+c"]
        withNoopGraph(havingTransactionNames: names) { (graph) in
            XCTAssertEqual(["ROOT", "a", "b", "c"], graph.orderedTransactions.map({ $0.identifier }))
        }
    }
    
    func testInterleavedBranches() {
        let names = ["1000+ROOT", "2000+ROOT+a", "2500+ROOT+b", "3000+a+c", "3500+b+d", "4000+c+e", "4500+d+e+f"]
        withNoopGraph(havingTransactionNames: names) { (graph) in
            XCTAssertEqual(["ROOT", "a", "b", "c", "d", "e", "f"], graph.orderedTransactions.map({ $0.identifier }))
        }
    }
    
    func testDisparateBranches() {
        let names = ["1000+ROOT", "1100+ROOT+a", "1200+a+b", "1300+b+c", "2000+ROOT+d", "2100+d+e", "2200+e+f"]
        withNoopGraph(havingTransactionNames: names) { (graph) in
            XCTAssertEqual(["ROOT", "a", "b", "c", "d", "e", "f"], graph.orderedTransactions.map({ $0.identifier }))
        }
    }
    
}
