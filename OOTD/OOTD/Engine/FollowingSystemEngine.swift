//
//  FollowingSystemEngine.swift
//  OOTD
//
//  Created by Matt Imhof on 1/22/25.
//  Following system engine. In future docs, refer here


import Firebase
import FirebaseFirestore

class FollowingSystemEngine {
    static let shared = FollowingSystemEngine()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Follow a User
    func followUser(currentUserId: String, targetUserId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let currentUserFollowingRef = db.collection("users").document(currentUserId).collection("following").document(targetUserId)
        let targetUserFollowersRef = db.collection("users").document(targetUserId).collection("followers").document(currentUserId)

        let batch = db.batch()
        batch.setData([:], forDocument: currentUserFollowingRef)
        batch.setData([:], forDocument: targetUserFollowersRef)

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Unfollow a User
    func unfollowUser(currentUserId: String, targetUserId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let currentUserFollowingRef = db.collection("users").document(currentUserId).collection("following").document(targetUserId)
        let targetUserFollowersRef = db.collection("users").document(targetUserId).collection("followers").document(currentUserId)

        let batch = db.batch()
        batch.deleteDocument(currentUserFollowingRef)
        batch.deleteDocument(targetUserFollowersRef)

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Retrieve Following List
    func fetchFollowing(userId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let followingRef = db.collection("users").document(userId).collection("following")

        followingRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let followedUserIds = snapshot?.documents.map { $0.documentID } ?? []
                completion(.success(followedUserIds))
            }
        }
    }

    // MARK: - Retrieve Followers List
    func fetchFollowers(userId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let followersRef = db.collection("users").document(userId).collection("followers")

        followersRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let followerUserIds = snapshot?.documents.map { $0.documentID } ?? []
                completion(.success(followerUserIds))
            }
        }
    }

    // MARK: - Check If Following
    func isFollowing(currentUserId: String, targetUserId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let followingRef = db.collection("users").document(currentUserId).collection("following").document(targetUserId)

        followingRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(document?.exists ?? false))
            }
        }
    }
}
