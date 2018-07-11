//
//  Task.swift
//  CheckmarksKit
//
//  Created by Tim Ekl on 7/10/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import UIKit

public class Task: NSObject {
    public private(set) var identifier: String
    public var name: String = "" {
        didSet {
            markUpdated()
        }
    }
    public var completed: Bool = false {
        didSet {
            markUpdated()
        }
    }
    
    private weak var dataStore: DataStore?
    
    init(identifier: String, dataStore: DataStore) {
        self.identifier = identifier
        self.dataStore = dataStore
        super.init()
    }
    
    private func markUpdated() {
        dataStore?.recordChange(to: self)
    }
}
