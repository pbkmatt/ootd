import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ExploreViewModel: ObservableObject {
    // MARK: - Users Tab
    @Published var recommendedUsers: [UserModel] = []
    @Published var recentSearches: [UserModel] = []
    @Published var searchResults: [UserModel] = []
    @Published var isLoadingUsers = false
    
    // MARK: - Items Tab
    @Published var itemsPosts: [OOTDPost] = []
    @Published var isLoadingItems = false
    @Published var canLoadMoreItems = true
    
    // Firestore references
    private let db = Firestore.firestore()
    private var lastItemsDocSnapshot: DocumentSnapshot?
    private let itemsPageSize = 10
    
    // MARK: - Recommended Users
    func fetchRecommendedUsers() {
        // Example: fetch top 5 user docs
        db.collection("users").limit(to: 5).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching recommended: \(error.localizedDescription)")
                return
            }
            guard let docs = snapshot?.documents else { return }
            let parsed = docs.compactMap { try? $0.data(as: UserModel.self) }
            DispatchQueue.main.async {
                self.recommendedUsers = parsed
            }
        }
    }
    
    // MARK: - Recent Searches
    func loadRecentSearches() {
        // load from UserDefaults or do nothing
        recentSearches = []
    }
    
    func addToRecentSearches(_ user: UserModel) {
        if let idx = recentSearches.firstIndex(where: { $0.uid == user.uid }) {
            recentSearches.remove(at: idx)
        }
        recentSearches.insert(user, at: 0)
        if recentSearches.count > 10 {
            recentSearches.removeLast()
        }
    }
    
    func removeFromRecentSearches(_ user: UserModel) {
        if let idx = recentSearches.firstIndex(where: { $0.uid == user.uid }) {
            recentSearches.remove(at: idx)
        }
    }
    
    // MARK: - Search Users (Case-insensitive approach)
    func searchUsers(by username: String) {
        guard !username.isEmpty else {
            searchResults = []
            return
        }
        isLoadingUsers = true
        
        // Must store username in all-lowercase in Firestore
        db.collection("users")
            .order(by: "username") // ascending
            .start(at: [username.lowercased()])
            .end(at: [username.lowercased() + "\u{f8ff}"])
            .limit(to: 10)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingUsers = false
                }
                if let error = error {
                    print("Error searching users: \(error)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                let found = docs.compactMap { try? $0.data(as: UserModel.self) }
                DispatchQueue.main.async {
                    self.searchResults = found
                }
            }
    }
    
    // MARK: - Items Tab: fetch today's public posts with non-empty taggedItems
    func fetchItemsPosts(reset: Bool) {
        guard !isLoadingItems else { return }
        isLoadingItems = true
        
        if reset {
            itemsPosts = []
            lastItemsDocSnapshot = nil
            canLoadMoreItems = true
        }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        var query = db.collection("posts")
            .whereField("visibility", isEqualTo: "public")
            .whereField("timestamp", isGreaterThan: Timestamp(date: startOfDay))
            .whereField("taggedItems", isGreaterThan: [])
            .order(by: "closetsCount", descending: true)
            .limit(to: itemsPageSize)
        
        if let lastSnap = lastItemsDocSnapshot {
            query = query.start(afterDocument: lastSnap)
        }
        
        query.getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoadingItems = false
            }
            if let error = error {
                print("Error fetching items posts: \(error.localizedDescription)")
                return
            }
            guard let docs = snapshot?.documents, !docs.isEmpty else {
                DispatchQueue.main.async {
                    self.canLoadMoreItems = false
                }
                return
            }
            
            let newPosts = docs.compactMap { try? $0.data(as: OOTDPost.self) }
            DispatchQueue.main.async {
                self.itemsPosts.append(contentsOf: newPosts)
                self.lastItemsDocSnapshot = docs.last
                if docs.count < self.itemsPageSize {
                    self.canLoadMoreItems = false
                }
            }
        }
    }
}
