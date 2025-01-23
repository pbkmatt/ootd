import SwiftUI
import Firebase

@main
struct OOTDApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            LandingView()
                .environmentObject(authViewModel)
        }
    }
    func updateExistingPostsSchema() {
        let db = Firestore.firestore()
        
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            
            snapshot?.documents.forEach { userDoc in
                let userId = userDoc.documentID
                let postsCollection = db.collection("users").document(userId).collection("posts")
                
                postsCollection.getDocuments { postsSnapshot, postsError in
                    if let postsError = postsError {
                        print("Error fetching posts for user \(userId): \(postsError.localizedDescription)")
                        return
                    }
                    
                    postsSnapshot?.documents.forEach { postDoc in
                        var updatedData = postDoc.data()
                        updatedData["visibility"] = updatedData["visibility"] ?? "public"
                        updatedData["commentsCount"] = updatedData["commentsCount"] ?? 0
                        updatedData["favoritesCount"] = updatedData["favoritesCount"] ?? 0
                        
                        postsCollection.document(postDoc.documentID).setData(updatedData, merge: true) { setDataError in
                            if let setDataError = setDataError {
                                print("Error updating post \(postDoc.documentID): \(setDataError.localizedDescription)")
                            } else {
                                print("Post \(postDoc.documentID) updated successfully.")
                            }
                        }
                    }
                }
            }
        }
    }
}
