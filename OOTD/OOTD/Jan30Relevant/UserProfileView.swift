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
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        profileHeader
                        statsAndBio
                        if let todaysOOTD = todaysOOTD {
                            todaysOOTDSection(todaysOOTD)
                        }
                        Text("Your OOTDs")
                            .font(Font.custom("BebasNeue-Regular", size: 20))
                            .padding(.leading, 8)
                        PostGrid(filterType: "profilePosts")
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(username.isEmpty ? "Profile" : "@\(username)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: signOut) {
            Text("Sign Out")
                .font(Font.custom("BebasNeue-Regular", size: 14))
                .foregroundColor(.red)
        })
        .onAppear {
            fetchUserProfile()
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
    private func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "❌ Error fetching user profile: \(error.localizedDescription)"
                } else if let document = document, let data = document.data() {
                    username = data["username"] as? String ?? "No Username"
                    fullName = data["fullName"] as? String ?? "No Full Name"
                    bio = data["bio"] as? String ?? ""
                    profilePictureURL = data["profilePictureURL"] as? String ?? ""
                    followersCount = data["followersCount"] as? Int ?? 0
                    followingCount = data["followingCount"] as? Int ?? 0
                    instagramHandle = data["instagramHandle"] as? String ?? ""
                }
                isLoading = false
            }
        }
    }
}
