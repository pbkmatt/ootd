import FirebaseFirestore
import FirebaseAuth

struct UserModel: Identifiable, Codable {
    @DocumentID var id: String?       // Firestore doc ID
    var uid: String                   // The Firebase Auth UID
    var email: String                 // User's email
    var username: String
    var fullName: String
    var bio: String
    var instagramHandle: String
    var profilePictureURL: String
    var followersCount: Int
    var followingCount: Int
    var isPrivateProfile: Bool
    var createdAt: Timestamp?         // Firestore Timestamp for user creation

    // MARK: - Custom Initializer
    init(
        id: String? = nil,
        uid: String = "",
        email: String = "",
        username: String = "",
        fullName: String = "",
        bio: String = "",
        instagramHandle: String = "",
        profilePictureURL: String = "",
        followersCount: Int = 0,
        followingCount: Int = 0,
        isPrivateProfile: Bool = false,
        createdAt: Timestamp? = nil
    ) {
        self.id = id
        self.uid = uid
        self.email = email
        self.username = username
        self.fullName = fullName
        self.bio = bio
        self.instagramHandle = instagramHandle
        self.profilePictureURL = profilePictureURL
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.isPrivateProfile = isPrivateProfile
        self.createdAt = createdAt
    }
}
