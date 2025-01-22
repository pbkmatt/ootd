import SwiftUI

struct LoggedInView: View {
    @State private var selectedTab: Int = 0
    @State private var capturedImage: UIImage? = nil // State to hold the captured image
    @State private var showPostOOTDView = false // State to control PostOOTDView presentation

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

            CameraCaptureView(capturedImage: $capturedImage)
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Capture")
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
        .onChange(of: capturedImage) { newImage in
            if let newImage = newImage {
                showPostOOTDView = true // Trigger PostOOTDView presentation
            }
        }
        .sheet(isPresented: $showPostOOTDView) {
            if let image = capturedImage {
                PostOOTDView(capturedImage: image)
            }
        }
    }
}
