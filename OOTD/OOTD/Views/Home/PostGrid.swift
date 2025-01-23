import SwiftUI

struct PostGrid: View {
    let posts: [OOTDPost] // Filtered list of posts for this view

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(posts) { post in
                NavigationLink(destination: PostDetailView(post: post)) {
                    PostGridItem(post: post)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct PostGridItem: View {
    let post: OOTDPost

    var body: some View {
        if let url = URL(string: post.imageURL) {
            AsyncImage(url: url) { image in
                image.resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width / 2 - 20, height: UIScreen.main.bounds.width / 2 - 20)
                    .cornerRadius(10)
            } placeholder: {
                Color.gray
                    .frame(width: UIScreen.main.bounds.width / 2 - 20, height: UIScreen.main.bounds.width / 2 - 20)
                    .cornerRadius(10)
            }
        } else {
            Color.gray
                .frame(width: UIScreen.main.bounds.width / 2 - 20, height: UIScreen.main.bounds.width / 2 - 20)
                .cornerRadius(10)
        }
    }
}
