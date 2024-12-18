import UIKit

class EditTodoViewController: UIViewController {
    var currentTodo: Todo?
    var parameters: [String:Any] = [:]
    var currentTodoCopy: Todo?
    var checked = false
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var contentTextField: UITextField!
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        if let currentTodo = currentTodo {
            if Reachability.isConnectedToNetwork() {
                HttpRequestHandler.deleteTask(todo: currentTodo)
            } else {
                Global.syncs.insert(Sync(id: Global.lastId, action: Sync.Action.delete, todo: currentTodo))
                Global.lastId += 1
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil);
        let viewController = storyboard.instantiateViewController(withIdentifier: "tableNavigationController") as! UINavigationController;
        self.present(viewController, animated: true, completion: nil);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deleteButton.titleLabel?.numberOfLines = 0
        deleteButton.titleLabel?.adjustsFontSizeToFitWidth = true
        deleteButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentTextField.text = currentTodo?.title
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let currentTodo = currentTodo, segue.identifier == "saveEditedTodoSegue" && contentTextField.text != currentTodo.title {
            
            let todoCopy = Todo(title: currentTodo.title, id: currentTodo.id, completed: checked, listId: currentTodo.listId, revision: currentTodo.revision)
            
            HttpRequestHandler.sendPatchRequest(todoCopy, text: contentTextField.text!)
        }
    }
}
