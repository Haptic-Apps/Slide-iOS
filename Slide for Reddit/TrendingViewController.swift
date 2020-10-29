//
//  TrendingViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 10/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import Alamofire
import reddift
import SDWebImage
import SwiftyJSON
import UIKit

class TrendingViewController: UITableViewController {
    var trendingSubs: [String] = []
    var trendingSearches: [TrendingItem] = []
    
    var taskSearches: DataRequest?
    var taskSubs: DataRequest?

    func loadData() {
        do {
            let requestString = "https://www.reddit.com/api/trending_searches_v1.json?always_show_media=1&api_type=json&expand_srs=1&feature=link_preview&from_detail=1&obey_over18=1&raw_json=1&sr_detail=1"
            taskSearches = Alamofire.request(requestString, method: .get).responseString { response in
                do {
                    guard let data = response.data else {
                        return
                    }
                    let json = try JSON(data: data)
                    if let searches = json["trending_searches"].array {
                        for searchLinkJSON in searches {
                            var searchItem = TrendingItem()
                            let linkData = searchLinkJSON["results"]["data"]["children"].array
                            
                            searchItem.imageUrl = linkData?[0]["thumbnail"].stringValue ?? ""
                            searchItem.title = linkData?[0]["title"].stringValue ?? ""
                            searchItem.subreddit = linkData?[0]["subreddit"].stringValue ?? ""
                            searchItem.imageUrl = linkData?[0]["thumbnail"].stringValue ?? ""
                            searchItem.searchTerm = searchLinkJSON["query_string"].stringValue ?? ""
                            searchItem.searchTitle = searchLinkJSON["display_string"].stringValue ?? ""
                            self.trendingSearches.append(searchItem)
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                } catch {
                }
            }
        }
        do {
            let requestString = "https://www.reddit.com/api/trending_subreddits.json"
            taskSubs = Alamofire.request(requestString, method: .get).responseString { response in
                do {
                    guard let data = response.data else {
                        return
                    }
                    let json = try JSON(data: data)
                    if let subs = json["subreddit_names"].array {
                        for sub in subs {
                            self.trendingSubs.append(sub.stringValue)
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                } catch {
                }
            }
        }
    }

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
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.register(TrendingCellView.classForCoder(), forCellReuseIdentifier: "trending")
        self.tableView.isEditing = true
        self.tableView.backgroundColor = ColorUtil.theme.backgroundColor
                
        //TODO show loading indicator
        tableView.reloadData()
        
        self.tableView.tableFooterView = UIView()
        
        loadData()
    }
        
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        taskSubs?.cancel()
        taskSearches?.cancel()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? trendingSearches.count : trendingSubs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let thing = trendingSearches[indexPath.row]
            var cell: TrendingCellView?
            let c = tableView.dequeueReusableCell(withIdentifier: "trending", for: indexPath) as! TrendingCellView
            c.setItem(item: thing)
            cell = c
            
            return cell!
        } else {
            let thing = trendingSubs[indexPath.row]
            var cell: SubredditCellView?
            let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
            c.setSubreddit(subreddit: thing, nav: nil)
            cell = c
            cell?.backgroundColor = ColorUtil.theme.foregroundColor
            
            return cell!
        }
    }
        
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.separatorStyle = .none
        setupBaseBarColors()
        self.title = "Trending on Reddit"
    }
}

class TrendingItem {
    var title: String = ""
    var subreddit: String = ""
    var searchTerm: String = ""
    var searchTitle: String = ""
    var imageUrl: String = ""
}

class TrendingCellView: UITableViewCell {

    var textView = UILabel()
    var searchTitle = UILabel()
    var thumbView = UIImageView()
    var subName = UILabel()
    var subDot = UIImageView()
    
    weak var navController: UIViewController?
    static var defaultIcon = UIImage(sfString: SFSymbol.rCircle, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)
    static var defaultIconMulti = UIImage(sfString: SFSymbol.mCircle, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)
    static var allIcon = UIImage(sfString: SFSymbol.globe, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)
    static var frontpageIcon = UIImage(sfString: SFSymbol.houseFill, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)
    static var popularIcon = UIImage(sfString: SFSymbol.flameFill, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
        configureLayout()
    }

    func configureViews() {
        self.clipsToBounds = true

        subName.font = UIFont.boldSystemFont(ofSize: 14)
        subName.textColor = ColorUtil.theme.fontColor
        
        subDot.layer.cornerRadius = (25 / 2)
        subDot.clipsToBounds = true
        textView.textColor = ColorUtil.theme.fontColor
        searchTitle.textColor = ColorUtil.baseAccent
        
        thumbView.layer.cornerRadius = 10
        thumbView.clipsToBounds = true
    }
    
    func setItem(item: TrendingItem) {

        subDot.backgroundColor = ColorUtil.getColorForSub(sub: item.subreddit)
        
        if let icon = Subscriptions.icon(for: item.subreddit) {
            subDot.sd_setImage(with: URL(string: icon.unescapeHTML), completed: nil)
        }
        subName.text = "r/\(item.subreddit)"
        
        if item.imageUrl != "" {
            thumbView.isHidden = false
            thumbView.contentMode = .scaleAspectFill
            thumbView.loadImageWithPulsingAnimation(atUrl: URL(string: item.imageUrl), withPlaceHolderImage: LinkCellImageCache.web, isBannerView: false)
        } else {
            thumbView.isHidden = true
        }
        
        textView.numberOfLines = 0
        textView.lineBreakMode = .byTruncatingTail

        textView.font = UIFont.systemFont(ofSize: 16)
        textView.text = item.title
        textView.sizeToFit()
        
        searchTitle.font = UIFont.boldSystemFont(ofSize: 20)
        searchTitle.text = item.searchTitle
        searchTitle.sizeToFit()

        contentView.backgroundColor = ColorUtil.theme.foregroundColor
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 5
        self.backgroundColor = ColorUtil.theme.backgroundColor

    }

    func configureLayout() {
        batch {
            contentView.addSubviews(textView, subDot, subName, thumbView, searchTitle)
            subDot.sizeAnchors == CGSize.square(size: 25)

            searchTitle.horizontalAnchors == contentView.horizontalAnchors + 8
            searchTitle.topAnchor == contentView.topAnchor + 8

            subDot.leftAnchor == contentView.leftAnchor + 8
            subName.leftAnchor == subDot.rightAnchor + 4
            subName.centerYAnchor == subDot.centerYAnchor
            subDot.topAnchor == searchTitle.bottomAnchor - 8
            
            textView.leftAnchor == contentView.leftAnchor + 8
            textView.topAnchor == subDot.bottomAnchor + 8
            textView.bottomAnchor >= contentView.bottomAnchor - 8
            
            thumbView.sizeAnchors == CGSize(width: 50, height: 50)
            thumbView.topAnchor == subDot.topAnchor
            thumbView.rightAnchor == contentView.rightAnchor - 8
            thumbView.bottomAnchor <= contentView.bottomAnchor - 8
            
            textView.rightAnchor == thumbView.leftAnchor - 8
            
        }
    }
}
