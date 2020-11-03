//
//  CommentViewController+UISearchBarDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit

extension CommentViewController: UISearchBarDelegate {
    // MARK: - Methods
    /// Hides the search bar when cancel button clicked.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearchBar()
    }
    
    /// Resets table view data with user entered text and refreshes it to what the user entered.
    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String) {
        filteredData = []
        if textSearched.length != 0 {
            isSearching = true
            searchCommentsList()
        } else {
            isSearching = false
        }
        tableView.reloadData()
    }
    
}
