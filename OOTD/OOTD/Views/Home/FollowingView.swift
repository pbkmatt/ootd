import SwiftUI

struct FollowingView: View {
    let posts = [
        ("ootd1", "Summer Beach Outfit"),
        ("ootd2", "Casual Winter Look"),
        ("ootd3", "Office Chic")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if posts.isEmpty {
                        Text("No posts yet! Follow others to see their OOTDs.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(posts, id: \.0) { post in
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
            .navigationTitle("Following")
        }
    }
}

struct FollowingView_Previews: PreviewProvider {
    static var previews: some View {
        FollowingView()
    }
}
