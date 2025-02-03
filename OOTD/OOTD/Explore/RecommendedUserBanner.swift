//
//  RecommendedUserBanner.swift
//  OOTD
//
//  Created by Matt Imhof on 2/2/25.
//


import SwiftUI

struct RecommendedUserBanner: View {
    let user: UserModel  // hacked user.bio
                         // pass mutual as sep prop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Profile pic
                if let url = URL(string: user.profilePictureURL), !user.profilePictureURL.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                }
                
                VStack(alignment: .leading) {
                    Text(user.username)
                        .font(.headline)
                    // If we stored "mutual count" in user.bio
                    Text("Followed by \(user.bio) mutual(s)") 
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
