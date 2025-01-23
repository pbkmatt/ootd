//
//  PostGrid.swift
//  OOTD
//
//  Created by Matt Imhof on 1/22/25.
//


import SwiftUI

struct PostGrid: View {
    let posts: [OOTDPost]
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
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
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width / 2 - 20, height: UIScreen.main.bounds.width / 2 - 20)
                    .clipped()
                    .cornerRadius(10)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: UIScreen.main.bounds.width / 2 - 20, height: UIScreen.main.bounds.width / 2 - 20)
                    .cornerRadius(10)
            }
        }
    }
}
