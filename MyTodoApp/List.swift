//
//  List.swift
//  MyTodoApp
//
//  Created by Agnieszka Bielatowicz on 20/03/2019.
//  Copyright © 2019 Agnieszka Bielatowicz. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift
import Realm

class List: Object, Mappable {
    @objc dynamic var listId: Int
    @objc dynamic var revision: Int
    
    init(listId: Int){
        self.listId = listId
        self.revision = 1
        
        super.init()
    }
    
    @objc override static func primaryKey() -> String? {
        return "listId"
    }
    
    required init() {
        self.listId = -1
        self.revision = -1
        
        super.init()
    }
    
    required init?(map: Map) {
        self.listId = -1
        self.revision = -1
        
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        self.listId = -1
        self.revision = -1
        
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        self.listId = -1
        self.revision = -1
        
        super.init()
    }
    
    func mapping(map: Map) {
        listId <- map["id"]
        revision <- map["revision"]
    }
}
