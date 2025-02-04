import SwiftUI
// this page does nothing right now and might remove it entirely

struct TourView: View {
    @State private var currentPage = 0
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode  // manual dismissal

    var body: some View {
        TabView(selection: $currentPage) {
            TourPageView(
                title: "Welcome to OOTD",
                description: "Share and explore daily outfits.",
                imageName: "tshirt"
            ).tag(0)

            TourPageView(
                title: "Tag Your Items",
                description: "Easily share where to buy your style.",
                imageName: "tag"
            ).tag(1)

            TourPageView(
                title: "Discover & Engage",
                description: "Like, comment, and save outfits.",
                imageName: "heart"
            ).tag(2)

            // Final Page with Start Button
            VStack(spacing: 20) {
                Text("Let's Get Started!")
                    .font(Font.custom("BebasNeue-Regular", size: 24))
                    .multilineTextAlignment(.center)

                Button(action: {
                    authViewModel.isAuthenticated = true  // 
                    presentationMode.wrappedValue.dismiss()  //
                }) {
                    Text("Start Now")
                        .font(Font.custom("BebasNeue-Regular", size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .tag(3)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .animation(.easeInOut, value: currentPage)
    }
}

// MARK: - Tour Page View
struct TourPageView: View {
    let title: String
    let description: String
    let imageName: String  // Added image to enhance UX

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            Text(title)
                .font(Font.custom("BebasNeue-Regular", size: 24))

            Text(description)
                .font(Font.custom("OpenSans", size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}
