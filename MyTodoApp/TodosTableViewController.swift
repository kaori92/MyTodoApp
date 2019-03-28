//
//  TodosTableViewController.swift
//  MyTodoApp
//
//  Created by Agnieszka Bielatowicz on 19/03/2019.
//  Copyright © 2019 Agnieszka Bielatowicz. All rights reserved.
//

import UIKit
import RealmSwift

class Global {
    static var realm: Realm? = nil
    static var realmTodos = [Todo]()
    static var lastId = 0
    static var syncs = Set<Sync>()
    static var viewController: TodosTableViewController?
    static var listId = -1
}

class TodosTableViewController: UITableViewController {
    var timer = Timer()
    
    required init?(coder aDecoder: NSCoder) {
        do {
            Global.realm = try Realm()
        }
        catch let error {
            print(error)
        }
        super.init(coder: aDecoder)
        Global.viewController = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
        
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.synchronizeTodos), userInfo: nil, repeats: true)
        if let listId = getListId(){
            try! Global.realm!.write {
                let list = List(listId: listId)
                Global.realm!.add(list, update: true)
                Global.listId = listId
            }
            
            getTasksForList(listId: listId)
        } else if(Global.realmTodos.isEmpty){
            Global.syncs.insert(Sync(id: Global.lastId, action: Sync.Action.get, todo: nil))
            Global.lastId += 1
            
            if !isOnline() {
                let alert = UIAlertController(title: "No Internet connection", message: "Check your Internet connection", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func getListId() -> Int? {
        let listsArray = Array(Global.realm!.objects(List.self))
        
        if listsArray.isEmpty || allIdsNegative(listsArray: listsArray){
            
            if isOnline() {
                return HttpRequestHandler.getListIdIfNoListSaved() ?? nil
            }
        } else {
            return getListIdFromDb() ?? nil
        }
        return nil
    }
    
    func allIdsNegative(listsArray: Array<List>) -> Bool{
        var idsNegative = true;
        for element in listsArray {
            if element.listId > 0 {
                idsNegative = false
            }
        }
        
        return idsNegative
    }
    
    func getListIdFromDb() -> Int? {
        let savedLists = Array(Global.realm!.objects(List.self))
        if !savedLists.isEmpty {
            return savedLists[0].listId
        }
        return nil
    }
    
    @objc func synchronizeTodos(){
        var visibleViewController: UIViewController?
        if let wd = UIApplication.shared.delegate?.window {
            visibleViewController = wd!.rootViewController
            if(visibleViewController is UINavigationController){
                visibleViewController = (visibleViewController as! UINavigationController).visibleViewController
            }
        }
        
        if(visibleViewController is TodosTableViewController || visibleViewController is UIAlertController && isOnline() && !Global.syncs.isEmpty){
            for sync in Global.syncs {
                synchronize(sync: sync)
                Global.syncs.remove(sync)
            }
        }
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    func synchronize(sync: Sync){
        switch(sync.action){
        case Sync.Action.add:
            do {
                try HttpRequestHandler.synchronizedAdd(sync)
            } catch let error {
                print(error)
            }
            
        case Sync.Action.edit:
             HttpRequestHandler.syncEdit(sync)
            
        case Sync.Action.delete:
            do {
                try HttpRequestHandler.synchronizedDelete(sync)
            } catch let error {
                print(error)
            }
        case Sync.Action.get:
            if let listId = getListId(){
                getTasksForList(listId: listId)
            }
        }
        
         if let listId = getListId(){
            getTasksForList(listId: listId)
        }
    }
    
    func isOnline() -> Bool{
        return Reachability.isConnectedToNetwork()
    }
    
    func getTasksForList(listId: Int){
        if isOnline() {
            HttpRequestHandler.getTasksForListOnline(listId: listId)
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Global.realmTodos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath) as! TodoTableViewCell
        
        cell.todoTitleLabel!.text = Global.realmTodos[indexPath.row].title
        cell.cellIndex = indexPath.row
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath) as! TodoTableViewCell
        
        cell.todo =  Global.realmTodos[indexPath.row]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editTodoSegue" {
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController  as! EditTodoViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                targetController.currentTodo = Global.realmTodos[indexPath.row]
            }
            
            let cell = sender as! TodoTableViewCell
            targetController.checked = cell.checked
        }
    }
}

