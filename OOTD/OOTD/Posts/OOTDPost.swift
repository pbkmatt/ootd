import Foundation
import FirebaseFirestore
import FirebaseAuth

struct OOTDPost: Identifiable, Codable {
    @DocumentID var id: String?
    var uid: String            // The user’s ID
    var username: String       // The user’s display name
    var profileImage: String   // The user’s profile image URL
    var caption: String
    var imageURL: String
    var taggedItems: [TaggedItem]  
    var timestamp: Timestamp
    var visibility: String
    var commentsCount: Int
    var favoritesCount: Int
    var closetsCount: Int
}

// MARK: - Comment Model
struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var username: String
    var profileImage: String
    var text: String
    var timestamp: Timestamp
}
