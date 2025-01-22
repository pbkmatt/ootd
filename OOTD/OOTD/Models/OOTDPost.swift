//
//  OOTDPost.swift
//  OOTD
//
//  Created by Matt Imhof on 1/19/25.
//


import Foundation
import FirebaseFirestore

struct OOTDPost: Identifiable, Codable {
    @DocumentID var id: String?
    var imageURL: String
    var caption: String
    var taggedItems: [OOTDItem]
    var timestamp: Date
    var userID: String
}

struct OOTDItem: Identifiable, Codable {
    var id = UUID().uuidString
    var title: String
    var link: String
}
