import Foundation

struct TaggedItem: Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var link: String? // optional

    // Validate that name contains only letters, digits, spaces (max 40 chars)
    static func isValidName(_ name: String) -> Bool {
        // Only letters, digits, spaces, 1...40 chars
        let pattern = "^[A-Za-z0-9 ]{1,40}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: name.utf16.count)
        return regex?.firstMatch(in: name, options: [], range: range) != nil
    }
}
