//
//  ReadLaterViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/29/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import RLBAlertsPickers
import UIKit

class ReadLaterViewController: ContentListingViewController {
    
    var sub = ""
    init(subreddit: String) {
        let dataSource = ReadLaterContributionLoader(sub: "all")
        super.init(dataSource: dataSource)
        baseData.delegate = self

//        if subreddit == "all" {
            self.title = "Read Later"
//        } else {
//            self.navigationItem.titleView = setTitle(title: "Read Later", subtitle: "r/\(subreddit)")
//        }
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
        sub = subreddit
//        if subreddit != "all" {
//            BannerUtil.makeBanner(text: "Click to see all Read Later items", color: ColorUtil.baseAccent, seconds: 0, context: self, top: false) {
//                self.sub = "all"
//                dataSource.sub = "all"
//                self.refresh()
//                self.title = "Read Later"
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let doneall = UIButton.init(type: .custom)
        doneall.setImage(UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "doneall")?.navIcon(), for: UIControl.State.normal)
        doneall.addTarget(self, action: #selector(self.doneAll), for: UIControl.Event.touchUpInside)
        doneall.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let doneallB = UIBarButtonItem.init(customView: doneall)
        
        self.navigationItem.rightBarButtonItem = doneallB
    }
    
    @objc func doneAll() {
        let alert = UIAlertController(title: "Really mark all as read?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
            for item in self.baseData.content {
                ReadLater.removeReadLater(id: item.getId())
            }
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension UIViewController {

    // https://gist.github.com/migueltg/7779fe93aec48394a39cfdf6cbcfd99b
    // Function to set title and subtitle in navigation bar
    func setTitle(title: String, subtitle: String) -> UIView {

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.fontColor
        titleLabel.textAlignment = .center
        titleLabel.sizeToFit()

        let subTitleLabel = UILabel()
        subTitleLabel.text = subtitle
        subTitleLabel.font = UIFont.systemFont(ofSize: 11)
        subTitleLabel.textColor = UIColor.fontColor
        subTitleLabel.textAlignment = .center
        subTitleLabel.lineBreakMode = .byTruncatingTail
        subTitleLabel.sizeToFit()

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        stackView.distribution = .fillProportionally
        stackView.axis = .vertical

        let width = max(titleLabel.frame.size.width, subTitleLabel.frame.size.width)
        stackView.frame = CGRect(x: 0, y: 0, width: width, height: 45)

        titleLabel.sizeToFit()
        subTitleLabel.sizeToFit()
        
        stackView.heightAnchor /==/ 45

        return stackView
    }

}
