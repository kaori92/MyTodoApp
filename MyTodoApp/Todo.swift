//
//  Todo.swift
//  MyTodoApp
//
//  Created by Agnieszka Bielatowicz on 19/03/2019.
//  Copyright © 2019 Agnieszka Bielatowicz. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift
import Realm

final class Todo: Object, Mappable, Codable {
    
    @objc dynamic var title: String
    @objc dynamic var id: Int
    @objc dynamic var completed: Bool
    @objc dynamic var listId: Int
    @objc dynamic var revision: Int
    
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case id = "id"
        case completed = "completed"
        case revision = "revision"
        case listId = "list_id"
    }
    
    @objc override static func primaryKey() -> String? {
        return "id"
    }
    
    static func == (lhs: Todo, rhs: Todo) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.listId == rhs.listId && lhs.revision == rhs.revision
    }
    
    required init?(map: Map) {
        self.title = ""
        self.id = -1
        self.completed = false
        self.listId = -1
        self.revision = -1
        
        super.init()
    }
    
    required init(title: String, id: Int, completed: Bool, listId: Int, revision: Int) {
        self.title = title
        self.id = id
        self.completed = completed
        self.listId = listId
        self.revision = revision
        
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        self.title = ""
        self.id = -1
        self.completed = false
        self.listId = -1
        self.revision = -1
        
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        self.title = ""
        self.id = -1
        self.completed = false
        self.listId = -1
        self.revision = -1
        
        super.init()
    }
    
    required init() {
        self.title = ""
        self.id = -1
        self.completed = false
        self.listId = -1
        self.revision = -1
        
        super.init()
    }
    
    func mapping(map: Map) {
        title    <- map["title"]
        id    <- map["id"]
        completed    <- map["completed"]
        listId <- map["list_id"]
        revision <- map["revision"]
    }
    
}
