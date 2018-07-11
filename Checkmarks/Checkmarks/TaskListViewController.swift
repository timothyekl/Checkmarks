//
//  TaskListViewController.swift
//  Checkmarks
//
//  Created by Tim Ekl on 7/10/18.
//  Copyright © 2018 Tim Ekl. All rights reserved.
//

import UIKit
import CheckmarksKit

class TaskListViewController: UITableViewController {
    
    weak var dataStore: DataStore? {
        didSet {
            reloadTasks()
        }
    }
    private var tasks: [Task] = []
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadTasks()
    }
    
    // MARK: UITableViewDataSource & UITableViewDelegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = tasks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath)
        cell.textLabel?.text = task.name
        cell.accessoryType = task.completed ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editTask(tasks[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = tasks[indexPath.row]
        let title: String
        if task.completed {
            title = "🚫"
        } else {
            title = "✔️"
        }
        
        let action = UIContextualAction(style: .normal, title: title, handler: { (action, view, completion) in
            task.completed = !task.completed
            try? self.dataStore?.save()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            completion(true)
        })
        
        let configuration = UISwipeActionsConfiguration(actions: [action])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    // MARK: Private
    
    private func reloadTasks() {
        guard let dataStore = dataStore else {
            tasks = []
            return
        }
        
        tasks = (try? dataStore.fetchTasks()) ?? []
        
        if isViewLoaded {
            tableView.reloadData()
        }
    }
    
    @IBAction private func addTask(_ sender: Any) {
        guard let dataStore = dataStore else { return }
        guard let task = try? dataStore.addTask() else { return }
        editTask(task)
    }
    
    private func editTask(_ task: Task) {
        let title = NSLocalizedString("Edit Task", comment: "task editor alert title")
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        var nameTextField: UITextField?
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Name", comment: "task editor alert text field placeholder")
            textField.text = task.name
            nameTextField = textField
        }
        
        let ok = NSLocalizedString("OK", comment: "task editor button label")
        alert.addAction(UIAlertAction(title: ok, style: .default, handler: { [weak self] (action) in
            task.name = nameTextField?.text ?? ""
            
            if let dataStore = self?.dataStore {
                try? dataStore.save()
                self!.reloadTasks()
            }
        }))
        
        let cancel = NSLocalizedString("Cancel", comment: "task editor button label")
        alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: { (action) in
            if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }

}

