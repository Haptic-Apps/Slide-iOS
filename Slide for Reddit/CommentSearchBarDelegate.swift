//
//  CommentSearchBarDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit

class CommentSearchBarDelegate: NSObject, UISearchBarDelegate {
    // MARK: - Properties / References
    private var commentController: CommentViewController!
    
    // MARK: - Initialization
    init(parentController: CommentViewController) {
        self.commentController = parentController
    }
    
    // MARK: - Methods
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        commentController.hideSearchBar()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String) {
        commentController.filteredData = []
        if textSearched.length != 0 {
            commentController.isSearching = true
            commentController.searchTableList()
        } else {
            commentController.isSearching = false
        }
        commentController.tableView.reloadData()
    }
}
