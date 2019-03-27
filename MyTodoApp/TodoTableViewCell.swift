//
//  TodoTableViewCell.swift
//  MyTodoApp
//
//  Created by Agnieszka Bielatowicz on 26/03/2019.
//  Copyright © 2019 Agnieszka Bielatowicz. All rights reserved.
//

import UIKit

class TodoTableViewCell: UITableViewCell {
    var checked = false
    var todo: Todo?
    var cellIndex: Int?
    @IBOutlet weak var checkmarkButton: UIButton!
    @IBOutlet weak var todoTitleLabel: UILabel!
    
    @IBAction func checkmarkButtonTapped(_ sender: UIButton) {
        if sender.currentBackgroundImage == UIImage(named: "checked"){
            sender.setBackgroundImage(UIImage(named: "unchecked"), for: .normal)
            checked = false
            
        } else if sender.currentBackgroundImage == UIImage(named: "unchecked"){
            sender.setBackgroundImage(UIImage(named: "checked"), for: .normal)
            checked = true
        }
        
        if let cellIndex = cellIndex {
            try! Global.realm!.write {
                Global.realmTodos[cellIndex].completed = checked
            }
            todo = Global.realmTodos[cellIndex]
            HttpRequestHandler.sendPatchRequest(todo!, text: todo!.title)
            if let todosTableViewController = Global.viewController {
                todosTableViewController.tableView.reloadData()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
