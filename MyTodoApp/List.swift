import Foundation
import ObjectMapper
import RealmSwift
import Realm

class List: Object, Mappable {
    @objc dynamic var listId: Int = 0
    @objc dynamic var revision: Int = 0
    
    init(listId: Int){
        self.listId = listId
        self.revision = 1
        
        super.init()
    }
    
    @objc override static func primaryKey() -> String? {
        return "listId"
    }
    
    required init() {
        super.init()
    }
    
    required init?(map: Map) {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    func mapping(map: Map) {
        listId <- map["id"]
        revision <- map["revision"]
    }
}
