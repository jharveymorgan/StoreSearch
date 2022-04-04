//
//  SearchResult.swift
//  StoreSearch
//
//  Created by Jordan Harvey-Morgan on 4/1/22.
//

import Foundation

class ResultArray: Codable {
    
    // MARK: Properties

    var resultCount = 0
    var results = [SearchResult]()
}

class SearchResult: Codable, CustomStringConvertible {
    
    // MARK: Coding Keys
    enum CodingKeys: String, CodingKey {
        case imageSmall = "artworkUrl60"
        case imageLarge = "artworkUrl100"
        case itemGenre = "primaryGenreName"
        case bookGenre = "genres"
        case itemPrice = "price"
        case kind, artistName, trackName
        case trackPrice, currency
        case collectionName, collectionViewUrl, collectionPrice
    }
    
    // MARK: Properties
    
    var kind: String?
    var artistName: String?
    var trackName: String?
    var trackPrice: Double?
    var trackViewUrl: String?
    var collectionName: String?
    var collectionViewUrl: String?
    var collectionPrice: Double?
    var itemPrice: Double?
    var itemGenre: String?
    var bookGenre: [String]?
    
    var currency = ""
    var imageSmall = ""
    var imageLarge = ""
    
    var name: String {
        trackName ?? collectionName ?? ""
    }
    
    var type: String {
        let kind = self.kind ?? "audiobook"
        switch kind {
        case "album":           return "Album"
        case "audiobook":       return "Audio Book"
        case "book":            return "Book"
        case "ebook":           return "E-Book"
        case "feature-movie":   return "Movie"
        case "music-video":     return "Music Video"
        case "podcast":         return "Podcast"
        case "software":        return "App"
        case "song":            return "Song"
        case "tv-episode":      return "TV Episode"
        default:                break
        }
        
        return "Unkown"
    }
    
    var artist: String {
        artistName ?? ""
    }
    
    var storeURL: String {
        trackViewUrl ?? collectionViewUrl ?? ""
    }
    
    var price: Double {
        trackPrice ?? collectionPrice ?? 0.0
    }
    
    var genre: String {
        if let genre = itemGenre {
            return genre
        } else if let genres = bookGenre {
            return genres.joined(separator: ", ")
        }
        
        return ""
    }
    
    var description: String {
        "\nResult - Kind: \(kind ?? "None"), Name: \(name), Artist Name: \(artistName ?? "None")"
    }
}

// MARK: - Helpers

extension SearchResult {
    static func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}
