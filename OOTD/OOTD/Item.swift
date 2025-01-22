//
//  Item.swift
//  OOTD
//
//  Created by Matt Imhof on 1/19/25.
//


import Foundation

struct Item: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var url: String
}
