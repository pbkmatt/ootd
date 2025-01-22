import SwiftUI

struct ContentView: View {
    let items: [Item] = [
        Item(title: "Nike Shoes", url: "https://www.nike.com"),
        Item(title: "Adidas Hoodie", url: "https://www.adidas.com")
    ]

    var body: some View {
        List(items) { item in
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                Text(item.url)
                    .foregroundColor(.blue)
            }
        }
    }
}
