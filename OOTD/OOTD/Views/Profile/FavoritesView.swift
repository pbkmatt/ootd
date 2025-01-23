//
//  FavoritesView.swift
//  OOTD
//
//  Created by Matt Imhof on 1/22/25.
//


import SwiftUI

struct FavoritesView: View {
    var favorites: [OOTDPost] // Replace `OOTDPost` with your post model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Favorites")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)

                if favorites.isEmpty {
                    VStack {
                        Image(systemName: "star.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.yellow)
                            .padding(.bottom, 16)

                        Text("No Favorites Yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(favorites) { post in
                            if let url = URL(string: post.imageURL) {
                                NavigationLink(destination: PostView(post: post)) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .scaledToFill()
                                            .frame(width: UIScreen.main.bounds.width / 3 - 16, height: UIScreen.main.bounds.width / 3 - 16)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
                                            .frame(width: UIScreen.main.bounds.width / 3 - 16, height: UIScreen.main.bounds.width / 3 - 16)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}
