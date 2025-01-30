//
//  TourView.swift
//  OOTD
//
//  Created by Matt Imhof on 1/29/25.
//


import SwiftUI

struct TourView: View {
    @State private var currentPage = 0
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView(selection: $currentPage) {
            TourPageView(title: "Welcome to OOTD", description: "Share and explore daily outfits.") .tag(0)
            TourPageView(title: "Tag Your Items", description: "Easily share where to buy your style.") .tag(1)
            TourPageView(title: "Discover & Engage", description: "Like, comment, and save outfits.") .tag(2)

            VStack {
                Text("Let's do it!")
                    .font(.title)
                    .padding()
                
                Button(action: { authViewModel.isAuthenticated = true }) {
                    Text("Start Now")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .tag(3)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

struct TourPageView: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack {
            Text(title).font(.title)
            Text(description).font(.body)
        }
        .padding()
    }
}
