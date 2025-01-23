import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    @State private var username: String = ""
    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var profilePictureURL: String = ""
    @State private var posts: [OOTDPost] = []
    @State private var favorites: [OOTDPost] = []
    @State private var followersCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var isLoading: Bool = true
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading profile...")
                    } else {
                        profileHeader
                        statsAndBio
                        todaysOOTD
                        yourOOTDs
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle(username.isEmpty ? "Profile" : "@\(username)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: HStack {
                    NavigationLink(destination: FavoritesView(favorites: favorites)) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                    }
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            )
            .onAppear {
                fetchUserProfile()
                fetchUserPosts()
            }
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
                    ProgressView()
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            Text(fullName.isEmpty ? "No Full Name" : fullName)
                .font(Font.custom("YourCustomFont-Bold", size: 20))
                .foregroundColor(.primary)

            Text(username.isEmpty ? "@username" : "@\(username)")
                .font(Font.custom("YourCustomFont-Regular", size: 16))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Stats and Bio
    private var statsAndBio: some View {
        VStack(spacing: 12) {
            HStack(spacing: 40) {
                VStack {
                    Text("\(followersCount)")
                        .font(Font.custom("YourCustomFont-Bold", size: 18))
                    Text("Followers")
                        .font(Font.custom("YourCustomFont-Regular", size: 14))
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(followingCount)")
                        .font(Font.custom("YourCustomFont-Bold", size: 18))
                    Text("Following")
                        .font(Font.custom("YourCustomFont-Regular", size: 14))
                        .foregroundColor(.secondary)
                }
            }

            if !bio.isEmpty {
                Text(bio)
                    .font(Font.custom("YourCustomFont-Regular", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Today's OOTD
    private var todaysOOTD: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's OOTD")
                .font(Font.custom("YourCustomFont-Bold", size: 18))
                .padding(.horizontal)

            if let latestPost = posts.first {
                NavigationLink(destination: PostView(post: latestPost)) {
                    AsyncImage(url: URL(string: latestPost.imageURL)) { image in
                        image.resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxHeight: 300) // Prominent display for today's OOTD
                    .padding(.horizontal)
                }
            } else {
                Text("No OOTD posted today")
                    .font(Font.custom("YourCustomFont-Regular", size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - User's OOTDs Grid
    private var yourOOTDs: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your OOTDs")
                .font(Font.custom("YourCustomFont-Bold", size: 18))
                .padding(.horizontal)

            if posts.count > 1 {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(posts.dropFirst()) { post in // Exclude the most recent post
                        NavigationLink(destination: PostView(post: post)) {
                            AsyncImage(url: URL(string: post.imageURL)) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: UIScreen.main.bounds.width / 3 - 12, height: UIScreen.main.bounds.width / 3 - 12)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } placeholder: {
                                Color.gray.opacity(0.3)
                                    .frame(width: UIScreen.main.bounds.width / 3 - 12, height: UIScreen.main.bounds.width / 3 - 12)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                Text("No additional OOTDs yet!")
                    .font(Font.custom("YourCustomFont-Regular", size: 14))
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding(.top)
    }

    // MARK: - Fetch User Profile
    private func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            return
        }

        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists, let data = document.data() {
                    self.username = data["username"] as? String ?? "No Username"
                    self.fullName = data["fullName"] as? String ?? "No Full Name"
                    self.bio = data["bio"] as? String ?? "No bio available"
                    self.profilePictureURL = data["profilePictureURL"] as? String ?? ""
                    self.followersCount = data["followersCount"] as? Int ?? 0
                    self.followingCount = data["followingCount"] as? Int ?? 0
                } else {
                    print("Error fetching profile: \(error?.localizedDescription ?? "Unknown error")")
                }
                self.isLoading = false
            }
        }
    }

    // MARK: - Fetch User Posts
    private func fetchUserPosts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("posts")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching posts: \(error.localizedDescription)")
                        return
                    }

                    if let snapshot = snapshot {
                        self.posts = snapshot.documents.compactMap { doc -> OOTDPost? in
                            try? doc.data(as: OOTDPost.self)
                        }
                        print("Fetched \(self.posts.count) posts.")
                    } else {
                        print("No posts found.")
                    }
                }
            }
    }

}
