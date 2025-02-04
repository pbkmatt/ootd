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
        VStack(alignment: .leading, spacing: 12) {
            
            // MARK: - Heading
            Text("Tags")
                .font(.custom("BebasNeue-Regular", size: 18))
                .padding(.bottom, 2)
            
            // MARK: - Add New Tag
            HStack(spacing: 8) {
                TextField("Enter a new tag", text: $newTag, onCommit: addTag)
                    .font(.custom("OpenSans", size: 14))
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)

                Button(action: addTag) {
                    Text("Add")
                        .font(.custom("BebasNeue-Regular", size: 16))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.gray
                            : Color.blue
                        )
                        .cornerRadius(8)
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // MARK: - Existing Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        TagView(tag: tag, onRemove: removeTag)
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Add Tag
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTag = ""
    }

    // MARK: - Remove Tag
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

// MARK: - Tag Chip
struct TagView: View {
    let tag: String
    let onRemove: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.custom("OpenSans", size: 14))
                .foregroundColor(.black)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            Button {
                onRemove(tag)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
        }
        .padding(.trailing, 4)
    }
}
