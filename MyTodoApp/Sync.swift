import Foundation

struct Sync: Hashable {
    var id: Int
    var action: Action
    var todo: Todo?
    var originalTodo: Todo?
    
    public enum Action {
        case add, edit, delete, get
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(id: Int, action: Action, todo: Todo?){
        self.id = id
        self.action = action
        self.todo = todo
    }
    
    init(id: Int, action: Action, todo: Todo, originalTodo: Todo){
        self.id = id
        self.action = action
        self.todo = todo
        self.originalTodo = originalTodo
    }
}
