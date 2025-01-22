//
//  PostView.swift
//  OOTD
//
//  Created by Matt Imhof on 1/21/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostView: View {
    var post: OOTDPost
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isFavorited = false
    @State private var favoriteCount = 0
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            // Display Post Image
            AsyncImage(url: URL(string: post.imageURL)) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(10)
            } placeholder: {
                ProgressView()
            }

            HStack {
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .foregroundColor(isFavorited ? .yellow : .gray)
                    Text("\(favoriteCount)")
                        .font(.subheadline)
                }
                
                Button(action: {
                    // Open comments section
                }) {
                    Image(systemName: "message")
                    Text("\(comments.count)")
                        .font(.subheadline)
                }

                if !post.taggedItems.isEmpty {
                    Button(action: {
                        // Open tagged items section
                    }) {
                        Image(systemName: "bag.fill")
                        Text("\(post.taggedItems.count)")
                            .font(.subheadline)
                    }
                }

                Spacer()

                Button(action: {
                    sharePost()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .padding()

            // Comments Section
            VStack(alignment: .leading) {
                Text("Comments")
                    .font(.headline)
                if comments.isEmpty {
                    Text("No comments yet.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(comments) { comment in
                        HStack {
                            Text(comment.username).bold()
                            Text(comment.text)
                        }
                    }
                }

                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Post") {
                        addComment()
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .onAppear {
            loadComments()
            checkFavoriteStatus()
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadComments() {
        let db = Firestore.firestore()
        db.collection("posts").document(post.id ?? "").collection("comments")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    self.comments = snapshot.documents.compactMap { doc -> Comment? in
                        try? doc.data(as: Comment.self)
                    }
                }
            }
    }

    private func addComment() {
        guard !newComment.isEmpty, let uid = Auth.auth().currentUser?.uid else { return }
        
        let comment = Comment(id: UUID().uuidString, userID: uid, username: authViewModel.currentUsername, text: newComment, timestamp: Date())

        Firestore.firestore().collection("posts").document(post.id ?? "").collection("comments")
            .document(comment.id)
            .setData(comment.toDict()) { error in
                if error == nil {
                    self.comments.append(comment)
                    self.newComment = ""
                }
            }
    }

    private func toggleFavorite() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let postRef = Firestore.firestore().collection("posts").document(post.id ?? "")
        
        if isFavorited {
            postRef.updateData(["favorites": FieldValue.increment(Int64(-1))])
            postRef.collection("favorites").document(uid).delete()
        } else {
            postRef.updateData(["favorites": FieldValue.increment(Int64(1))])
            postRef.collection("favorites").document(uid).setData(["favoritedAt": Timestamp()])
        }
        
        isFavorited.toggle()
    }

    private func checkFavoriteStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("posts").document(post.id ?? "")
            .collection("favorites").document(uid)
            .getDocument { document, _ in
                if document?.exists == true {
                    self.isFavorited = true
                }
            }
    }

    private func sharePost() {
        let urlString = "https://ootdapp.com/post/\(post.id ?? "")"
        let activityVC = UIActivityViewController(activityItems: [urlString], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }
}

// Models

struct Comment: Identifiable, Codable {
    var id: String
    var userID: String
    var username: String
    var text: String
    var timestamp: Date

    func toDict() -> [String: Any] {
        return [
            "id": id,
            "userID": userID,
            "username": username,
            "text": text,
            "timestamp": timestamp
        ]
    }
}
