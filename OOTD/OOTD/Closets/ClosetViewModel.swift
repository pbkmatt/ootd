import Foundation
import FirebaseAuth
import FirebaseFirestore

class ClosetViewModel: ObservableObject {
    @Published var closets: [Closet] = []
    private var listenerRegistration: ListenerRegistration?

    func fetchUserClosets() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        listenerRegistration = db.collection("users")
            .document(uid)
            .collection("closets")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching closets: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.closets = documents.compactMap { doc in
                    try? doc.data(as: Closet.self)
                }
            }
    }

    func stopListening() {
        listenerRegistration?.remove()
    }

    // Add a post to an existing closet
    func addPost(to closet: Closet, postId: String, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid,
              let closetId = closet.id else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(uid)
          .collection("closets").document(closetId)
          .updateData(["postIds": FieldValue.arrayUnion([postId])], completion: completion)
    }

    // Create a new closet
    func createCloset(name: String, firstPostId: String? = nil, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let ref = db.collection("users").document(uid)
            .collection("closets").document()

        var postArray = [String]()
        if let firstPostId = firstPostId {
            postArray.append(firstPostId)
        }

        let closet = Closet(
            id: ref.documentID,
            name: name,
            ownerId: uid,
            createdAt: Timestamp(),
            postIds: postArray
        )

        do {
            try ref.setData(from: closet, completion: completion)
        } catch {
            completion(error)
        }
    }
}
