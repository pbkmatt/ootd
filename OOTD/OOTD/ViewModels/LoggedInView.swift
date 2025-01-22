import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoggedInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var profilePictureURL: String = ""
    @State private var isLoading: Bool = true
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FollowingView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Following")
                }
                .tag(0)

            TrendingView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Trending")
                }
                .tag(1)

            PostOOTDView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Post OOTD")
                }
                .tag(2)

            NotificationsView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Notifications")
                }
                .tag(3)

            UserProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .navigationTitle(selectedTab == 0 ? "Following" : selectedTab == 1 ? "Trending" : selectedTab == 2 ? "Post OOTD" : selectedTab == 3 ? "Notifications" : "Profile")
        .navigationBarItems(trailing: NavigationLink(destination: EditProfileView()) {
            Image(systemName: "gear")
                .font(.title)
        })
        .onAppear {
            fetchUserProfile()
        }
    }

    private func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            return
        }

        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists, let data = document.data() {
                    self.username = data["username"] as? String ?? "No Name"
                    self.bio = data["bio"] as? String ?? "No bio available."
                    self.profilePictureURL = data["profilePictureURL"] as? String ?? ""
                } else {
                    print("Error fetching profile: \(error?.localizedDescription ?? "Unknown error")")

                }
                self.isLoading = false
            }
        }
    }
}

struct LoggedInView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInView().environmentObject(AuthViewModel())
    }
}
