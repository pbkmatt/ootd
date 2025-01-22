import Foundation

struct UserModel: Identifiable, Codable {
    var id: String
    var username: String
    var bio: String
    var profilePictureURL: String
    var isPrivate: Bool

    init(id: String = UUID().uuidString, username: String, bio: String = "", profilePictureURL: String = "", isPrivate: Bool = false) {
        self.id = id
        self.username = username
        self.bio = bio
        self.profilePictureURL = profilePictureURL
        self.isPrivate = isPrivate
    }
}
