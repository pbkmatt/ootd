//
//  OOTDPost.swift
//  OOTD
//
//  Created by Matt Imhof on 1/19/25.
//


import Foundation
import FirebaseFirestore

struct OOTDPost: Identifiable, Decodable {
    @DocumentID var id: String?
    var caption: String
    var imageURL: String
    var taggedItems: [String] // Adjust type if `taggedItems` is an array of dictionaries
    var timestamp: Timestamp
    var visibility: String // e.g., "public" or "private"
    var commentsCount: Int
    var favoritesCount: Int
    var userID: String
}


struct OOTDItem: Identifiable, Codable {
    var id = UUID().uuidString
    var title: String
    var link: String
}
