import Firebase
import FirebaseAuth
import FirebaseFirestore

class FollowService {
    static let shared = FollowService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Follow a user
    func followUser(targetUserId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId != targetUserId else {
            completion(nil)
            return
        }

        // 1) Add doc in "targetUserId/followers/currentUserId"
        db.collection("users")
            .document(targetUserId)
            .collection("followers")
            .document(currentUserId)
            .setData(["followedAt": FieldValue.serverTimestamp()]) { error in

                if let error = error {
                    completion(error)
                    return
                }
                // 2) Add doc in "currentUserId/following/targetUserId"
                self.db.collection("users")
                    .document(currentUserId)
                    .collection("following")
                    .document(targetUserId)
                    .setData(["followedAt": FieldValue.serverTimestamp()]) { err2 in

                        if let err2 = err2 {
                            completion(err2)
                            return
                        }
                        // 3) Increment counters
                        self.incrementFollowCounts(targetUserId: targetUserId,
                                                   currentUserId: currentUserId) { err3 in
                            completion(err3)
                        }
                    }
            }
    }

    // MARK: - Unfollow a user
    func unfollowUser(targetUserId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }

        // 1) Remove doc in "targetUserId/followers/currentUserId"
        db.collection("users")
            .document(targetUserId)
            .collection("followers")
            .document(currentUserId)
            .delete { error in

                if let error = error {
                    completion(error)
                    return
                }
                // 2) Remove doc in "currentUserId/following/targetUserId"
                self.db.collection("users")
                    .document(currentUserId)
                    .collection("following")
                    .document(targetUserId)
                    .delete { err2 in

                        if let err2 = err2 {
                            completion(err2)
                            return
                        }
                        // 3) Decrement counters
                        self.decrementFollowCounts(targetUserId: targetUserId,
                                                   currentUserId: currentUserId) { err3 in
                            completion(err3)
                        }
                    }
            }
    }

    // MARK: - Check if current user is following target
    func isFollowing(targetUserId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        db.collection("users")
            .document(currentUserId)
            .collection("following")
            .document(targetUserId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error checking follow status: \(error)")
                    completion(false)
                } else {
                    completion(snapshot?.exists == true)
                }
            }
    }

    // MARK: - Fetch who I am following
    func fetchFollowing(currentUserId: String, completion: @escaping ([String]) -> Void) {
        db.collection("users")
            .document(currentUserId)
            .collection("following")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching following: \(error)")
                    completion([])
                    return
                }
                let userIds = snapshot?.documents.map { $0.documentID } ?? []
                completion(userIds)
            }
    }

    // MARK: - Fetch my followers
    func fetchFollowers(forUserId userId: String, completion: @escaping ([String]) -> Void) {
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

    // MARK: - Private Helpers
    private func incrementFollowCounts(targetUserId: String,
                                       currentUserId: String,
                                       completion: @escaping (Error?) -> Void) {
        let batch = db.batch()

        let targetRef = db.collection("users").document(targetUserId)
        batch.updateData(["followersCount": FieldValue.increment(Int64(1))], forDocument: targetRef)

        let currentRef = db.collection("users").document(currentUserId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: currentRef)

        batch.commit(completion: completion)
    }

    private func decrementFollowCounts(targetUserId: String,
                                       currentUserId: String,
                                       completion: @escaping (Error?) -> Void) {
        let batch = db.batch()

        let targetRef = db.collection("users").document(targetUserId)
        batch.updateData(["followersCount": FieldValue.increment(Int64(-1))], forDocument: targetRef)

        let currentRef = db.collection("users").document(currentUserId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: currentRef)

        batch.commit(completion: completion)
    }
}
