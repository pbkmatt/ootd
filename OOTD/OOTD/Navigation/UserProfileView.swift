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

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
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

                        if let todaysOOTD = todaysOOTD {
                            todaysOOTDSection(todaysOOTD)
                        }

                        if !pastOOTDs.isEmpty {
                            pastOOTDsSection
                        } else {
                            Text("No past OOTDs yet!")
                                .font(Font.custom("OpenSans", size: 14))
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.opacity)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(username.isEmpty ? "Profile" : "@\(username)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: signOut) {
                    Text("Sign Out")
                        .font(Font.custom("BebasNeue-Regular", size: 14))
                        .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            Task {
                await fetchUserProfile()
                await fetchUserPosts()
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 8) {
            if let url = URL(string: profilePictureURL), !profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable()
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
                .font(Font.custom("BebasNeue-Regular", size: 24))

            Text(username.isEmpty ? "@username" : "@\(username)")
                .font(Font.custom("BebasNeue-Regular", size: 16))
                .foregroundColor(.primary)

            if !instagramHandle.isEmpty {
                Link(instagramHandle, destination: URL(string: "https://instagram.com/\(instagramHandle.replacingOccurrences(of: "@", with: ""))")!)
                    .font(Font.custom("BebasNeue-Regular", size: 16))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.976, green: 0.537, blue: 0.337), Color(red: 0.545, green: 0.298, blue: 0.847)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .underline()
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Stats and Bio
    private var statsAndBio: some View {
        VStack(spacing: 10) {
            HStack(spacing: 40) {
                VStack {
                    Text("\(followersCount)")
                        .font(Font.custom("BebasNeue-Regular", size: 18))
                    Text("Followers")
                        .font(Font.custom("OpenSans", size: 14))
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(followingCount)")
                        .font(Font.custom("BebasNeue-Regular", size: 18))
                    Text("Following")
                        .font(Font.custom("OpenSans", size: 14))
                        .foregroundColor(.secondary)
                }
            }

            if !bio.isEmpty {
                Text(bio)
                    .font(Font.custom("OpenSans", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Today's OOTD Section
    private func todaysOOTDSection(_ post: OOTDPost) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's OOTD")
                .font(Font.custom("BebasNeue-Regular", size: 20))

            PostView(post: post)
                .cornerRadius(10)
        }
    }

    // MARK: - Past OOTDs Section
    private var pastOOTDsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Past OOTDs")
                .font(Font.custom("BebasNeue-Regular", size: 20))
                .padding(.leading, 8)

            Text("Past OOTDs Count: \(pastOOTDs.count)")  // ✅ Debug print in UI

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(pastOOTDs) { post in
                    NavigationLink(destination: PostView(post: post)) {
                        AsyncImage(url: URL(string: post.imageURL ?? "")) { image in
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
    }

    // MARK: - Sign Out
    private func signOut() {
        do {
            try Auth.auth().signOut()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch User Profile
    private func fetchUserProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let document = try await Firestore.firestore().collection("users").document(uid).getDocument()
            if let data = document.data() {
                DispatchQueue.main.async {
                    username = data["username"] as? String ?? "No Username"
                    fullName = data["fullName"] as? String ?? "No Full Name"
                    bio = data["bio"] as? String ?? ""
                    profilePictureURL = data["profilePictureURL"] as? String ?? ""
                    followersCount = data["followersCount"] as? Int ?? 0
                    followingCount = data["followingCount"] as? Int ?? 0
                    instagramHandle = data["instagramHandle"] as? String ?? ""
                    isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "❌ Error fetching user profile: \(error.localizedDescription)"
                isLoading = false
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
                .collection("posts")  // ✅ Querying the global posts collection
                .whereField("uid", isEqualTo: uid)  // ✅ Filtering by user ID
                .order(by: "timestamp", descending: true)  // ✅ Sorting by timestamp
                .getDocuments()

            print("✅ Firestore returned \(snapshot.documents.count) documents.")

            let posts = snapshot.documents.compactMap { document -> OOTDPost? in
                let data = document.data()
                print("📸 Found post: \(data)")
                return try? document.data(as: OOTDPost.self)
            }

            DispatchQueue.main.async {
                todaysOOTD = posts.first(where: { Calendar.current.isDateInToday($0.timestamp.dateValue()) })
                pastOOTDs = posts.filter { !Calendar.current.isDateInToday($0.timestamp.dateValue()) }
                isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "❌ Error fetching posts: \(error.localizedDescription)"
                print("❌ Firestore Error: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    }
