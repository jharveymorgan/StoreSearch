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
        static let cellIdentifier = "SearchResultCell"
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
    }


}

// MARK: -  Search Bar Delegate

extension SearchViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        if searchBar.text! != "justin bieber" {
            for i in 0...2 {
                let searchResult = SearchResult()
                searchResult.name = String(format: "Fake Result %d for ", i)
                searchResult.artistName = searchBar.text ?? ""
                searchResults.append(searchResult)
            }
        }
        
//        for i in 0...2 {
//            let searchResult = SearchResult()
//            searchResult.name = String(format: "Fake Result %d for ", i)
//            searchResult.artistName = searchBar.text ?? ""
//            searchResults.append(searchResult)
//        }
        hasSearched = true
        tableView.reloadData()
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
        var cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier)

        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: Constants.cellIdentifier)
        }
        
        var content = cell?.defaultContentConfiguration()
        guard let cell = cell else { return UITableViewCell() }

        if searchResults.count == 0 {
            content?.text = "(Nothing found)"
            content?.secondaryText = ""
        } else {
            let searchResult = searchResults[indexPath.row]
            content?.text = searchResult.name
            content?.secondaryText = searchResult.artistName
        }
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return searchResults.count == 0 ? nil : indexPath
    }
}

