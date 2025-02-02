import SwiftUI

struct LoggedInView: View {
    @State private var selectedTab: Int = 0
    @State private var capturedImage: UIImage? = nil // For captured image

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

            // CLOSET (replacing Notifications!)
            NavigationView {
                ClosetsView()
            }
            .tabItem {
                Text("🧥") // or "👚", or "hanger" text, or a custom SFSymbol if you have one
            }
            .tag(3)

            // Profile
            NavigationView {
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
