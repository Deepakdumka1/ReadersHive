//
//  TrendingEntities.swift
//  Club
//
//  Created by GEU on 14/02/26.
//
// ----->
import Foundation

// MARK: - Book Category
enum BookCategory: String, Codable, CaseIterable {
    case classics
    case fiction
    case philosophy
    case fantasy
    case dark
}

//////////////////////////////////////////////////
// MARK: - Trending Response (Root)
//////////////////////////////////////////////////

struct TrendingResponse: Codable {
    let title: String
    let books: [TrendingBook]

    enum CodingKeys: String, CodingKey {
        case title
        case books = "trending_books"
    }
}

//////////////////////////////////////////////////
// MARK: - Trending Book
//////////////////////////////////////////////////

struct TrendingBook: Codable, Identifiable {
    let id: String
    let title: String
    let author: String
    let coverImage: String
    let category: BookCategory

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case coverImage = "cover_image"
        case category
    }
}
