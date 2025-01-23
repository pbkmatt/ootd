//
//  HomeView.swift
//  OOTD
//
//  Created by Matt Imhof on 1/22/25.
//


import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Int = 0
    @State private var posts: [OOTDPost] = []

    var body: some View {
        VStack {
            // Tab Switcher
            HStack {
                Button(action: {
                    selectedTab = 0
                    fetchFollowingPosts()
                }) {
                    Text("Following")
                        .font(.headline)
                        .foregroundColor(selectedTab == 0 ? .black : .gray)
                }

                Spacer()

                Button(action: {
                    selectedTab = 1
                    fetchTrendingPosts()
                }) {
                    Text("Trending")
                        .font(.headline)
                        .foregroundColor(selectedTab == 1 ? .black : .gray)
                }
            }
            .padding(.horizontal)

            Divider()

            // Posts
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(posts) { post in
                        PostCard(post: post)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            selectedTab == 0 ? fetchFollowingPosts() : fetchTrendingPosts()
        }
    }

    private func fetchFollowingPosts() {
        // Fetch posts from followed users
    }

    private func fetchTrendingPosts() {
        // Fetch trending posts
    }
    
    struct PostCard: View {
        let post: OOTDPost

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Post Header
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.userID) // Replace with fetched username if necessary
                            .font(.headline)
                        Text(post.timestamp.dateValue(), style: .time)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }

                // Post Image
                if let url = URL(string: post.imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                    }
                }

                // Post Footer
                HStack {
                    Image(systemName: "star")
                    Text("\(post.favoritesCount ?? 0) Favorites")

                    Spacer()

                    Image(systemName: "message")
                    Text("\(post.commentsCount ?? 0) Comments")
                }
                .padding(.top, 8)
                .font(.subheadline)
                .foregroundColor(.gray)

                Text(post.caption)
                    .font(.body)
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

}
