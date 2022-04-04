//
//  SearchViewController.swift
//  StoreSearch
//
//  Created by Jordan Harvey-Morgan on 4/1/22.
//

import UIKit

class SearchViewController: UIViewController {
    
    // MARK: Constants

    struct Constants {
        static let searchResultCellId = "SearchResultCell"
        static let nothingFoundCellId = "NothingFoundCell"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 51, left: 0, bottom: 0, right: 0)
        
        let searchResultCellNib = UINib(nibName: Constants.searchResultCellId, bundle: nil)
        tableView.register(searchResultCellNib, forCellReuseIdentifier: Constants.searchResultCellId)
        
        let nothingFoundCellNib = UINib(nibName: Constants.nothingFoundCellId, bundle: nil)
        tableView.register(nothingFoundCellNib, forCellReuseIdentifier: Constants.nothingFoundCellId)
        
        searchBar.becomeFirstResponder()
    }


}

// MARK: -  Search Bar Delegate

extension SearchViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if
            let searchBarText = searchBar.text,
            !searchBarText.isEmpty
        {
            searchBar.resignFirstResponder()

            hasSearched = true
            searchResults = []
            
            guard let url = iTunesURL(searchText: searchBarText) else { return }
            print("URL: \(url)")
            
            if let data = performStoreRequest(with: url) {
                searchResults = parse(data: data)
                
                searchResults.sort { $0 < $1 }
            }
            
            tableView.reloadData()
        }
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        .topAttached
    }
}

// MARK: - Table View Delegate

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: Constants.nothingFoundCellId, for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.searchResultCellId, for: indexPath) as! SearchResultCell
            
            let searchResult = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            
            if searchResult.artist.isEmpty {
                cell.artistNameLabel.text = "Unknown"
            } else {
                cell.artistNameLabel.text = "\(searchResult.artist) (\(searchResult.type))"
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return searchResults.count == 0 ? nil : indexPath
    }
}

// MARK: - Helper Methods

extension SearchViewController {
    
    func iTunesURL(searchText: String) -> URL? {
        guard
            let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        else { return nil }
        
        let urlString = "https://itunes.apple.com/search?term=\(encodedText)"
        let url = URL(string: urlString)
        
        return url
    }
    
    func performStoreRequest(with url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            print("Download Error: \(error.localizedDescription)")
            showNetworkErrorAlert()
            return nil
        }
    }
    
    func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            
            return result.results
        } catch {
            print("JSON Error: \(error)")
            return []
        }
    }
}

// MARK: - Alerts

extension SearchViewController {
    
    func showNetworkErrorAlert() {
        let alert = UIAlertController(
            title: "Oops...",
            message: "There was an error accessing the iTunes Store." + " Please try again.",
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil
        )
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}

