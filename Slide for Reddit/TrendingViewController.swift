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
    var spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)

    var taskSearches: DataRequest?
    var taskSubs: DataRequest?
    
    func loadData() {
        
        spinnerIndicator.color = ColorUtil.theme.fontColor
        self.tableView.addSubview(spinnerIndicator)
        spinnerIndicator.centerAnchors == self.tableView.centerAnchors
        spinnerIndicator.sizeAnchors == CGSize(width: 75, height: 75)
        spinnerIndicator.startAnimating()

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
                            let linkData = searchLinkJSON["results"]["data"]["children"].array?[0]["data"]
                            
                            searchItem.imageUrl = linkData?["thumbnail"].stringValue ?? ""
                            searchItem.title = linkData?["title"].stringValue ?? ""
                            searchItem.subreddit = linkData?["subreddit"].stringValue ?? ""
                            searchItem.imageUrl = linkData?["thumbnail"].stringValue ?? ""
                            searchItem.searchTerm = searchLinkJSON["query_string"].stringValue ?? ""
                            searchItem.searchTitle = searchLinkJSON["display_string"].stringValue ?? ""
                            self.trendingSearches.append(searchItem)
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.spinnerIndicator.stopAnimating()
                            self.spinnerIndicator.isHidden = true
                            self.spinnerIndicator.removeFromSuperview()
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 14, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 24, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.theme.backgroundColor
        
        switch section {
        case 0: label.text = "Trending Topics"
        case 1: label.text = "Trending Subreddits"
        default: label.text = ""
        }
        return toReturn
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return trendingSearches.isEmpty ? 0 : 30
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.register(TrendingCellView.classForCoder(), forCellReuseIdentifier: "trending")
        self.tableView.backgroundColor = ColorUtil.theme.backgroundColor
                
        //TODO show loading indicator
        tableView.reloadData()
        
        self.tableView.tableFooterView = UIView()
        
        loadData()
    }
        
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            VCPresenter.openRedditLink("https://reddit.com/r/all/search?q=\(trendingSearches[indexPath.row].searchTerm)", nil, self)
        } else {
            VCPresenter.openRedditLink("https://reddit.com/r/\(trendingSubs[indexPath.row])", nil, self)
        }
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
        return section == 0 ? trendingSearches.count : (trendingSearches.count == 0 ? 0 : trendingSubs.count)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
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
    var innerView = UIView()
    
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

        self.backgroundColor = ColorUtil.theme.backgroundColor
        contentView.backgroundColor = ColorUtil.theme.backgroundColor

        innerView.backgroundColor = ColorUtil.theme.foregroundColor
    }

    func configureLayout() {
        batch {
            contentView.addSubview(innerView)
            innerView.topAnchor == contentView.topAnchor + 2.5
            innerView.bottomAnchor == contentView.bottomAnchor
            innerView.leftAnchor == contentView.leftAnchor
            innerView.rightAnchor == contentView.rightAnchor
            
            innerView.addSubviews(textView, subDot, subName, thumbView, searchTitle)
            subDot.sizeAnchors == CGSize.square(size: 25)

            searchTitle.horizontalAnchors == innerView.horizontalAnchors + 16
            searchTitle.topAnchor == innerView.topAnchor + 12

            subDot.leftAnchor == innerView.leftAnchor + 16
            subName.leftAnchor == subDot.rightAnchor + 4
            subName.centerYAnchor == subDot.centerYAnchor
            subDot.topAnchor == searchTitle.bottomAnchor + 8
            
            textView.leftAnchor == innerView.leftAnchor + 16
            textView.topAnchor == subDot.bottomAnchor + 8
            textView.bottomAnchor <= innerView.bottomAnchor - 12
            
            thumbView.sizeAnchors == CGSize(width: 65, height: 65)
            thumbView.topAnchor == searchTitle.bottomAnchor + 8
            thumbView.rightAnchor == innerView.rightAnchor - 8
            thumbView.bottomAnchor <= innerView.bottomAnchor - 12
            
            textView.rightAnchor == thumbView.leftAnchor - 8
        }
    }
}
