import SwiftUI

struct ExploreView: View {
    @StateObject private var vm = ExploreViewModel()
    @State private var searchText: String = ""
    @State private var selectedTab: ExploreTab = .users
    
    enum ExploreTab {
        case users
        case items
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Segmented Picker
                Picker("", selection: $selectedTab) {
                    Text("Users").tag(ExploreTab.users)
                    Text("Items").tag(ExploreTab.items)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                switch selectedTab {
                case .users:
                    usersTab
                case .items:
                    itemsTab
                }
            }
            .navigationBarTitle("Explore", displayMode: .inline)
            .onAppear {
                vm.fetchRecommendedUsers()
                vm.loadRecentSearches()
                if vm.itemsPosts.isEmpty {
                    vm.fetchItemsPosts(reset: true)
                }
            }
        }
    }
    
    // MARK: - Users Tab
    private var usersTab: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                TextField("Search by username", text: $searchText)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: searchText) { newVal in
                        if newVal.isEmpty {
                            vm.searchResults = []
                        } else {
                            vm.searchUsers(by: newVal)
                        }
                    }
                
                Button(action: {
                    vm.searchUsers(by: searchText)
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .padding(.leading, 8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            if !searchText.isEmpty {
                if vm.isLoadingUsers {
                    ProgressView("Searching...")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.searchResults, id: \.uid) { user in
                                // Single NavigationLink row
                                NavigationLink(destination: OtherProfileView(user: user)) {
                                    UserSearchCard(user: user)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
            } else {
                // If no text => show recommended + recents
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Recommended
                        if !vm.recommendedUsers.isEmpty {
                            Text("Recommended")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(vm.recommendedUsers, id: \.uid) { user in
                                        // You can use a smaller version or same card
                                        NavigationLink(destination: OtherProfileView(user: user)) {
                                            UserSearchCard(user: user)
                                                .frame(width: 250) // narrower card
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Recents
                        if !vm.recentSearches.isEmpty {
                            Text("Recent")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Show a vertical list of recently searched
                            ForEach(vm.recentSearches, id: \.uid) { user in
                                HStack {
                                    NavigationLink(destination: OtherProfileView(user: user)) {
                                        UserSearchCard(user: user)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        vm.removeFromRecentSearches(user)
                                    }) {
                                        Image(systemName: "xmark")
                                    }
                                    .padding(.trailing)
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }
    
    // MARK: - Items Tab
    private var itemsTab: some View {
        VStack {
            if vm.isLoadingItems && vm.itemsPosts.isEmpty {
                ProgressView("Loading...")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(vm.itemsPosts, id: \.id) { post in
                            Text("Post: \(post.id ?? "unknown")")
                                .frame(height: 150)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
