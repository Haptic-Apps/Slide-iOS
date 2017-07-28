//
//  UZTextViewCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/6/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit

class SubredditCellView: UITableViewCell {
    var sideView: UIView = UIView()
    var title: UILabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        title.numberOfLines = 0
        title.font = FontGenerator.fontOfSize(size: 16, submission: true)
        
        self.sideView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        
        sideView.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(sideView)
        self.contentView.addSubview(title)
        
        self.clipsToBounds = true
    }
    
    func setSubreddit(subreddit: String){
        title.textColor = ColorUtil.fontColor
        self.contentView.backgroundColor = ColorUtil.foregroundColor

        self.subreddit = subreddit
        title.text = subreddit
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
        updateConstraints()
        let selectedView = UIView()
        selectedView.backgroundColor = ColorUtil.backgroundColor
        selectedBackgroundView = selectedView

    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var subreddit = ""
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let metrics=["topMargin": 0]
        let views=["title": title, "side":sideView] as [String : Any]
        
        var constraint:[NSLayoutConstraint] = []
        constraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[side(16)]-8-[title]-2-|",
                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                    metrics: metrics,
                                                    views: views)
        
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-(22)-[side(16)]-(22)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[title(56)]-2-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        self.contentView.addConstraints(constraint)
        sideView.layer.cornerRadius = 8
        sideView.clipsToBounds = true

    }
}
