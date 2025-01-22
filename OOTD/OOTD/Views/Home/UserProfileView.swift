import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    @State private var username: String = ""
    @State private var fullName: String = ""
    @State private var instagramHandle: String = ""
    @State private var bio: String = ""
    @State private var profilePictureURL: String = ""
    @State private var posts: [OOTDPost] = []
    @State private var favorites: [OOTDPost] = []
    @State private var isPrivateProfile: Bool = false
    @State private var isLoading: Bool = true
    @State private var followersCount: Int = 0
    @State private var followingCount: Int = 0
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if isLoading {
                        ProgressView("Loading profile...")
                    } else {
                        profileHeader
                        Divider().padding()
                        todaysOOTD
                        yourOOTDs
                    }
                }
                .padding()
            }
            .navigationTitle(username.isEmpty ? "Profile" : "@\(username)")
            .navigationBarItems(
                leading: Button(action: {
                    // Navigate to Home
                }) {
                    Image(systemName: "house.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                },
                trailing: HStack {
                    NavigationLink(destination: FavoritesView(favorites: favorites)) {
                        Image(systemName: "star.fill")
                            .font(.title)
                            .foregroundColor(.yellow)
                    }
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
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

    // Profile Header Section
    private var profileHeader: some View {
        VStack {
            Text(username.isEmpty ? "No Username Set" : "@\(username)")
                .font(.title)
                .bold()
                .padding(.top, 8)

            if let url = URL(string: profilePictureURL), !profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            Text(fullName.isEmpty ? "No Full Name" : fullName)
                .font(.headline)

            if !instagramHandle.isEmpty {
                Link(instagramHandle, destination: URL(string: "https://instagram.com/\(instagramHandle)")!)
                    .foregroundColor(.blue)
            }

            HStack {
                VStack {
                    Text("\(followersCount)")
                        .font(.headline)
                    Text("Followers")
                        .font(.subheadline)
                }
                .padding(.horizontal)

                VStack {
                    Text("\(followingCount)")
                        .font(.headline)
                    Text("Following")
                        .font(.subheadline)
                }
                .padding(.horizontal)
            }

            Text(bio.isEmpty ? "No Bio Set" : bio)
                .font(.body)
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
    }

    // Today's OOTD Section
    private var todaysOOTD: some View {
        VStack {
            Text("Today's OOTD")
                .font(.headline)
                .padding(.bottom, 8)

            if let latestPost = posts.first {
                NavigationLink(destination: PostView(post: latestPost)) {
                    AsyncImage(url: URL(string: latestPost.imageURL)) { image in
                        image.resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .cornerRadius(10)
                    } placeholder: {
                        ProgressView()
                    }
                }
            } else {
                Text("No OOTD posted today")
                    .foregroundColor(.gray)
            }
        }
        .padding(.top)
    }

    // User's OOTDs Section
    private var yourOOTDs: some View {
        VStack {
            Text("Your OOTDs")
                .font(.headline)
                .padding(.bottom, 8)

            if posts.isEmpty {
                Text("No OOTDs yet!")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(posts) { post in
                        NavigationLink(destination: PostView(post: post)) {
                            AsyncImage(url: URL(string: post.imageURL)) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .cornerRadius(10)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
            }
        }
        .padding(.top)
    }

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
                    self.instagramHandle = data["instagramHandle"] as? String ?? ""
                    self.bio = data["bio"] as? String ?? "No bio available"
                    self.profilePictureURL = data["profilePictureURL"] as? String ?? ""
                    self.isPrivateProfile = data["isPrivateProfile"] as? Bool ?? false
                    self.followersCount = data["followersCount"] as? Int ?? 0
                    self.followingCount = data["followingCount"] as? Int ?? 0
                } else {
                    print("Error fetching profile: \(error?.localizedDescription ?? "Unknown error")")
                }
                self.isLoading = false
            }
        }
    }

    private func fetchUserPosts() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid).collection("posts")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let snapshot = snapshot {
                        self.posts = snapshot.documents.compactMap { doc -> OOTDPost? in
                            try? doc.data(as: OOTDPost.self)
                        }
                    } else {
                        print("Error fetching posts: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
    }
}

struct FavoritesView: View {
    var favorites: [OOTDPost]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(favorites) { post in
                    if let url = URL(string: post.imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(height: 100)
                                .cornerRadius(10)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorites")
    }
}



