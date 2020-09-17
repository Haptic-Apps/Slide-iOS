//
//  SubredditThemeEditViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/17/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

@available(iOS 14.0, *)
class SubredditThemeEditViewController: UIViewController, UIColorPickerViewControllerDelegate {
    
    static var changed = false
    var subreddit: String
    var primary = UILabel()
    var accent = UILabel()

    var primaryWell: UIColorWell?
    var accentWell: UIColorWell?


    init(subreddit: String) {
        self.subreddit = subreddit
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
        }
        accentWell = UIColorWell().then {
            $0.selectedColor = ColorUtil.accentColorForSub(sub: subreddit)
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

    func selectColor(_ primary: Bool) {
        let vc = SingleColorPickerVC(selectedColor: ColorUtil.getColorForSub(sub: subreddit), delegate: self)
        self.navigationController?.pushViewController(vc, animated: true)
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

@available(iOS 14.0, *)
extension SubredditThemeEditViewController: SelectedColorDelegate {
    func didSelect(color: UIColor) {
        
    }
}

protocol SelectedColorDelegate {
    func didSelect(color: UIColor)
}

@available(iOS 14.0, *)
class SingleColorPickerVC: UIViewController {
    var delegate: SelectedColorDelegate
    var selectedColor: UIColor
    
    init(selectedColor: UIColor, delegate: SelectedColorDelegate) {
        self.delegate = delegate
        self.selectedColor = selectedColor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        configureViews()
    }
    
    func configureViews() {
        let colorPicker = UIColorWell()
        colorPicker.selectedColor = selectedColor
        colorPicker.supportsAlpha = false
        self.view.addSubview(colorPicker)
        colorPicker.edgeAnchors == self.view.edgeAnchors
    }
}
