//
//  NotificationView.swift
//  OOTD
//
//  Created by Matt Imhof on 1/19/25.
//


import SwiftUI

struct NotificationsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("No notifications yet!")
                    .foregroundColor(.gray)
                    .font(.title2)
                    .padding()
                Spacer()
            }
            .navigationTitle("Notifications")
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
