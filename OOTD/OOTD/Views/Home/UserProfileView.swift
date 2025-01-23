import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    @State private var username: String = ""
    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var profilePictureURL: String = ""
    @State private var posts: [OOTDPost] = []
    @State private var todaysOOTD: OOTDPost?
    @State private var followersCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var isLoading: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading profile...")
                } else {
                    profileHeader
                    statsAndBio
                    if let todaysOOTD = todaysOOTD {
                        todaysOOTDSection(todaysOOTD)
                    }
                    postGrid
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(username.isEmpty ? "Profile" : "@\(username)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchUserProfile()
            fetchUserPosts()
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            if let url = URL(string: profilePictureURL), !profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2))
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
            }

            Text(fullName.isEmpty ? "No Full Name" : fullName)
                .font(Font.custom("YourFont-Bold", size: 20))

            Text(username.isEmpty ? "@username" : "@\(username)")
                .font(Font.custom("YourFont-Regular", size: 16))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Stats and Bio
    private var statsAndBio: some View {
        VStack(spacing: 12) {
            HStack(spacing: 40) {
                VStack {
                    Text("\(followersCount)")
                        .font(Font.custom("YourFont-Bold", size: 18))
                    Text("Followers")
                        .font(Font.custom("YourFont-Regular", size: 14))
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(followingCount)")
                        .font(Font.custom("YourFont-Bold", size: 18))
                    Text("Following")
                        .font(Font.custom("YourFont-Regular", size: 14))
                        .foregroundColor(.secondary)
                }
            }

            if !bio.isEmpty {
                Text(bio)
                    .font(Font.custom("YourFont-Regular", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Today's OOTD Section
    private func todaysOOTDSection(_ post: OOTDPost) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's OOTD")
                .font(Font.custom("YourFont-Bold", size: 18))

            NavigationLink(destination: PostView(post: post)) {
                AsyncImage(url: URL(string: post.imageURL)) { image in
                    image.resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                } placeholder: {
                    Color.gray
                        .frame(height: 300)
                        .cornerRadius(10)
                }
                .frame(maxHeight: 300)
            }
        }
    }

    // MARK: - Post Grid
    private var postGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(posts) { post in
                NavigationLink(destination: PostView(post: post)) {
                    AsyncImage(url: URL(string: post.imageURL)) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width / 2 - 20, height: UIScreen.main.bounds.width / 2 - 20)
                            .cornerRadius(10)
                    } placeholder: {
                        Color.gray
                            .frame(width: UIScreen.main.bounds.width / 2 - 20, height: UIScreen.main.bounds.width / 2 - 20)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }

    // MARK: - Fetch User Profile
    private func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            if let document = document, let data = document.data() {
                username = data["username"] as? String ?? "No Username"
                fullName = data["fullName"] as? String ?? "No Full Name"
                bio = data["bio"] as? String ?? ""
                profilePictureURL = data["profilePictureURL"] as? String ?? ""
                followersCount = data["followersCount"] as? Int ?? 0
                followingCount = data["followingCount"] as? Int ?? 0
            }
        }
    }

    // MARK: - Fetch User Posts
    private func fetchUserPosts() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).collection("posts")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    posts = snapshot.documents.compactMap { doc -> OOTDPost? in
                        try? doc.data(as: OOTDPost.self)
                    }
                    todaysOOTD = posts.first(where: { Calendar.current.isDateInToday($0.timestamp.dateValue()) })
                }
            }
    }
}
