//
//  FiltersViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class FiltersViewController: BubbleSettingTableViewController, UISearchBarDelegate {
    
    var domainEnter = UISearchBar()
    var selftextEnter = UISearchBar()
    var titleEnter = UISearchBar()
    var profileEnter = UISearchBar()
    var subredditEnter = UISearchBar()
    var flairEnter = UISearchBar()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
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
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
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
                PostFilter.profiles.remove(at: indexPath.row)
            case 4:
                PostFilter.subreddits.remove(at: indexPath.row)
            case 5:
                PostFilter.flairs.remove(at: indexPath.row)
            default: fatalError("Unknown section")
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
            PostFilter.saveAndUpdate()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "Filters"
        self.headers = ["Submission domain filters", "Submission body text filters", "Submission title filters", "Submission author filters", "Subreddit filters", "Submission flair filters"]

        domainEnter.searchBarStyle = UISearchBar.Style.minimal
        domainEnter.placeholder = "Add a new domain to filter"
        domainEnter.delegate = self
        domainEnter.returnKeyType = .done
        domainEnter.textColor = ColorUtil.theme.fontColor
        domainEnter.setImage(UIImage(), for: .search, state: .normal)
        domainEnter.autocapitalizationType = .none
        domainEnter.isTranslucent = false
        domainEnter.backgroundColor = ColorUtil.theme.foregroundColor
        if !ColorUtil.theme.isLight {
            domainEnter.keyboardAppearance = .dark
        }

        selftextEnter.searchBarStyle = UISearchBar.Style.minimal
        selftextEnter.placeholder = "Add a new subreddit to filter"
        selftextEnter.delegate = self
        selftextEnter.returnKeyType = .done
        selftextEnter.textColor = ColorUtil.theme.fontColor
        selftextEnter.setImage(UIImage(), for: .search, state: .normal)
        selftextEnter.autocapitalizationType = .none
        selftextEnter.isTranslucent = false
        selftextEnter.backgroundColor = ColorUtil.theme.foregroundColor
        if !ColorUtil.theme.isLight {
            selftextEnter.keyboardAppearance = .dark
        }

        titleEnter.searchBarStyle = UISearchBar.Style.minimal
        titleEnter.placeholder = "Add a new title keyword to filter"
        titleEnter.delegate = self
        titleEnter.returnKeyType = .done
        titleEnter.textColor = ColorUtil.theme.fontColor
        titleEnter.setImage(UIImage(), for: .search, state: .normal)
        titleEnter.autocapitalizationType = .none
        titleEnter.isTranslucent = false
        titleEnter.backgroundColor = ColorUtil.theme.foregroundColor
        if !ColorUtil.theme.isLight {
            titleEnter.keyboardAppearance = .dark
        }

        profileEnter.searchBarStyle = UISearchBar.Style.minimal
        profileEnter.placeholder = "Add a new user to filter"
        profileEnter.delegate = self
        profileEnter.returnKeyType = .done
        profileEnter.textColor = ColorUtil.theme.fontColor
        profileEnter.setImage(UIImage(), for: .search, state: .normal)
        profileEnter.autocapitalizationType = .none
        profileEnter.isTranslucent = false
        profileEnter.backgroundColor = ColorUtil.theme.foregroundColor
        if !ColorUtil.theme.isLight {
            profileEnter.keyboardAppearance = .dark
        }

        subredditEnter.searchBarStyle = UISearchBar.Style.minimal
        subredditEnter.placeholder = "Add a new subreddit to filter"
        subredditEnter.delegate = self
        subredditEnter.returnKeyType = .done
        subredditEnter.textColor = ColorUtil.theme.fontColor
        subredditEnter.setImage(UIImage(), for: .search, state: .normal)
        subredditEnter.setImage(UIImage(), for: .search, state: .normal)
        subredditEnter.isTranslucent = false
        subredditEnter.backgroundColor = ColorUtil.theme.foregroundColor
        if !ColorUtil.theme.isLight {
            subredditEnter.keyboardAppearance = .dark
        }

        flairEnter.searchBarStyle = UISearchBar.Style.minimal
        flairEnter.placeholder = "Add a new flair keyword to filter"
        flairEnter.delegate = self
        flairEnter.returnKeyType = .done
        flairEnter.textColor = ColorUtil.theme.fontColor
        flairEnter.setImage(UIImage(), for: .search, state: .normal)
        flairEnter.setImage(UIImage(), for: .search, state: .normal)
        flairEnter.isTranslucent = false
        flairEnter.backgroundColor = ColorUtil.theme.foregroundColor
        if !ColorUtil.theme.isLight {
            flairEnter.keyboardAppearance = .dark
        }

        tableView.isEditing = true
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
        let cell = UITableViewCell()
        cell.backgroundColor = ColorUtil.theme.foregroundColor
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = ColorUtil.theme.foregroundColor
        cell.textLabel?.textColor = ColorUtil.theme.fontColor

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = PostFilter.domains[indexPath.row] as String
        case 1:
            cell.textLabel?.text = PostFilter.selftext[indexPath.row] as String
        case 2:
            cell.textLabel?.text = PostFilter.titles[indexPath.row] as String
        case 3:
            cell.textLabel?.text = PostFilter.profiles[indexPath.row] as String
        case 4:
            cell.textLabel?.text = PostFilter.subreddits[indexPath.row] as String
        case 5:
            cell.textLabel?.text = PostFilter.flairs[indexPath.row] as String
        default: fatalError("Unknown section")
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    /* maybe future
     override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
     let cornerRadius : CGFloat = 12.0
     cell.backgroundColor = UIColor.clear
     var layer: CAShapeLayer = CAShapeLayer()
     var pathRef:CGMutablePath = CGMutablePath()
     var bounds: CGRect = cell.bounds.insetBy(dx: 25, dy: 0)
     var addLine: Bool = false
     
     if (indexPath.row == 0 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1) {
     pathRef.__addRoundedRect(transform: nil, rect: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
     } else if (indexPath.row == 0) {
     pathRef.move(to: CGPoint.init(x: bounds.minX, y: bounds.maxY))
     pathRef.addArc(center: CGPoint.init(x: bounds.minX, y: bounds.maxY), radius: bounds.midX, startAngle: bounds.minY, endAngle: cornerRadius, clockwise: false)
     pathRef.addArc(center: CGPoint.init(x: bounds.maxX, y: bounds.minY), radius: bounds.maxX, startAngle: bounds.midY, endAngle: cornerRadius, clockwise: false)
     pathRef.addLine(to: CGPoint.init(x: bounds.maxX, y: bounds.maxY))
     addLine = true
     } else if (indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1) {
     pathRef.move(to: CGPoint.init(x: bounds.minX, y: bounds.maxY))
     pathRef.addArc(center: CGPoint.init(x: bounds.minX, y: bounds.maxY), radius: bounds.midX, startAngle: bounds.maxY, endAngle: cornerRadius, clockwise: false)
     pathRef.addArc(center: CGPoint.init(x: bounds.maxX, y: bounds.maxY), radius: bounds.maxX, startAngle: bounds.midY, endAngle: cornerRadius, clockwise: false)
     pathRef.addLine(to: CGPoint.init(x: bounds.maxX, y: bounds.minY))
     } else {
     pathRef.addRect(bounds)
     addLine = true
     }
     
     layer.path = pathRef
     layer.fillColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 0.8).cgColor
     
     if (addLine == true) {
     var lineLayer: CALayer = CALayer()
     var lineHeight: CGFloat = (1.0 / UIScreen.main.scale)
     lineLayer.frame = CGRect.init(x: bounds.minX+10, y:  bounds.size.height-lineHeight, width: bounds.size.width-10, height: lineHeight)
     lineLayer.backgroundColor = tableView.separatorColor?.cgColor
     layer.addSublayer(lineLayer)
     }
     var testView: UIView = UIView(frame: bounds)
     testView.layer.insertSublayer(layer, at: 0)
     testView.backgroundColor = UIColor.clear
     cell.backgroundView = testView
     
     }*/
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return PostFilter.domains.count    // section 0 has 2 rows
        case 1: return PostFilter.selftext.count    // section 1 has 1 row
        case 2: return PostFilter.titles.count
        case 3: return PostFilter.profiles.count
        case 4: return PostFilter.subreddits.count
        case 5: return PostFilter.flairs.count
        default: fatalError("Unknown number of sections")
        }
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
