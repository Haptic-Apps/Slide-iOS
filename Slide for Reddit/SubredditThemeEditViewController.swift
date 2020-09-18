//
//  SubredditThemeEditViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/17/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

protocol SubredditThemeEditViewControllerDelegate {
    func didChangeColors(_ isAccent: Bool, color: UIColor)
}

//VC for presenting theme pickers for a specific subreddit
@available(iOS 14.0, *)
class SubredditThemeEditViewController: UIViewController, UIColorPickerViewControllerDelegate {
    
    static var changed = false
    var subreddit: String
    var primary = UILabel()
    var accent = UILabel()

    var primaryWell: UIColorWell?
    var accentWell: UIColorWell?
    
    //Delegate will handle instant color changes
    var delegate: SubredditThemeEditViewControllerDelegate

    init(subreddit: String, delegate: SubredditThemeEditViewControllerDelegate) {
        self.subreddit = subreddit
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        navigationController?.setToolbarHidden(true, animated: false)
        setupTitleView(subreddit)
    }
    
    //Configure wells and set constraints
    func configureLayout() {
        primary = UILabel().then {
            $0.backgroundColor = ColorUtil.theme.backgroundColor
            $0.textColor = ColorUtil.theme.fontColor
            $0.text = "Primary color"
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.textAlignment = .left
        }
        accent = UILabel().then {
            $0.backgroundColor = ColorUtil.theme.backgroundColor
            $0.textColor = ColorUtil.theme.fontColor
            $0.text = "Accent color"
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.textAlignment = .left
        }
        
        primaryWell = UIColorWell().then {
            $0.selectedColor = ColorUtil.getColorForSub(sub: subreddit)
            $0.supportsAlpha = false
            $0.addTarget(self, action: #selector(colorWellChangedPrimary(_:)), for: .valueChanged)
        }
        accentWell = UIColorWell().then {
            $0.selectedColor = ColorUtil.accentColorForSub(sub: subreddit)
            $0.supportsAlpha = false
            $0.addTarget(self, action: #selector(colorWellChangedAccent(_:)), for: .valueChanged)
        }

        view.addSubviews(primary, accent, primaryWell!, accentWell!)
        
        primary.topAnchor == self.view.safeTopAnchor + 16
        primary.rightAnchor == self.view.rightAnchor - 8
        primary.leftAnchor == primaryWell!.rightAnchor + 8
        primary.heightAnchor == 50
        
        primaryWell!.centerYAnchor == primary.centerYAnchor
        primaryWell!.leftAnchor == self.view.leftAnchor + 16
        
        accent.topAnchor == primary.bottomAnchor + 8
        accent.rightAnchor == self.view.rightAnchor - 8
        accent.leftAnchor == accentWell!.rightAnchor + 8
        accent.heightAnchor == 50
        
        accentWell!.centerYAnchor == accent.centerYAnchor
        accentWell!.leftAnchor == self.view.leftAnchor + 16
    }
    
    //Primary color changed, set color and call delegate
    @objc func colorWellChangedPrimary(_ sender: Any) {
        if let selected = primaryWell?.selectedColor {
            ColorUtil.setColorForSub(sub: subreddit, color: selected)
            setupTitleView(subreddit)
            delegate.didChangeColors(false, color: selected)
        }
    }

    //Accent color changed, set color and call delegate
    @objc func colorWellChangedAccent(_ sender: Any) {
        if let selected = accentWell?.selectedColor {
            ColorUtil.setAccentColorForSub(sub: subreddit, color: selected)
            delegate.didChangeColors(true, color: selected)
        }
    }
    
    //Create view for header with icon and subreddit name
    func setupTitleView(_ sub: String) {
        let label = UILabel()
        label.text = "   \(SettingValues.reduceColor ? "      " : "")\(sub)"
        label.textColor = SettingValues.reduceColor ? ColorUtil.theme.fontColor : .white
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 20)
        
        if SettingValues.reduceColor {
            let sideView = UIImageView(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
            let subreddit = sub
            sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
            
            if let icon = Subscriptions.icon(for: subreddit) {
                sideView.contentMode = .scaleAspectFill
                sideView.image = UIImage()
                sideView.sd_setImage(with: URL(string: icon.unescapeHTML), completed: nil)
            } else {
                sideView.contentMode = .center
                if subreddit.contains("m/") {
                    sideView.image = SubredditCellView.defaultIconMulti
                } else if subreddit.lowercased() == "all" {
                    sideView.image = SubredditCellView.allIcon
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if subreddit.lowercased() == "frontpage" {
                    sideView.image = SubredditCellView.frontpageIcon
                    sideView.backgroundColor = GMColor.green500Color()
                } else if subreddit.lowercased() == "popular" {
                    sideView.image = SubredditCellView.popularIcon
                    sideView.backgroundColor = GMColor.purple500Color()
                } else {
                    sideView.image = SubredditCellView.defaultIcon
                }
            }
            
            label.addSubview(sideView)
            sideView.sizeAnchors == CGSize.square(size: 30)
            sideView.centerYAnchor == label.centerYAnchor
            sideView.leftAnchor == label.leftAnchor

            sideView.layer.cornerRadius = 15
            sideView.clipsToBounds = true
        }
        
        label.sizeToFit()
        self.navigationItem.titleView = label
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = subreddit
        configureLayout()
    }
}
