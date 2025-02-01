import Foundation
import FirebaseFirestore

struct OOTDPost: Identifiable, Codable {
    @DocumentID var id: String? // ✅ Firestore auto-generated document ID
    var caption: String
    var imageURL: String
    var taggedItems: [OOTDItem] // ✅ Stores full OOTDItem objects
    var timestamp: Timestamp
    var visibility: String // e.g., "public" or "private"
    var commentsCount: Int
    var favoritesCount: Int
    var userID: String
    var username: String // ✅ Avoids extra Firestore calls
    var profileImage: String // ✅ Includes profile image in posts

    func toDict() -> [String: Any] {
        return [
            "caption": caption,
            "imageURL": imageURL,
            "taggedItems": taggedItems.map { $0.toDict() }, // ✅ Convert items to Firestore format
            "timestamp": timestamp,
            "visibility": visibility,
            "commentsCount": commentsCount,
            "favoritesCount": favoritesCount,
            "userID": userID,
            "username": username,
            "profileImage": profileImage
        ]
    }
}

// MARK: - OOTD Item Model
struct OOTDItem: Identifiable, Codable {
    var id = UUID().uuidString
    var title: String
    var link: String

    func toDict() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "link": link
        ]
    }
}

// MARK: - Comment Model
struct Comment: Identifiable, Codable {
    var id: String
    var userId: String // ✅ Allows profile navigation
    var username: String
    var profileImage: String // ✅ Displays user’s profile picture in comments
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
