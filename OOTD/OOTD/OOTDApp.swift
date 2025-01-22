import SwiftUI
import Firebase

@main
struct OOTDApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            LandingView()
                .environmentObject(authViewModel)
        }
    }
}
