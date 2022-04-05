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
        static let loadingCellId      = "LoadingCell"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var searchResults = [SearchResult]()
    var dataTask: URLSessionDataTask?
    var hasSearched = false
    var isLoading = false
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 51, left: 0, bottom: 0, right: 0)
        
        let searchResultCellNib = UINib(nibName: Constants.searchResultCellId, bundle: nil)
        tableView.register(searchResultCellNib, forCellReuseIdentifier: Constants.searchResultCellId)
        
        let nothingFoundCellNib = UINib(nibName: Constants.nothingFoundCellId, bundle: nil)
        tableView.register(nothingFoundCellNib, forCellReuseIdentifier: Constants.nothingFoundCellId)
        
        let loadingCellNib = UINib(nibName: Constants.loadingCellId, bundle: nil)
        tableView.register(loadingCellNib, forCellReuseIdentifier: Constants.loadingCellId)
        
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
            
            dataTask?.cancel()
            
            isLoading = true
            tableView.reloadData()

            hasSearched = true
            searchResults = []

            guard let url = iTunesURL(searchText: searchBarText) else { return }
            let session = URLSession.shared
            
            dataTask = session.dataTask(with: url) { data, response, error in // should ther be [weak self] here ???
                if let error = error as NSError?, error.code == -999 {
                    return // because search was cancelled
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let data = data {
                        self.searchResults = self.parse(data: data)
                        self.searchResults.sort { $0 < $1 }
                        
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.tableView.reloadData()
                        }
                        
                        return
                    }
                } else {
                    print("Failure! \(String(describing: response))")
                }
                
                DispatchQueue.main.async {
                    self.hasSearched = false
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.showNetworkErrorAlert()
                }
            }
            
            dataTask?.resume()
        }
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        .topAttached
    }
}

// MARK: - Table View Delegate

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.loadingCellId, for: indexPath)

            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            
            return cell
        }
        
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
        return (searchResults.count == 0 || isLoading) ? nil : indexPath
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

