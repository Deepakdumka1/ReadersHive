//
//  TrendingData.swift
//  Club
//
//  Auto-generated from trending.json
//

import Foundation

// MARK: - Loader
final class TrendingData {

    private(set) var response: TrendingResponse?

    init() {
        load()
    }

    // MARK: - Public Accessors
    var title: String {
        response?.title ?? "Trending"
    }

    var books: [TrendingBook] {
        response?.books ?? []
    }
}

//////////////////////////////////////////////////
// MARK: - JSON Loading
//////////////////////////////////////////////////

extension TrendingData {

    private func load(from filename: String = "trending") {
        guard let url = Bundle.main.url(forResource: "trending", withExtension: "json") else {
            print("❌ trending.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

           // print(String(data: data, encoding: .utf8) ?? "")
            response = try decoder.decode(TrendingResponse.self, from: data)

        } catch {
            print("❌ Trending JSON decode error:", error.localizedDescription)
        }
    }
}

//////////////////////////////////////////////////
// MARK: - Filtering & Helpers
//////////////////////////////////////////////////

extension TrendingData {

    /// Get books for a specific category
    func books(for category: BookCategory) -> [TrendingBook] {
        books.filter { $0.category == category }
    }

    /// Random trending book
    func randomBook() -> TrendingBook? {
        books.randomElement()
    }

    /// Safe index access
    func book(at index: Int) -> TrendingBook? {
        guard books.indices.contains(index) else { return nil }
        return books[index]
    }

    /// Check if section is empty
    var isEmpty: Bool {
        books.isEmpty
    }
}

//////////////////////////////////////////////////
// MARK: - Grouping (Optional, Future Use)
//////////////////////////////////////////////////

extension TrendingData {

    /// Group books by category
    var booksByCategory: [BookCategory: [TrendingBook]] {
        Dictionary(grouping: books, by: { $0.category })
    }
}
