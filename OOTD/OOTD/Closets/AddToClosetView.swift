//
//  AddToClosetView.swift
//  OOTD
//
//  Created by Matt Imhof on 2/2/25.
//


import SwiftUI

struct AddToClosetView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var closetViewModel = ClosetViewModel()
    
    let postId: String  // The ID of the post we want to save
    
    // For creating a new closet
    @State private var newClosetName: String = ""
    @State private var showNewClosetField: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Optional: toggle to show/hide “create new closet” text field
                if showNewClosetField {
                    TextField("Closet name", text: $newClosetName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button("Create Closet") {
                        createNewCloset()
                    }
                    .padding(.bottom, 10)
                } else {
                    Button(action: {
                        // Show the text field for a new closet name
                        withAnimation {
                            showNewClosetField = true
                        }
                    }) {
                        Text("Create New Closet")
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding([.horizontal, .top])
                    }
                }
                
                // List of existing closets
                List {
                    ForEach(closetViewModel.closets) { closet in
                        Button(action: {
                            addPostTo(closet: closet)
                        }) {
                            HStack {
                                Text(closet.name)
                                Spacer()
                                Text("\(closet.postIds.count) items")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Your Closets", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                closetViewModel.fetchUserClosets()
            }
            .onDisappear {
                closetViewModel.stopListening()
            }
        }
    }
    
    private func createNewCloset() {
        guard !newClosetName.isEmpty else { return }
        closetViewModel.createCloset(name: newClosetName, firstPostId: postId) { error in
            if let error = error {
                print("Error creating closet: \(error.localizedDescription)")
                return
            }
            // Reset UI
            self.newClosetName = ""
            self.showNewClosetField = false
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func addPostTo(closet: Closet) {
        closetViewModel.addPost(to: closet, postId: postId) { error in
            if let error = error {
                print("Error adding post to closet: \(error.localizedDescription)")
            } else {
                // Dismiss after success
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
