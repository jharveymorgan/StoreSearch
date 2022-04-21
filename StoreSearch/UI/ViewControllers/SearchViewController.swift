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
        
        static let showDetailSegue    = "ShowDetail"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var landscapeVC: LandscapeViewController?
    var dataTask: URLSessionDataTask?
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 91, left: 0, bottom: 0, right: 0)
        
        let searchResultCellNib = UINib(nibName: Constants.searchResultCellId, bundle: nil)
        tableView.register(searchResultCellNib, forCellReuseIdentifier: Constants.searchResultCellId)
        
        let nothingFoundCellNib = UINib(nibName: Constants.nothingFoundCellId, bundle: nil)
        tableView.register(nothingFoundCellNib, forCellReuseIdentifier: Constants.nothingFoundCellId)
        
        let loadingCellNib = UINib(nibName: Constants.loadingCellId, bundle: nil)
        tableView.register(loadingCellNib, forCellReuseIdentifier: Constants.loadingCellId)
        
        searchBar.becomeFirstResponder()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        switch newCollection.verticalSizeClass {
        case .compact:                  showLandscape(with: coordinator)
        case .regular, .unspecified:    hideLandscape(with: coordinator)
        @unknown default:               break
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.showDetailSegue {
            let detailViewController = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            
            let searchResult = searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }


}

// MARK: -  Search Bar Delegate

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    func performSearch() {
        
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

            guard let url = iTunesURL(searchText: searchBarText, category: segmentedControl.selectedSegmentIndex) else { return }
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
            cell.configure(for: searchResult)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: Constants.showDetailSegue, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return (searchResults.count == 0 || isLoading) ? nil : indexPath
    }
}

// MARK: - Helper Methods

extension SearchViewController {
    
    func iTunesURL(searchText: String, category: Int) -> URL? {
        var kind: String
        switch category {
            case 1:     kind = "musicTrack"
            case 2:     kind = "software"
            case 3:     kind = "ebook"
            default:    kind = ""
        }
        
        guard
            let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        else { return nil }
        
        let urlString = "https://itunes.apple.com/search?term=\(encodedText)&entity=\(kind)"
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
    
    func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        guard landscapeVC == nil else { return }
        
        landscapeVC = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
        
        if let landscapeVC = landscapeVC {
            landscapeVC.view.frame = view.bounds
            landscapeVC.view.alpha = 0
            
            view.addSubview(landscapeVC.view)
            addChild(landscapeVC)
            
            // animation
            coordinator.animate { _ in
                landscapeVC.view.alpha = 1
                self.searchBar.resignFirstResponder()
                
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            } completion: { _ in
                landscapeVC.didMove(toParent: self)
            }

        }
    }
    
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if let landscapeController = landscapeVC {
            landscapeController.willMove(toParent: nil)
            
            // animation
            coordinator.animate { _ in
                landscapeController.view.alpha = 0
            } completion: { _ in
                landscapeController.view.removeFromSuperview()
                landscapeController.removeFromParent()
                self.landscapeVC = nil
            }

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

// MARK: - Actions

extension SearchViewController {
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
}

