import Just
import UIKit
import Alamofire
import ObjectMapper
import RxSwift

class HttpRequestHandler {
    static let clientId = "07820a0dd3022d18af52"
    static let accessToken = "2b3083896e70f8ac1a004ae4961449589ee1e5746bdc269f4bad9b520144"
    static let headers: HTTPHeaders = [
        "X-Access-Token": accessToken,
        "X-Client-ID": clientId,
        "Content-Type": "application/json"
    ]
    static let deleteHeaders: HTTPHeaders = [
        "X-Access-Token": accessToken,
        "X-Client-ID": clientId,
    ]
    static let tasksApiUrl = "http://a.wunderlist.com/api/v1/tasks"
    static let listsApiUrl = "http://a.wunderlist.com/api/v1/lists"
    
    class func synchronizedDelete(_ sync: Sync) throws {
        let httpCallObservable:Observable<Any> = Observable<Any>.create { subscribe in
            syncDelete(subscribe, sync)
            
            return Disposables.create()
        }
        
        _ = httpCallObservable.subscribe(
            onNext: nil,
            onError: { error in print(error) },
            onCompleted: nil,
            onDisposed: nil
        )
    }
    
    class func syncDelete( _ subscribe: (AnyObserver<Any>), _ sync: Sync){
        let parameters = ["revision": sync.todo!.revision]
        let urlForSingleTask = "\(tasksApiUrl)/\(String(describing: sync.todo!.id))"
        
        let response = Just.delete(urlForSingleTask, params: parameters, headers: deleteHeaders)
        if let statusCode = response.statusCode {
            if statusCode == 204 {
                DispatchQueue.main.async() {
                    try! Global.realm!.write {
                        Global.realm!.delete(sync.todo!)
                        Global.realmTodos.remove(at: Global.realmTodos.firstIndex(of: sync.todo!)!)
                    }
                }
                
                subscribe.onCompleted()
            } else if let error = response.error{
                subscribe.onError(error)
            }
        }
    }
    
    class func synchronizedAdd(_ sync: Sync) throws {
        let httpCallObservable:Observable<Any> = Observable<Any>.create { subscribe in
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let parameters = ["list_id": Global.listId]
            do {
                let data = try encoder.encode(sync.todo)
                
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]{
                    makePostRequest(subscribe, parameters, json, sync)
                }
            } catch {
                print(error)
            }
            
            return Disposables.create()
        }
        
        _ = httpCallObservable.subscribe(
            onNext: nil,
            onError: { error in print(error) },
            onCompleted: nil,
            onDisposed: nil
        )
        
    }
    
    class func makePostRequest(_ subscribe: (AnyObserver<Any>), _ parameters: [String : Int], _ json: [String : Any], _ sync: Sync) {
        let response = Just.post(tasksApiUrl, params: parameters, data: json, headers: headers)
        
        if let statusCode = response.statusCode {
            if statusCode == 201 {
                let content = response.content
                
                DispatchQueue.main.async() {
                    try! Global.realm!.write {
                        Global.realm!.add(sync.todo!, update: true)
                        
                        if !Global.realmTodos.contains(sync.todo!){
                            Global.realmTodos.append(sync.todo!)
                        }
                    }
                }
                subscribe.onNext(content as Any)
                subscribe.onCompleted()
            } else if let error = response.error{
                subscribe.onError(error)
            }
        }
    }
    
    class func getListIdIfNoListSaved() -> Int? {
        let getHeaders: HTTPHeaders = [
            "X-Access-Token": accessToken,
            "X-Client-ID": clientId
        ]
        
        let response = Just.get(listsApiUrl, headers: getHeaders)
        guard let content = response.content  else {return nil }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: content, options: .mutableContainers)
            
            if let lists = Mapper<List>().mapArray(JSONObject: jsonObject){
                let listId = lists[0].listId
                let list = List(listId: listId)
                
                DispatchQueue.main.async() {
                    try! Global.realm!.write {
                        let result = Global.realm!.objects(List.self)
                        Global.realm!.delete(result)
                    }
                    
                    try! Global.realm!.write {
                        Global.realm!.add(list)
                    }
                }
                
                return listId
                
            }
        } catch let error {
            print("Error getting id of list: \(error)")
        }
        return nil
    }
    
    class func getTasksForList(listId: Int) {
        let httpCallObservable:Observable<Any> = Observable<Any>.create { subscribe in
            if let controller = Global.viewController, let listId = controller.getListId(){
                _ = getTasksForListApiCall(subscribe, listId: listId)
            }
            
            return Disposables.create()
        }
        
        _ = httpCallObservable.subscribe(
            onNext: nil,
            onError: { error in print(error) },
            onCompleted: nil,
            onDisposed: nil
        )
    }
    
    class func getTasksForListApiCall( _ subscribe: (AnyObserver<Any>), listId: Int){
        let parameters = ["list_id": listId]
        Just.get(tasksApiUrl, params: parameters, headers: headers) {response in
            guard let content = response.content  else {return }
            if response.statusCode == 200 {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: content, options: .mutableContainers)
                    if let todosFetched = Mapper<Todo>().mapArray(JSONObject: jsonObject){
                        DispatchQueue.main.async() {
                            try! Global.realm!.write {
                                for todo in todosFetched {
                                    Global.realm!.add(todo, update: true)
                                    if !Global.realmTodos.contains(where: { (localTodo) -> Bool in
                                        localTodo.title == todo.title && localTodo.listId == todo.listId
                                    }){
                                        Global.realmTodos.append(todo)
                                    }
                                }
                            }
                        }
                    }
                    
                    subscribe.onNext(content)
                    subscribe.onCompleted()
                    
                } catch let error as NSError {
                    print(error)
                }
            } else if let error = response.error{
                subscribe.onError(error)
            }
        }
    }
    
    class func addTask(text: String){
        let httpCallObservable:Observable<Any> = Observable<Any>.create { subscribe in
            if let controller = Global.viewController, let listId = controller.getListId(){
                _ = addTaskApiCall(text: text, listId, subscribe)
            }
            
            return Disposables.create()
        }
        
        _ = httpCallObservable.subscribe(
            onNext: nil,
            onError: { error in print(error) },
            onCompleted: nil,
            onDisposed: nil
        )
    }
    
    class func addTaskApiCall(text: String, _ listId: Int, _ subscribe: (AnyObserver<Any>)) -> HTTPResult {
        return Just.post(tasksApiUrl, data: ["list_id": listId, "title": text], headers: headers) { (response: HTTPResult) in
            if let statusCode = response.statusCode, let content = response.content {
                if statusCode == 201 {
                    DispatchQueue.main.async() {
                        let  todoJson = String(decoding:  content, as: UTF8.self)
                        if let todo = Todo(JSONString: todoJson){
                            try! Global.realm!.write {
                                Global.realm!.add(todo, update: true)
                            }
                            Global.viewController?.tableView.reloadData()
                        }
                        
                        subscribe.onNext(content)
                        subscribe.onCompleted()
                    }
                } else if let error = response.error{
                    subscribe.onError(error)
                }
            }
        }
    }
    
    class func deleteTask(todo: Todo){
        let httpCallObservable:Observable<Any> = Observable<Any>.create { subscribe in
            _ = deleteTaskApiCall(subscribe, todo: todo)
            
            return Disposables.create()
        }
        
        _ = httpCallObservable.subscribe(
            onNext: nil,
            onError: { error in print(error) },
            onCompleted: nil,
            onDisposed: nil
        )
    }
    
    class func deleteTaskApiCall(_ subscribe: (AnyObserver<Any>), todo: Todo){
        let parameters = ["revision": todo.revision]
        let urlForSingleTask = "\(tasksApiUrl)/\(String(describing: todo.id))"
        
        Just.delete(urlForSingleTask, params: parameters, headers: deleteHeaders){ (response: HTTPResult) in
            
            if let statusCode = response.statusCode {
                if statusCode == 204 {
                    DispatchQueue.main.async() {
                        try! Global.realm!.write {
                            Global.realm!.delete(todo)
                            Global.realmTodos.remove(at: Global.realmTodos.firstIndex(of: todo)!)
                        }
                        Global.viewController?.tableView.reloadData()
                        let content = response.content
                        
                        subscribe.onNext(content as Any)
                        subscribe.onCompleted()
                    }
                } else if let error = response.error{
                    subscribe.onError(error)
                }
            }
        }
    }
    
    class func sendPatchRequest(_ currentTodo: Todo, text: String) {
        let currentTodoCopy = Todo(title: (currentTodo.title), id: (currentTodo.id), completed: (currentTodo.completed), listId: (currentTodo.listId), revision: (currentTodo.revision))
        currentTodoCopy.title = text
        
        if !Reachability.isConnectedToNetwork(){
            Global.syncs.insert(Sync(id: Global.lastId, action: Sync.Action.edit, todo: currentTodoCopy, originalTodo: currentTodo))
            Global.lastId += 1
        } else {
            let httpCallObservable:Observable<Any> = Observable<Any>.create { subscribe in
                patchTaskApiCall(subscribe, currentTodo, currentTodoCopy: currentTodoCopy)
                return Disposables.create()
            }
            
            _ = httpCallObservable.subscribe(
                onNext: nil,
                onError: { error in print(error) },
                onCompleted: nil,
                onDisposed: nil
            )
        }
    }
    
    class func patchTaskApiCall(_ subscribe: (AnyObserver<Any>), _ currentTodo: Todo, currentTodoCopy: Todo){
        do {
            let jsonEncoder = JSONEncoder()
            let updatedTodoAsData = try jsonEncoder.encode(currentTodoCopy)
            let parameters = ["revision": currentTodo.revision+1, "list_id": currentTodo.listId as Any]
            let urlForSingleTask = "\(tasksApiUrl)/\(String(describing: currentTodo.id))"
            
            Just.patch(urlForSingleTask, params: parameters, headers: headers, requestBody: updatedTodoAsData, asyncCompletionHandler: { (response: HTTPResult) in
                
                if let statusCode = response.statusCode, let todoFromApi = response.content {
                    if statusCode == 200 {
                        let todoJson = String(decoding:  todoFromApi, as: UTF8.self)
                        
                        if let updatedTodo = Todo(JSONString: todoJson){
                            var current = currentTodo
                            
                            DispatchQueue.main.async() {
                                if let currentTodoIndex = Global.realmTodos.firstIndex(of: current){
                                    try! Global.realm!.write {
                                        current = updatedTodo
                                        Global.realmTodos[currentTodoIndex] = updatedTodo
                                    }
                                    Global.viewController?.tableView.reloadData()
                                }
                            }
                        }
                        
                        let content = response.content
                        
                        subscribe.onNext(content as Any)
                        subscribe.onCompleted()
                    } else if let error = response.error{
                        subscribe.onError(error)
                    }
                }
            })
            
        } catch {
            print("EncodingError for todo: ", currentTodoCopy, error)
        }
    }
    
    class func syncEdit(_ sync: Sync){
        let httpCallObservable:Observable<Any> = Observable<Any>.create { subscribe in
            synchronizedEdit(subscribe, sync)
            return Disposables.create()
        }
        
        _ = httpCallObservable.subscribe(
            onNext: nil,
            onError: { error in print(error) },
            onCompleted: nil,
            onDisposed: nil
        )
    }
    
    class func synchronizedEdit(_ subscribe: (AnyObserver<Any>), _ sync: Sync) {
        let jsonEncoder = JSONEncoder()
        var updatedTodoAsData = Data()
        do {
            updatedTodoAsData = try jsonEncoder.encode(sync.todo)
        } catch {
            print("Encoding error for todo: ", sync.todo as Any, error)
            return
        }
        
        let parameters = ["revision": sync.todo!.revision, "list_id": sync.todo!.listId]
        let urlForSingleTask = "\(tasksApiUrl)/\(String(describing: sync.todo!.id))"
        
        Just.patch(urlForSingleTask, params: parameters, headers: headers, requestBody: updatedTodoAsData, asyncCompletionHandler: { (response: HTTPResult) in
            if let statusCode = response.statusCode, let todoFromApi = response.content  {
                if statusCode == 200 {
                    let todoJson = String(decoding:  todoFromApi, as: UTF8.self)
                    var originalTodo = sync.originalTodo
                    if let updatedTodo = Todo(JSONString: todoJson) {
                        DispatchQueue.main.async() {
                            if let originalTodoIndex = Global.realmTodos.firstIndex(of: originalTodo!){
                                try! Global.realm!.write {
                                    originalTodo = updatedTodo
                                    Global.realmTodos[originalTodoIndex] = updatedTodo
                                }
                            }
                        }
                    }
                    
                    subscribe.onNext(todoFromApi as Any)
                    subscribe.onCompleted()
                } else if let error = response.error{
                    subscribe.onError(error)
                }
            }
        })
    }
}

