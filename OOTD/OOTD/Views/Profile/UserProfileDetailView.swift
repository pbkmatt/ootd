//
//  UserProfileDetailView.swift
//  OOTD
//
//  Created by Matt Imhof on 1/22/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfileDetailView: View {
    let user: UserModel
    @State private var posts: [OOTDPost] = []
    @State private var todaysOOTD: OOTDPost? = nil
    @State private var isFollowing: Bool = false
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profile Header
                ProfileHeader(
                    user: user,
                    isFollowing: $isFollowing,
                    onFollow: followUser,
                    onUnfollow: unfollowUser
                )

                // Today's OOTD
                if let todaysOOTD = todaysOOTD {
                    todaysOOTDSection(todaysOOTD)
                }

                // User's Posts
                PostGrid(posts: posts)
            }
            .padding()
        }
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkIfFollowing()
            fetchUserPosts()
        }
    }

    // MARK: - Fetch User Posts
    private func fetchUserPosts() {
        let db = Firestore.firestore()
        db.collection("users").document(user.id).collection("posts")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error.localizedDescription)")
                    return
                }

                if let snapshot = snapshot {
                    let allPosts = snapshot.documents.compactMap { doc -> OOTDPost? in
                        try? doc.data(as: OOTDPost.self)
                    }
                    self.posts = allPosts
                    self.todaysOOTD = allPosts.first(where: { Calendar.current.isDateInToday($0.timestamp.dateValue()) })
                }
            }
    }

    // MARK: - Check If Following
    private func checkIfFollowing() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        FollowingSystemEngine.shared.isFollowing(currentUserId: currentUserId, targetUserId: user.id) { result in
            switch result {
            case .success(let followingStatus):
                DispatchQueue.main.async {
                    self.isFollowing = followingStatus
                }
            case .failure(let error):
                print("Error checking follow status: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Follow User
    private func followUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        FollowingSystemEngine.shared.followUser(currentUserId: currentUserId, targetUserId: user.id) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.isFollowing = true
                }
            case .failure(let error):
                print("Error following user: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Unfollow User
    private func unfollowUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        FollowingSystemEngine.shared.unfollowUser(currentUserId: currentUserId, targetUserId: user.id) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.isFollowing = false
                }
            case .failure(let error):
                print("Error unfollowing user: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Today's OOTD Section
    private func todaysOOTDSection(_ post: OOTDPost) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's OOTD")
                .font(Font.custom("BebasNeue-Regular", size: 18))

            NavigationLink(destination: PostDetailView(post: post)) {
                AsyncImage(url: URL(string: post.imageURL ?? "")) { image in
                    image.resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                } placeholder: {
                    Color.gray
                        .frame(height: 300)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct ProfileHeader: View {
    let user: UserModel
    @Binding var isFollowing: Bool
    let onFollow: () -> Void
    let onUnfollow: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture
            if let url = URL(string: user.profilePictureURL), !user.profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2))
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
            }
            
            // Username and Bio
            Text(user.username)
                .font(Font.custom("BebasNeue-Regular", size: 20))
            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(Font.custom("OpenSans", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Follow/Unfollow Button
            Button(action: {
                isFollowing ? onUnfollow() : onFollow()
            }) {
                Text(isFollowing ? "Unfollow" : "Follow")
                    .font(Font.custom("BebasNeue-Regular", size: 16))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFollowing ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
}

