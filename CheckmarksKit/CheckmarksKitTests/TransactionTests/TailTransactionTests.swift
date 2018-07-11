//
//  TailTransactionTests.swift
//  CheckmarksKitTests
//
//  Created by Tim Ekl on 7/10/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import XCTest
@testable import CheckmarksKit

class TailTransactionTests: TransactionTests {
    
    func testSingleTail() {
        let names = ["1000+ROOT", "2000+ROOT+a", "3000+a+b"]
        withNoopGraph(havingTransactionNames: names) { (graph) in
            XCTAssertEqual(["b"], graph.tailTransactions.map({ $0.identifier }))
        }
    }
    
    func testTwoLongBranchTails() {
        let names = ["1000+ROOT", "1100+ROOT+a", "1200+a+b", "1300+b+c", "2000+ROOT+d", "2100+d+e"]
        withNoopGraph(havingTransactionNames: names) { (graph) in
            XCTAssertEqual(["c", "e"], graph.tailTransactions.map({ $0.identifier }))
        }
    }
    
    func testManyTails() {
        let names = ["1000+ROOT", "2000+ROOT+a", "3000+ROOT+b", "4000+ROOT+c", "5000+ROOT+d"]
        withNoopGraph(havingTransactionNames: names) { (graph) in
            XCTAssertEqual(["a", "b", "c", "d"], graph.tailTransactions.map({ $0.identifier }))
        }
    }
    
    func testDiamondTail() {
        let names = ["1000+ROOT", "2000+ROOT+a", "3000+ROOT+b", "4000+a+b+c"]
        withNoopGraph(havingTransactionNames: names) { (graph) in
            XCTAssertEqual(["c"], graph.tailTransactions.map({ $0.identifier }))
        }
    }
    
}
