import SwiftUI

struct LoggedInView: View {
    @State private var selectedTab: Int = 0

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
            CameraCaptureView()
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
            UserProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                }
                .tag(4)
        }
        .accentColor(.black) // Use a sleek color for the selected tab
        .onAppear {
            UITabBar.appearance().backgroundColor = UIColor.systemBackground
            UITabBar.appearance().isTranslucent = false
        }
    }
}
