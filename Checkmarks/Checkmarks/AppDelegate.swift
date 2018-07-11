//
//  AppDelegate.swift
//  Checkmarks
//
//  Created by Tim Ekl on 7/10/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import UIKit
import CheckmarksKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private static let dataStoreURL: URL = {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent("Database").appendingPathExtension("checkmarks")
    }()

    var window: UIWindow?
    
    private(set) var dataStore: DataStore!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let url = AppDelegate.dataStoreURL
        if FileManager.default.fileExists(atPath: url.path) {
            dataStore = try! DataStore(url: url, owner: self)
        } else {
            dataStore = try! DataStore.createDataStore(at: url, owner: self)
        }
        
        ((window?.rootViewController as? UINavigationController)?.topViewController as? TaskListViewController)?.dataStore = dataStore
        
        return true
    }

}

extension AppDelegate: DataStoreOwner {
    func tasksDidUpdate(_ tasks: Set<Task>) {
        // nothing
    }
}

