import Foundation
import FirebaseFirestore

struct UserModel: Identifiable, Codable {
    @DocumentID var id: String? // Firestore document ID (optional)
    var username: String
    var bio: String
    var profilePictureURL: String
    var isPrivate: Bool
    var instagramHandle: String // Now correctly declared

    init(
        id: String? = nil,
        username: String,
        bio: String = "",
        profilePictureURL: String = "",
        isPrivate: Bool = false,
        instagramHandle: String = ""
    ) {
        self.id = id
        self.username = username
        self.bio = bio
        self.profilePictureURL = profilePictureURL
        self.isPrivate = isPrivate
        self.instagramHandle = instagramHandle
    }
}
