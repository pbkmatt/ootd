import SwiftUI

struct UserSearchCard: View {
    let user: UserModel

    var body: some View {
        HStack(spacing: 12) {
            // MARK: Profile Picture
            if let url = URL(string: user.profilePictureURL), !user.profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable()
                         .scaledToFill()
                         .frame(width: 50, height: 50)
                         .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
            }

            // MARK: Username & Full Name
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.headline)
                if !user.fullName.isEmpty {
                    Text(user.fullName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // MARK: Followers Count
            Text("\(user.followersCount) followers")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
