import SwiftUI

struct LoggedInView: View {
    @State private var selectedTab: Int = 0
    @State private var capturedImage: UIImage? = nil // State for captured image

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home (Feed)
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                }
                .tag(0)

            // Explore (Discover)
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
                .tag(1)

            // Capture
            CameraCaptureView(capturedImage: $capturedImage)
                .tabItem {
                    Image(systemName: "camera.fill")
                }
                .tag(2)

            // Notifications
            NotificationsView()
                .tabItem {
                    Image(systemName: "bell.fill")
                }
                .tag(3)

            // Profile
            NavigationView { // Add NavigationView here
                UserProfileView()
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
            }
            .tag(4)
        }
        .accentColor(.black)
    }
}
