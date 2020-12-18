//
//  FiltersViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsContentFilters: BubbleSettingTableViewController, UISearchBarDelegate {
    
    var domainEnter = UISearchBar()
    var selftextEnter = UISearchBar()
    var titleEnter = UISearchBar()
    var profileEnter = UISearchBar()
    var subredditEnter = UISearchBar()
    var flairEnter = UISearchBar()
    
    var userPaginator = Paginator()
    var redditBlocked = [String]()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.isLightTheme && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AccountController.isLoggedIn {
            getBlockedUntilCompletion()
        }
    }
    
    func getBlockedUntilCompletion() {
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.getBlocked(userPaginator, limit: 50, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                    return
                case .success(let list):
                    print(list)
                    for user in list {
                        self.redditBlocked.append(user.name)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    if self.userPaginator.hasMore() {
                        self.getBlockedUntilCompletion()
                    }
                }
            })
            
        } catch {
            print(error)
        }
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return indexPath.section == 3 && indexPath.row >= PostFilter.profiles.count ? .none : .delete
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 3 && indexPath.row >= PostFilter.profiles.count ? false : true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch indexPath.section {
            case 0:
                PostFilter.domains.remove(at: indexPath.row)
            case 1:
                PostFilter.selftext.remove(at: indexPath.row)
            case 2:
                PostFilter.titles.remove(at: indexPath.row)
            case 3:
                if indexPath.row < PostFilter.profiles.count {
                    PostFilter.profiles.remove(at: indexPath.row)
                }
            case 4:
                PostFilter.subreddits.remove(at: indexPath.row)
            case 5:
                PostFilter.flairs.remove(at: indexPath.row)
            default: fatalError("Unknown section")
            }
            let lastScrollOffset = tableView.contentOffset
            tableView.beginUpdates()

            tableView.deleteRows(at: [indexPath], with: .fade)
            
            tableView.endUpdates()
            tableView.layer.removeAllAnimations()
            tableView.setContentOffset(lastScrollOffset, animated: false)

            PostFilter.saveAndUpdate()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 3 && indexPath.row >= PostFilter.profiles.count {
            UIApplication.shared.open(URL(string: "https://www.reddit.com/prefs/blocked")!, options: [:], completionHandler: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    func setupSearchBar(_ searchBar: UISearchBar, _ title: String) {
        searchBar.searchBarStyle = UISearchBar.Style.minimal
        searchBar.placeholder = title
        searchBar.delegate = self
        searchBar.returnKeyType = .done
        searchBar.textColor = UIColor.fontColor
        searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchBar.autocapitalizationType = .none
        searchBar.isTranslucent = false
        searchBar.backgroundColor = UIColor.foregroundColor
        if !UIColor.isLightTheme {
            searchBar.keyboardAppearance = .dark
        }
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = UIColor.backgroundColor
        // set the title
        self.title = "Filters"
        self.headers = ["Submission domain filters", "Submission body text filters", "Submission title filters", "Submission author filters", "Subreddit filters", "Submission flair filters"]

        setupSearchBar(domainEnter, "Add new domain filter")
        setupSearchBar(selftextEnter, "Add new selftext keyword filter")
        setupSearchBar(titleEnter, "Add new title keyword filter")
        setupSearchBar(profileEnter, "Add new user filter")
        setupSearchBar(subredditEnter, "Add new subreddit filter")
        setupSearchBar(flairEnter, "Add new flair keyword filter")
        
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        doEnter(searchBar)
    }
    
    func doEnter(_ searchBar: UISearchBar) {
        if searchBar == domainEnter {
            PostFilter.domains.append(domainEnter.text! as NSString)
            domainEnter.text = ""
        } else if searchBar == selftextEnter {
            PostFilter.selftext.append(selftextEnter.text! as NSString)
            selftextEnter.text = ""
        } else if searchBar == titleEnter {
            PostFilter.titles.append(titleEnter.text! as NSString)
            titleEnter.text = ""
        } else if searchBar == profileEnter {
            PostFilter.profiles.append(profileEnter.text! as NSString)
            profileEnter.text = ""
        } else if searchBar == subredditEnter {
            PostFilter.subreddits.append(subredditEnter.text! as NSString)
            subredditEnter.text = ""
        } else if searchBar == flairEnter {
            PostFilter.flairs.append(flairEnter.text! as NSString)
            flairEnter.text = ""
        }
        PostFilter.saveAndUpdate()
        tableView.endEditing(true)

        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        doEnter(searchBar)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 0: return domainEnter
        case 1: return selftextEnter
        case 2: return titleEnter
        case 3: return profileEnter
        case 4: return subredditEnter
        case 5: return flairEnter
        default: fatalError("Unknown section")
            
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        cell.backgroundColor = UIColor.foregroundColor
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = UIColor.foregroundColor
        cell.textLabel?.textColor = UIColor.fontColor
        cell.tintColor = UIColor.fontColor
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = PostFilter.domains[indexPath.row] as String
        case 1:
            cell.textLabel?.text = PostFilter.selftext[indexPath.row] as String
        case 2:
            cell.textLabel?.text = PostFilter.titles[indexPath.row] as String
        case 3:
            if indexPath.row < PostFilter.profiles.count {
                cell.textLabel?.text = PostFilter.profiles[indexPath.row] as String
            } else {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.backgroundColor = UIColor.foregroundColor
                cell.accessoryType = .detailButton
                cell.backgroundColor = UIColor.foregroundColor
                cell.textLabel?.textColor = UIColor.fontColor
                cell.detailTextLabel?.textColor = UIColor.fontColor
                cell.tintColor = UIColor.fontColor
                cell.detailTextLabel?.numberOfLines = 0
                cell.detailTextLabel?.text = "User is blocked on your Reddit account, and can be unblocked at Reddit.com"
                cell.textLabel?.text = redditBlocked[indexPath.row - PostFilter.profiles.count]
            }
        case 4:
            cell.textLabel?.text = PostFilter.subreddits[indexPath.row] as String
        case 5:
            cell.textLabel?.text = PostFilter.flairs[indexPath.row] as String
        default: fatalError("Unknown section")
        }
        return cell
    }
        
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return PostFilter.domains.count
        case 1: return PostFilter.selftext.count
        case 2: return PostFilter.titles.count
        case 3: return PostFilter.profiles.count + redditBlocked.count
        case 4: return PostFilter.subreddits.count
        case 5: return PostFilter.flairs.count
        default: fatalError("Unknown number of sections")
        }
    }
}
