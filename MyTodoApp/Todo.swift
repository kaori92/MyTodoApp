import Foundation
import ObjectMapper
import RealmSwift
import Realm

final class Todo: Object, Mappable, Codable {
    
    @objc dynamic var title: String = ""
    @objc dynamic var id: Int = 0
    @objc dynamic var completed: Bool = false
    @objc dynamic var listId: Int = 0
    @objc dynamic var revision: Int = 0
    
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
    
    init?(map: Map) {
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    init(title: String, id: Int, completed: Bool, listId: Int, revision: Int) {
        self.title = title
        self.id = id
        self.completed = completed
        self.listId = listId
        self.revision = revision
        
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
