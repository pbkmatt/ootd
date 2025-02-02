import Firebase
import FirebaseAuth
import FirebaseFirestore

class FollowService {
    static let shared = FollowService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    // Follow a user: create a doc in targetUserId's followers subcollection
    func followUser(targetUserId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId != targetUserId else {
            completion(nil)
            return
        }
        
        let followerDoc = db.collection("users")
            .document(targetUserId)
            .collection("followers")
            .document(currentUserId)
        
        followerDoc.setData(["followedAt": Timestamp()]) { error in
            completion(error)
        }
    }
    
    // Unfollow a user: remove that doc
    func unfollowUser(targetUserId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        let followerDoc = db.collection("users")
            .document(targetUserId)
            .collection("followers")
            .document(currentUserId)
        
        followerDoc.delete { error in
            completion(error)
        }
    }
    
    // Check if current user is following
    func isFollowing(targetUserId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let followerDoc = db.collection("users")
            .document(targetUserId)
            .collection("followers")
            .document(currentUserId)
        
        followerDoc.getDocument { snapshot, error in
            if let error = error {
                print("Error checking follow status: \(error)")
                completion(false)
            } else {
                completion(snapshot?.exists == true)
            }
        }
    }
    
    // Return a list of user IDs that the current user (myUid) is following
    // i.e., "myUid" is in their followers subcollection
    func fetchUsersIAmFollowing(completion: @escaping ([String]) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        let db = Firestore.firestore()
        
        // Because we only store a subcollection "followers" under each user,
        // we must scan all user docs to see which ones contain the current user as a follower doc.
        // That's extremely inefficient at scale.
        // A typical approach is to have a "following" subcollection under me as well.
        // But here's a naive approach:
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users for following check: \(error)")
                completion([])
                return
            }
            guard let docs = snapshot?.documents else {
                completion([])
                return
            }
            
            // We'll gather userIDs where subcollection contains doc of currentUserId
            let group = DispatchGroup()
            var followingIds = [String]()
            
            for doc in docs {
                let userId = doc.documentID
                if userId == currentUserId { continue } // skip self
                
                group.enter()
                db.collection("users")
                    .document(userId)
                    .collection("followers")
                    .document(currentUserId)
                    .getDocument { followerSnap, err in
                        if err == nil, followerSnap?.exists == true {
                            // That means I follow this user
                            followingIds.append(userId)
                        }
                        group.leave()
                    }
            }
            
            group.notify(queue: .main) {
                completion(followingIds)
            }
        }
    }
    
    // Return all followers of a given user
    func fetchFollowers(ofUser userId: String, completion: @escaping ([String]) -> Void) {
        db.collection("users")
            .document(userId)
            .collection("followers")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching followers: \(error)")
                    completion([])
                    return
                }
                let followerIds = snapshot?.documents.map { $0.documentID } ?? []
                completion(followerIds)
            }
    }
}
