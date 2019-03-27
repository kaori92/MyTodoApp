//
//  HttpRequestHandler.swift
//  MyTodoApp
//
//  Created by Agnieszka Bielatowicz on 25/03/2019.
//  Copyright © 2019 Agnieszka Bielatowicz. All rights reserved.
//

import Just
import UIKit
import Alamofire
import ObjectMapper
import RxSwift
import RxAtomic

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
        let parameters = ["revision": sync.todo!.revision]
        let urlForSingleTask = "\(tasksApiUrl)/\(String(describing: sync.todo!.id))"
        
        let response = Just.delete(urlForSingleTask, params: parameters, headers: deleteHeaders)
        if let statusCode = response.statusCode {
            if statusCode == 204 {
                try! Global.realm!.write {
                    Global.realm!.delete(sync.todo!)
                    Global.realmTodos.remove(at: Global.realmTodos.firstIndex(of: sync.todo!)!)
                }
            } else {
                print("ERROR: \(String(describing: response.response))")
            }
        }
    }
    
    class func synchronizedAdd(_ sync: Sync) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let parameters = ["list_id": Global.listId]
        let data = try encoder.encode(sync.todo)
        
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]{
            makePostRequest(parameters, json, sync)
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
                
                try! Global.realm!.write {
                    let result = Global.realm!.objects(List.self)
                    Global.realm!.delete(result)
                }
                
                try! Global.realm!.write {
                    Global.realm!.add(list)
                }
                return listId
                
            }
        } catch let error {
            print("Error getting id of list: \(error)")
        }
        return nil
    }
    
    class func getTasksForListOnline(listId: Int) {
        let parameters = ["list_id": listId]
        let response = Just.get(tasksApiUrl, params: parameters, headers: headers)
        guard let content = response.content  else {return }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: content, options: .mutableContainers)
            if let todosFetched = Mapper<Todo>().mapArray(JSONObject: jsonObject){
                try! Global.realm!.write {
                    for todo in todosFetched {
                        Global.realm!.add(todo, update: true)
                        if !Global.realmTodos.contains(todo){
                            Global.realmTodos.append(todo)
                        }
                    }
                }
            }
            
        } catch let error as NSError {
            print(error)
        }
    }
    
    enum FailureReason: Int, Error {
        case unAuthorized = 401
        case notFound = 404
    }
    
    class func  getTasksForListRx3(listId: Int){
        let parameters = ["list_id": listId]
        let httpCallObservable:Observable<Any> = Observable<Any>.create { sub in
            Alamofire.request(tasksApiUrl, method: HTTPMethod.get, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        sub.onNext(response.result.value!)
                        sub.onCompleted()
                    case .failure(let error):
                        sub.onError(error)
                    }
            }
            
            return Disposables.create()
        }
        
        _ = httpCallObservable.subscribe(
            onNext: { data in print(data) },
            onError: { error in print(error) },
            onCompleted: nil,
            onDisposed: nil
        )
    }
    
    class func getTasksForListRx2(listId: Int){
        let parameters = ["list_id": listId]
        
        let httpCallObservable:Observable<Any> = Observable<Any>.create { sub in
            Just.get(tasksApiUrl, params: parameters, headers: headers, asyncCompletionHandler: { (response: HTTPResult) in
                if response.statusCode == 200 {
                    guard let content = response.content  else {return }
                    do {
                        let jsonObject = try JSONSerialization.jsonObject(with: content, options: .mutableContainers)
                        if let todosFetched = Mapper<Todo>().mapArray(JSONObject: jsonObject){
                            try! Global.realm!.write {
                                for todo in todosFetched {
                                    Global.realm!.add(todo, update: true)
                                    if !Global.realmTodos.contains(todo){
                                        Global.realmTodos.append(todo)
                                    }
                                }
                            }
                        }
                        
                        sub.onNext(content)
                        sub.onCompleted()
                    } catch let error {
                        print(error)
                    }
                    
                } else {
                    if let error = response.error{
                        sub.onError(error)
                    }
                    
                }
            })
            
            return Disposables.create()
        }
        
        _ = httpCallObservable.subscribe(
            onNext: { data in print(data) },
            onError: { error in print(error) },
            onCompleted: nil,
            onDisposed: nil
        )
    }
    
    //    class func getTasksForListRx(listId: Int) -> Observable<[Todo]> {
    //        let parameters = ["list_id": listId]
    //        return Observable.create { observer -> Disposable in
    //            let response = Just.get(tasksApiUrl, params: parameters, headers: headers)
    //            switch response.statusCode {
    //            case 401:
    //                print("error")
    //            case 404:
    //                print("not found")
    //            case 200:
    //                guard let content = response.content else {
    // if no error provided by alamofire return .notFound error instead.
    // .notFound should never happen here?
    //                    observer.onError(response.error ?? GetFriendsFailureReason.notFound)
    //                    return
    //                    print("error")
    //                }
    //                do {
    //                    let jsonObject = try JSONSerialization.jsonObject(with: content, options: .mutableContainers)
    //
    //                    if let todosFetched = Mapper<Todo>().mapArray(JSONObject: jsonObject){
    //                        try! Global.realm!.write {
    //                            for todo in todosFetched {
    //                                Global.realm!.add(todo, update: true)
    //                                if !Global.realmTodos.contains(todo){
    //                                    Global.realmTodos.append(todo)
    //                                }
    //                            }
    //                        }
    //                    }
    //
    ////                    let friends = try JSONDecoder().decode([Friend].self, from: data)
    ////                    observer.onNext(friends)
    //                } catch {
    //                    observer.onError(error)
    //                }
    //            default:
    //                print("")
    //            }
    //
    //
    //            return Disposables.create()
    //        }
    //    }
    
    class func addTask(text: String){
        if let controller = Global.viewController, let listId = controller.getListId(){
            let response = Just.post(tasksApiUrl, data: ["list_id": listId, "title": text], headers: headers)
            if let statusCode = response.statusCode, let content = response.content {
                if statusCode == 201 {
                    let  todoJson = String(decoding:  content, as: UTF8.self)
                    if let todo = Todo(JSONString: todoJson){
                        try! Global.realm!.write {
                            Global.realm!.add(todo)
                        }
                    }
                } else {
                    print("Error adding todo \(response) \(String(describing: response.error))")
                }
            }
        }
    }
    
    class func deleteTask(todo: Todo){
        let parameters = ["revision": todo.revision]
        let urlForSingleTask = "\(tasksApiUrl)/\(String(describing: todo.id))"
        
        let response = Just.delete(urlForSingleTask, params: parameters, headers: deleteHeaders)
        if let statusCode = response.statusCode {
            if statusCode == 204 {
                try! Global.realm!.write {
                    Global.realm!.delete(todo)
                    Global.realmTodos.remove(at: Global.realmTodos.firstIndex(of: todo)!)
                }
            }else{
                print("ERROR: \(String(describing: response.response))")
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
            let jsonEncoder = JSONEncoder()
            do {
                let updatedTodoAsData = try jsonEncoder.encode(currentTodoCopy)
                let parameters = ["revision": currentTodo.revision+1, "list_id": currentTodo.listId as Any]
                let urlForSingleTask = "\(tasksApiUrl)/\(String(describing: currentTodo.id))"
                let response = Just.patch(urlForSingleTask, params: parameters, headers: headers, requestBody: updatedTodoAsData)
                
                if let statusCode = response.statusCode, let todoFromApi = response.content {
                    if statusCode == 200 {
                        let todoJson = String(decoding:  todoFromApi, as: UTF8.self)
                        
                        if let updatedTodo = Todo(JSONString: todoJson){
                            var current = currentTodo
                            
                            if let currentTodoIndex = Global.realmTodos.firstIndex(of: current){
                                try! Global.realm!.write {
                                    current = updatedTodo
                                    Global.realmTodos[currentTodoIndex] = updatedTodo
                                }
                            }
                        }
                    } else {
                        print("ERROR: \(String(describing: response.response))")
                    }
                }
            } catch let error {
                print(error)
            }
        }
    }
    
    class func synchronizedEdit(_ sync: Sync) throws {
        let jsonEncoder = JSONEncoder()
        let updatedTodoAsData = try jsonEncoder.encode(sync.todo)
        let parameters = ["revision": sync.todo!.revision, "list_id": sync.todo!.listId]
        let urlForSingleTask = "\(tasksApiUrl)/\(String(describing: sync.todo!.id))"
        
        let response = Just.patch(urlForSingleTask, params: parameters, headers: headers, requestBody: updatedTodoAsData)
        if let statusCode = response.statusCode, let todoFromApi = response.content {
            if statusCode == 200 {
                let todoJson = String(decoding:  todoFromApi, as: UTF8.self)
                var originalTodo = sync.originalTodo
                if let updatedTodo = Todo(JSONString: todoJson) {
                    if let originalTodoIndex = Global.realmTodos.firstIndex(of: originalTodo!){
                        try! Global.realm!.write {
                            originalTodo = updatedTodo
                            Global.realmTodos[originalTodoIndex] = updatedTodo
                        }
                    }
                }
            } else {
                print("ERROR: \(String(describing: response.response))")
            }
        }
    }
    
    class func makePostRequest(_ parameters: [String : Int], _ json: [String : Any], _ sync: Sync) {
        let response = Just.post(tasksApiUrl, params: parameters, data: json, headers: headers)
        
        if let statusCode = response.statusCode {
            if statusCode != 201 {
                print("Error adding todo \(String(describing: sync.todo)) \(response) \(String(describing: response.error))")
            } else {
                try! Global.realm!.write {
                    Global.realm!.add(sync.todo!, update: true)
                    
                    if !Global.realmTodos.contains(sync.todo!){
                        Global.realmTodos.append(sync.todo!)
                    }
                }
            }
        }
    }
}
