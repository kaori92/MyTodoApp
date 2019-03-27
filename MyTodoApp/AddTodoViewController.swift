//
//  AddTodoViewController.swift
//  MyTodoApp
//
//  Created by Agnieszka Bielatowicz on 19/03/2019.
//  Copyright © 2019 Agnieszka Bielatowicz. All rights reserved.
//

import UIKit

class AddTodoViewController: UIViewController {
    @IBOutlet weak var contentTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "saveTodoSegue"{
            guard let text = contentTextField.text else {return}
            
            if Reachability.isConnectedToNetwork(){
                HttpRequestHandler.addTask(text: text)
            } else {
                    let todo = Todo(title: text, id: Global.lastId, completed: false, listId: Global.listId, revision: 1)
                    Global.syncs.insert(Sync(id: Global.lastId, action: Sync.Action.add, todo: todo))
                    Global.lastId += 1
            }
        }
    }
}
