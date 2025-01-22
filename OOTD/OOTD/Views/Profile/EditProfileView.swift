//
//  EditProfileView.swift
//  OOTD
//
//  Created by Matt Imhof on 1/19/25.
//


import SwiftUI

struct EditProfileView: View {
    @State private var user = UserModel(username: "", bio: "", isPrivate: false)

    var body: some View {
        VStack {
            Text("Edit Profile")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $user.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Bio", text: $user.bio)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Toggle("Private Profile", isOn: $user.isPrivate)
                .padding()

            Button("Update Profile") {
                ProfileManager.shared.createUserProfile(user: user) { error in
                    if let error = error {
                        print("Error updating profile:", error.localizedDescription)
                    } else {
                        print("Profile updated successfully")
                    }
                }
            }
            .padding()
        }
        .padding()
        .onAppear {
            ProfileManager.shared.fetchUserProfile { fetchedUser, error in
                if let fetchedUser = fetchedUser {
                    self.user = fetchedUser
                }
            }
        }
    }
}
