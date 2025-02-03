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
            // Buttons at the top of the screen
            HStack(spacing: 16) {
                Spacer()
                Button("Edit Profile") {
                    isSettingsViewPresented = true
                }
                .font(.custom("BebasNeue-Regular", size: 14))

                Button(action: signOut) {
                    Text("Sign Out")
                        .font(.custom("BebasNeue-Regular", size: 14))
                        .foregroundColor(.red)
                }
            }
            .padding(.top)
            .padding(.horizontal)

            if isLoading {
                ProgressView("Loading Profile...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(1.5)
                    .padding(.top, 50)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        profileHeader
                        statsAndBio

                        // Print out the 4 AM EST boundary for debugging
                        Text("Debug: Today 4AM EST = \(Date.today4AMInEST())")
                            .foregroundColor(.orange)
                            .font(.footnote)

                        // Show "Today's OOTD"
                        if let post = todaysOOTD {
                            Text("Today's OOTD")
                                .font(.custom("BebasNeue-Regular", size: 20))
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                .padding(.horizontal)
                            }
                        }

                        // Show Past OOTDs
                        if !pastOOTDs.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Past OOTDs")
                                    .font(.custom("BebasNeue-Regular", size: 20))
                                    .padding(.leading, 8)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(pastOOTDs) { post in
                                        NavigationLink(destination: PostView(post: post)) {
                                            AsyncImage(url: URL(string: post.imageURL)) { image in
                                                image.resizable()
                                                     .scaledToFill()
                                                     .frame(width: UIScreen.main.bounds.width / 2 - 20,
                                                            height: UIScreen.main.bounds.width / 2 - 20)
                                                     .cornerRadius(10)
                                            } placeholder: {
                                                Color.gray
                                                    .frame(width: UIScreen.main.bounds.width / 2 - 20,
                                                           height: UIScreen.main.bounds.width / 2 - 20)
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            Text("No past OOTDs yet!")
                                .font(.custom("OpenSans", size: 14))
                                .foregroundColor(.gray)
                                .padding()
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
            if let url = URL(string: profilePictureURL), !profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
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

            Text(fullName.isEmpty ? "No Full Name" : fullName)
                .font(.custom("BebasNeue-Regular", size: 24))

            Text(username.isEmpty ? "@username" : "@\(username)")
                .font(.custom("BebasNeue-Regular", size: 16))
                .foregroundColor(.primary)

            if !instagramHandle.isEmpty {
                Link(instagramHandle,
                     destination: URL(string: "https://instagram.com/\(instagramHandle.replacingOccurrences(of: "@", with: ""))")!)
                    .font(.custom("BebasNeue-Regular", size: 16))
                    .underline()
            }
        }
    }

    // MARK: - Stats and Bio
    private var statsAndBio: some View {
        VStack(spacing: 10) {
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

            if !bio.isEmpty {
                Text(bio)
                    .font(.custom("OpenSans", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
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
                    // Debug print: each post doc ID + timestamp
                    print("🔎 Post docID: \(p.id ?? "nil"), timestamp(UTC): \(p.timestamp.dateValue())")
                }
                return post
            }
            
            // Print the boundary for debug
            let boundary = Date.today4AMInEST()
            print("🕓 4 AM EST boundary: \(boundary)")
            
            DispatchQueue.main.async {
                // Filter
                let filtered = self.applyProfileFilter(posts)
                
                // "Today's" = any post after boundary
                self.todaysOOTD = filtered.first(where: {
                    let ts = $0.timestamp.dateValue()
                    print("🔎 Checking postID: \($0.id ?? "nil"), date=\(ts)")
                    return ts >= boundary
                })
                
                if let t = self.todaysOOTD {
                    print("✅ Found today's OOTD: \(t.id ?? "nil")")
                } else {
                    print("🛑 No today's OOTD matched. Possibly all < 4 AM boundary or no posts exist.")
                }

                // Past = < boundary
                self.pastOOTDs = filtered.filter { $0.timestamp.dateValue() < boundary }
                if !self.pastOOTDs.isEmpty {
                    print("🗂 Past OOTDs count: \(self.pastOOTDs.count)")
                } else {
                    print("🗂 No past OOTDs either.")
                }

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
            print("🤔 Filter = .today, boundary: \(boundary)")
            return posts.filter { $0.timestamp.dateValue() >= boundary }
        case .last7days:
            let boundary = Date.daysAgo4AMInEST(7)
            print("🤔 Filter = .last7days, boundary: \(boundary)")
            return posts.filter { $0.timestamp.dateValue() >= boundary }
        case .all:
            print("🤔 Filter = .all, no boundary used.")
            return posts
        }
    }
}
