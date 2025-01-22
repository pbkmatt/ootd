import SwiftUI

struct TrendingView: View {
    let trendingPosts = [
        ("ootd4", "Streetwear Essentials"),
        ("ootd5", "Minimalist Fashion"),
        ("ootd6", "Festival Outfit")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if trendingPosts.isEmpty {
                        Text("No trending posts right now.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(trendingPosts, id: \.0) { post in
                            VStack {
                                Image(post.0)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                                    .cornerRadius(10)
                                    .padding()
                                
                                Text(post.1)
                                    .font(.headline)
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Trending")
        }
    }
}

struct TrendingView_Previews: PreviewProvider {
    static var previews: some View {
        TrendingView()
    }
}
