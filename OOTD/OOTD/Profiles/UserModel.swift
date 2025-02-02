import FirebaseAuth
import FirebaseFirestore

struct UserModel: Identifiable, Codable {
    @DocumentID var id: String?
    
    var uid: String
    var username: String
    var bio: String
    var profilePictureURL: String
    var isPrivate: Bool
    var instagramHandle: String
    var followersCount: Int
    var followingCount: Int
    var fullName: String
    
    init(
        id: String? = nil,
        uid: String = "",
        username: String,
        bio: String = "",
        profilePictureURL: String = "",
        isPrivate: Bool = false,
        instagramHandle: String = "",
        followersCount: Int = 0,
        followingCount: Int = 0,
        fullName: String = ""
        
    ) {
        self.id = id
        self.uid = uid
        self.username = username
        self.bio = bio
        self.profilePictureURL = profilePictureURL
        self.isPrivate = isPrivate
        self.instagramHandle = instagramHandle
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.fullName = fullName
    }
}
