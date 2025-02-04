import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    @State private var username: String = ""
    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var profilePictureURL: String = ""
    @State private var instagramHandle: String = ""
    @State private var todaysOOTD: OOTDPost?
    @State private var pastOOTDs: [OOTDPost] = []
    @State private var followersCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    @State private var profileFilter: ProfilePostFilter = .all

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isSettingsViewPresented = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Bar
            HStack(spacing: 16) {
                Spacer()

                Button("Edit Profile") {
                    isSettingsViewPresented = true
                }
                .font(.custom("BebasNeue-Regular", size: 14))
                .foregroundColor(.blue)

                Button(action: signOut) {
                    Text("Sign Out")
                        .font(.custom("BebasNeue-Regular", size: 14))
                        .foregroundColor(.red)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)

            // MARK: - Content
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView("Loading Profile...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(1.3)
                }
                .padding(.top, 50)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader
                        statsAndBio

                        // MARK: - Today's OOTD
                        if let post = todaysOOTD {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Today's OOTD")
                                    .font(.custom("BebasNeue-Regular", size: 20))
                                    .padding(.leading, 8)

                                NavigationLink(destination: PostView(post: post)) {
                                    AsyncImage(url: URL(string: post.imageURL)) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(10)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        // MARK: - Past OOTDs
                        if !pastOOTDs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Past OOTDs")
                                    .font(.custom("BebasNeue-Regular", size: 20))
                                    .padding(.leading, 8)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                                          spacing: 16) {
                                    ForEach(pastOOTDs) { post in
                                        NavigationLink(destination: PostView(post: post)) {
                                            AsyncImage(url: URL(string: post.imageURL)) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(
                                                        width: UIScreen.main.bounds.width/2 - 20,
                                                        height: UIScreen.main.bounds.width/2 - 20
                                                    )
                                                    .cornerRadius(10)
                                                    .clipped()
                                            } placeholder: {
                                                Color.gray
                                                    .frame(
                                                        width: UIScreen.main.bounds.width/2 - 20,
                                                        height: UIScreen.main.bounds.width/2 - 20
                                                    )
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        } else {
                            Text("No past OOTDs yet!")
                                .font(.custom("OpenSans", size: 14))
                                .foregroundColor(.gray)
                                .padding(.top, 16)
                        }
                    }
                    .padding(.top, 12)
                }
                .refreshable {
                    await loadProfileAndPosts()
                }
                .transition(.opacity)
            }
        }
        .navigationTitle(username.isEmpty ? "Profile" : "@\(username)")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground).ignoresSafeArea())
        .sheet(isPresented: $isSettingsViewPresented) {
            SettingsView()
                .environmentObject(authViewModel)
        }
        .onAppear {
            Task {
                await loadProfileAndPosts()
            }
        }
    }

    // MARK: - Load Profile + Posts
    private func loadProfileAndPosts() async {
        await fetchUserProfile()
        await fetchUserPosts()
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 8) {
            // Profile Picture
            if let url = URL(string: profilePictureURL), !profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
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

            // Full Name
            Text(fullName.isEmpty ? "No Full Name" : fullName)
                .font(.custom("BebasNeue-Regular", size: 24))

            // Username
            Text(username.isEmpty ? "@username" : "@\(username)")
                .font(.custom("BebasNeue-Regular", size: 16))
                .foregroundColor(.primary)

            // Instagram Handle
            if !instagramHandle.isEmpty {
                Link(instagramHandle,
                     destination: URL(string: "https://instagram.com/\(instagramHandle.replacingOccurrences(of: "@", with: ""))")!)
                    .font(.custom("BebasNeue-Regular", size: 16))
                    .underline()
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Stats and Bio
    private var statsAndBio: some View {
        VStack(spacing: 10) {
            // Followers / Following
            HStack(spacing: 40) {
                VStack {
                    Text("\(followersCount)")
                        .font(.custom("BebasNeue-Regular", size: 18))
                    Text("Followers")
                        .font(.custom("OpenSans", size: 14))
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("\(followingCount)")
                        .font(.custom("BebasNeue-Regular", size: 18))
                    Text("Following")
                        .font(.custom("OpenSans", size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // Bio
            if !bio.isEmpty {
                Text(bio)
                    .font(.custom("OpenSans", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Sign Out
    private func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                authViewModel.isAuthenticated = false
            }
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch User Profile
    private func fetchUserProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let document = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()
            if let data = document.data() {
                DispatchQueue.main.async {
                    self.username = data["username"] as? String ?? "No Username"
                    self.fullName = data["fullName"] as? String ?? "No Full Name"
                    self.bio = data["bio"] as? String ?? ""
                    self.profilePictureURL = data["profilePictureURL"] as? String ?? ""
                    self.followersCount = data["followersCount"] as? Int ?? 0
                    self.followingCount = data["followingCount"] as? Int ?? 0
                    self.instagramHandle = data["instagramHandle"] as? String ?? ""

                    if let filterStr = data["profilePostFilter"] as? String,
                       let filter = ProfilePostFilter(rawValue: filterStr) {
                        self.profileFilter = filter
                    } else {
                        self.profileFilter = .all
                    }
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "❌ Error fetching user profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Fetch User Posts
    private func fetchUserPosts() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No UID found. User might not be authenticated.")
            return
        }
        do {
            let snapshot = try await Firestore.firestore()
                .collection("posts")
                .whereField("uid", isEqualTo: uid)
                .order(by: "timestamp", descending: true)
                .getDocuments()

            let posts = snapshot.documents.compactMap { doc -> OOTDPost? in
                let post = try? doc.data(as: OOTDPost.self)
                if let p = post {
                    // Debug print
                    print("🔎 Post docID: \(p.id ?? "nil"), timestamp(UTC): \(p.timestamp.dateValue())")
                }
                return post
            }

            let boundary = Date.today4AMInEST()
            print("🕓 4 AM EST boundary: \(boundary)")

            DispatchQueue.main.async {
                let filtered = self.applyProfileFilter(posts)

                // "Today’s" = any post after boundary
                self.todaysOOTD = filtered.first {
                    let ts = $0.timestamp.dateValue()
                    return ts >= boundary
                }

                // "Past" = everything before boundary
                self.pastOOTDs = filtered.filter { $0.timestamp.dateValue() < boundary }

                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "❌ Error fetching posts: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Apply Filter
    private func applyProfileFilter(_ posts: [OOTDPost]) -> [OOTDPost] {
        switch profileFilter {
        case .today:
            let boundary = Date.today4AMInEST()
            return posts.filter { $0.timestamp.dateValue() >= boundary }
        case .last7days:
            let boundary = Date.daysAgo4AMInEST(7)
            return posts.filter { $0.timestamp.dateValue() >= boundary }
        case .all:
            return posts
        }
    }
}
