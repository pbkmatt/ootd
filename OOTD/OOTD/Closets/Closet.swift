import FirebaseFirestore

struct Closet: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var createdAt: Timestamp
    var postIds: [String]
    
    init(id: String? = nil,
         name: String,
         ownerId: String,
         createdAt: Timestamp,
         postIds: [String] = []) {
        self.id = id
        self.name = name
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.postIds = postIds
    }
}
