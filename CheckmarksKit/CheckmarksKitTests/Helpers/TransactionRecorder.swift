//
//  TransactionRecorder.swift
//  CheckmarksKitTests
//
//  Created by Tim Ekl on 7/12/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import XCTest
@testable import CheckmarksKit

enum TransactionRecordingError: Error {
    case invalidURL
    case cannotReadFile
    case noSuchGroup
}

class TransactionRecorder {
    
    private struct TransactionGroup {
        var contents: [String: Data]
    }
    
    private var groups: [String: TransactionGroup]
    
    private var seenFileNames: Set<String> {
        return groups.reduce(Set<String>(), { (allNames, pair) -> Set<String> in
            let groupNames: [String] = Array(pair.value.contents.keys)
            return allNames.union(groupNames)
        })
    }
    
    init() {
        self.groups = [:]
    }
    
    func captureGroup(named name: String, from dataStore: DataStore) throws {
        let filePaths = try FileManager.default.contentsOfDirectory(atPath: dataStore.url.path)
        let fileURLs = filePaths.map({ dataStore.url.appendingPathComponent($0) })
        let files: [String: URL] = Dictionary(uniqueKeysWithValues: fileURLs.map({ ($0.lastPathComponent, $0) }))
        
        let contents: [String: Data] = Dictionary(uniqueKeysWithValues: try files.compactMap({ (fileName, fileURL) -> (String, Data)? in
            guard !seenFileNames.contains(fileName) else { return nil }
            guard let data = FileManager.default.contents(atPath: fileURL.path) else { throw TransactionRecordingError.cannotReadFile }
            return (fileName, data)
        }))
        let group = TransactionGroup(contents: contents)
        groups[name] = group
    }
    
    func replayGroup(named name: String, into dataStore: DataStore) throws {
        guard let group = groups[name] else { throw TransactionRecordingError.noSuchGroup }
        try group.contents.forEach { (fileName, fileData) in
            let fileURL = dataStore.url.appendingPathComponent(fileName)
            try fileData.write(to: fileURL)
        }
        try dataStore.incorporateTransactions()
    }
    
}
