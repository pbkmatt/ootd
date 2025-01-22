//
//  TagInputView.swift
//  OOTD
//
//  Created by Matt Imhof on 1/22/25.
//


import SwiftUI

struct TagInputView: View {
    @Binding var tags: [String]
    @State private var newTag: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("Tags:")
                .font(.headline)
            HStack {
                TextField("Add a tag", text: $newTag, onCommit: addTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: addTag) {
                    Text("Add")
                }
            }
            ScrollView(.horizontal) {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        TagView(tag: tag, onRemove: removeTag)
                    }
                }
            }
        }
    }

    func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else { return }
        tags.append(trimmedTag)
        newTag = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

struct TagView: View {
    let tag: String
    let onRemove: (String) -> Void

    var body: some View {
        HStack {
            Text(tag)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
            Button(action: {
                onRemove(tag)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.trailing, 5)
    }
}
