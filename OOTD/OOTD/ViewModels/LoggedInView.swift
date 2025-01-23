import SwiftUI

struct LoggedInView: View {
    @State private var selectedTab: Int = 0
    @State private var capturedImage: UIImage? = nil // State to hold the captured image
    @State private var showPostView = false // State to present PostOOTDView

    var body: some View {
        ZStack {
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
        }
        .onChange(of: capturedImage) {
            if capturedImage != nil {
                showPostView = true // Trigger PostOOTDView
            }
        }
        .sheet(isPresented: $showPostView) {
            if let image = capturedImage {
                PostOOTDView(capturedImage: image)
            }
        }
    }
}
