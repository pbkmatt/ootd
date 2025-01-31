import Foundation
import FirebaseFirestore

struct OOTDPost: Identifiable, Decodable {
    @DocumentID var id: String?
    var caption: String
    var imageURL: String
    var taggedItems: [OOTDItem] // Now stores full OOTDItem objects
    var timestamp: Timestamp
    var visibility: String // e.g., "public" or "private"
    var commentsCount: Int
    var favoritesCount: Int
    var userID: String
    var username: String // Added: So we don’t need extra Firestore calls
    var profileImage: String // Added: So we can display user’s profile picture in posts
}

struct OOTDItem: Identifiable, Codable {
    var id = UUID().uuidString
    var title: String
    var link: String
}

struct Comment: Identifiable, Codable {
    var id: String
    var userId: String // Added: So we can navigate to profiles
    var username: String
    var profileImage: String // Added: So comments show profile pictures
    var text: String
    var timestamp: Timestamp

    func toDict() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "username": username,
            "profileImage": profileImage,
            "text": text,
            "timestamp": timestamp
        ]
    }
}
