//
//  SettingsWelcome.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/27/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import Anchorage

class SettingsWelcome: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var pages = [UIViewController]()
    let pageControl = UIPageControl()
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doToolbar()
    }
    
    func doToolbar() {
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.isHidden = true
        navigationController?.setToolbarHidden(false, animated: false)
        
        self.pageControl.currentPageIndicatorTintColor = ColorUtil.fontColor
        self.pageControl.pageIndicatorTintColor = ColorUtil.fontColor.withAlphaComponent(0.4)
        self.pageControl.currentPage = current
        
        if current == pages.count - 1 {
            let start = UIButton.init(type: .system)
            start.setTitle("LET'S GO!", for: .normal)
            start.titleLabel?.textColor = ColorUtil.fontColor
            start.setTitleColor(ColorUtil.fontColor, for: .normal)
            
            start.addTarget(self, action: #selector(self.skip(_:)), for: UIControlEvents.touchUpInside)
            let startB = UIBarButtonItem.init(customView: start)
            let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            
            toolbarItems = [flexButton, startB]
        } else {
            let skip = UIButton.init(type: .system)
            skip.setTitle("SKIP", for: .normal)
            skip.titleLabel?.textColor = ColorUtil.fontColor
            skip.setTitleColor(ColorUtil.fontColor, for: .normal)
            
            skip.addTarget(self, action: #selector(self.skip(_:)), for: UIControlEvents.touchUpInside)
            let skipB = UIBarButtonItem.init(customView: skip)
            
            let next = UIButton.init(type: .system)
            next.setTitle("CONTINUE", for: .normal)
            next.titleLabel?.textColor = ColorUtil.fontColor
            next.setTitleColor(ColorUtil.fontColor, for: .normal)
            
            next.addTarget(self, action: #selector(self.next(_:)), for: UIControlEvents.touchUpInside)
            let nextB = UIBarButtonItem.init(customView: next)
            
            let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            
            toolbarItems = [skipB, flexButton, nextB]
        }
        
        self.navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
    }

    func skip(_ sender: AnyObject) {
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.synchronize()
        navigationController?.navigationBar.isHidden = false

        self.navigationController?.popViewController(animated: false)
        self.navigationController?.pushViewController(MainViewController(), animated: false)
    }
    
    var current = 0
    
    func next(_ sender: AnyObject) {
        current += 1
        setViewControllers([pages[current]], direction: .forward, animated: true, completion: nil)
        doToolbar()
    }
    
    func close(_ sender: AnyObject) {
        SubredditReorderViewController.changed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        
        self.pages.append(SettingsWelcomeStart())
        self.pages.append(SettingsWelcomeTheme(parent: self))
        self.pages.append(SettingsWelcomeLayout(parent: self))
        self.pages.append(SettingsWelcomeMisc(parent: self))

        setViewControllers([pages[0]], direction: .forward, animated: true, completion: nil)
        // pageControl
        self.pageControl.frame = CGRect()
        self.pageControl.currentPageIndicatorTintColor = ColorUtil.fontColor
        self.pageControl.pageIndicatorTintColor = ColorUtil.fontColor.withAlphaComponent(0.4)
        self.pageControl.numberOfPages = self.pages.count
        self.pageControl.currentPage = 0
        self.view.addSubview(self.pageControl)
        
        self.pageControl.bottomAnchor == self.view.safeBottomAnchor - 16
        self.pageControl.centerXAnchor == self.view.centerXAnchor
        self.pageControl.horizontalAnchors == self.view.horizontalAnchors
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        // set the pageControl.currentPage to the index of the current viewController in pages
        if let viewControllers = pageViewController.viewControllers {
            if let viewControllerIndex = self.pages.index(of: viewControllers[0]) {
                self.pageControl.currentPage = viewControllerIndex
            }
        }
    }
}

class SettingsWelcomeTheme: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doCells()
    }
    
    override func loadView() {
        super.loadView()
    }
    
    var parentVC: SettingsWelcome
    
    init(parent: SettingsWelcome) {
        self.parentVC = parent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var iOS = UIButton()
    var blue = UIButton()
    var dark = UIButton()
    
    func doCells() {
        self.view.backgroundColor = ColorUtil.backgroundColor
        
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        
        //iOS theme
        let about = UILabel.init(frame: CGRect.init(x: 48, y: 70, width: self.view.frame.size.width - 96, height: 100))
        about.textColor = ColorUtil.fontColor
        about.font = UIFont.boldSystemFont(ofSize: 26)
        about.text = "Choose a theme to get started"
        about.textAlignment = .center
        about.numberOfLines = 0
        about.lineBreakMode = .byWordWrapping
        self.view.addSubview(about)
        
        iOS = UIButton(frame: CGRect.init(x: 48, y: 270, width: self.view.frame.size.width - 96, height: 45))
        iOS.backgroundColor = .white
        iOS.layer.cornerRadius = 22.5
        iOS.clipsToBounds = true
        iOS.setTitle("  iOS", for: .normal)
        iOS.leftImage(image: (UIImage.init(named: "colors")?.navIcon().getCopy(withColor: GMColor.blue500Color()))!, renderMode: UIImageRenderingMode.alwaysOriginal)
        iOS.elevate(elevation: 2)
        iOS.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        iOS.setTitleColor(GMColor.blue500Color(), for: .normal)
        iOS.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
        self.view.addSubview(iOS)
        
        iOS.addTapGestureRecognizer {
            self.setiOS()
        }
        
        iOS.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.iOS.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: nil)
        
        //Dark theme
        dark = UIButton(frame: CGRect.init(x: 48, y: 340, width: self.view.frame.size.width - 96, height: 45))
        dark.backgroundColor = ColorUtil.Theme.DARK.foregroundColor
        dark.layer.cornerRadius = 22.5
        dark.clipsToBounds = true
        dark.setTitle("  Dark material", for: .normal)
        dark.leftImage(image: (UIImage.init(named: "colors")?.navIcon().getCopy(withColor: ColorUtil.Theme.DARK.fontColor))!, renderMode: UIImageRenderingMode.alwaysOriginal)
        dark.elevate(elevation: 2)
        dark.titleLabel?.font = FontGenerator.Font.ROBOTO_BOLD.font.withSize(18)
        dark.setTitleColor(ColorUtil.Theme.DARK.fontColor, for: .normal)
        dark.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
        self.view.addSubview(dark)
        
        dark.addTapGestureRecognizer {
            self.setDark()
        }
        
        dark.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.dark.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: nil)
        
        //Blue theme
        blue = UIButton(frame: CGRect.init(x: 48, y: 410, width: self.view.frame.size.width - 96, height: 45))
        blue.backgroundColor = ColorUtil.Theme.BLUE.foregroundColor
        blue.layer.cornerRadius = 22.5
        blue.clipsToBounds = true
        blue.setTitle("  Deep blue", for: .normal)
        blue.leftImage(image: (UIImage.init(named: "colors")?.navIcon().getCopy(withColor: ColorUtil.Theme.BLUE.fontColor))!, renderMode: UIImageRenderingMode.alwaysOriginal)
        blue.elevate(elevation: 2)
        blue.titleLabel?.font = FontGenerator.Font.HELVETICA.font.withSize(18)
        blue.setTitleColor(ColorUtil.Theme.BLUE.fontColor, for: .normal)
        blue.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
        self.view.addSubview(blue)
        
        blue.addTapGestureRecognizer {
            self.setBlue()
        }
        
        blue.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.blue.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: nil)
        
        self.navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
        self.view.backgroundColor = ColorUtil.backgroundColor
    }
    
    func setiOS() {
        UserDefaults.standard.set(ColorUtil.Theme.LIGHT.rawValue, forKey: "theme")
        UserDefaults.standard.setColor(color: GMColor.blue500Color(), forKey: "basecolor")
        UserDefaults.standard.setColor(color: GMColor.lightBlueA400Color(), forKey: "accentcolor")
        UserDefaults.standard.set(FontGenerator.Font.SYSTEM.rawValue, forKey: "postfont")
        UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "commentfont")
        SettingValues.viewType = false
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.set(false, forKey: SettingValues.pref_viewType)
        UserDefaults.standard.synchronize()
        _ = ColorUtil.doInit()
        doCells()
        parentVC.doToolbar()
    }
    
    func setDark() {
        UserDefaults.standard.set(ColorUtil.Theme.DARK.rawValue, forKey: "theme")
        UserDefaults.standard.set(FontGenerator.Font.ROBOTO_BOLD.rawValue, forKey: "postfont")
        UserDefaults.standard.set(FontGenerator.Font.ROBOTO_MEDIUM.rawValue, forKey: "commentfont")
        UserDefaults.standard.setColor(color: GMColor.yellowA400Color(), forKey: "accentcolor")
        UserDefaults.standard.set(true, forKey: "firstOpen")
        SettingValues.viewType = true
        UserDefaults.standard.set(true, forKey: SettingValues.pref_viewType)
        UserDefaults.standard.synchronize()
        _ = ColorUtil.doInit()
        doCells()
        parentVC.doToolbar()
    }
    
    func setBlue() {
        UserDefaults.standard.set(ColorUtil.Theme.BLUE.rawValue, forKey: "theme")
        UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "postfont")
        UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "commentfont")
        UserDefaults.standard.setColor(color: GMColor.blueGrey800Color(), forKey: "basecolor")
        UserDefaults.standard.setColor(color: GMColor.lightBlueA400Color(), forKey: "accentcolor")
        SettingValues.viewType = false
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.set(false, forKey: SettingValues.pref_viewType)
        UserDefaults.standard.synchronize()
        _ = ColorUtil.doInit()
        doCells()
        parentVC.doToolbar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doCells()
    }
}

class SettingsWelcomeStart: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doLayout()
    }
    
    func doLayout() {
        self.view.backgroundColor = ColorUtil.backgroundColor
        let about = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width - 96, height: 100))
        about.textColor = ColorUtil.fontColor
        about.textAlignment = .center
        let attributedTitle = NSMutableAttributedString(string: "Welcome to Slide!", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 26), NSForegroundColorAttributeName: ColorUtil.fontColor])
        attributedTitle.appendString("\n")
        attributedTitle.append(NSAttributedString(string: "Let's get started", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: ColorUtil.fontColor]))
        about.numberOfLines = 0
        about.attributedText = attributedTitle
        self.view.addSubview(about)
        
        let icon = UIImageView(image: UIImage(named: "roundicon"))
        self.view.addSubview(icon)
        
        icon.widthAnchor == 128
        icon.heightAnchor == 128
        icon.centerAnchors == self.view.centerAnchors
        
        about.topAnchor == icon.bottomAnchor + 24
        about.horizontalAnchors == self.view.horizontalAnchors
    }
}

class SettingsWelcomeLayout: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doCells()
    }
    
    override func loadView() {
        super.loadView()
    }
    
    var parentVC: SettingsWelcome
    
    init(parent: SettingsWelcome) {
        self.parentVC = parent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var card = UIImageView()
    var list = UIImageView()
    var compact = UIImageView()
    
    func doCells() {
        self.view.backgroundColor = ColorUtil.backgroundColor
        
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        
        let about = UILabel.init(frame: CGRect.init(x: 48, y: 40, width: self.view.frame.size.width - 96, height: 100))
        about.textColor = ColorUtil.fontColor
        about.textAlignment = .center
        about.numberOfLines = 0
        about.lineBreakMode = .byWordWrapping
        let attributedTitle = NSMutableAttributedString(string: "Choose a view mode", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 26), NSForegroundColorAttributeName: ColorUtil.fontColor])
        attributedTitle.appendString("\n")
        attributedTitle.append(NSAttributedString(string: "This can be changed later in Settings!", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: ColorUtil.fontColor]))
        about.attributedText = attributedTitle
        self.view.addSubview(about)
        
        let isCard = SettingValues.postViewMode == .CARD
        let isList = SettingValues.postViewMode == .LIST
        let isCompact = SettingValues.postViewMode == .COMPACT
        
        card = UIImageView().then {
            $0.image = UIImage(named: "card-1")?.getCopy(withColor: isCard ? ColorUtil.baseAccent : ColorUtil.fontColor)
            $0.contentMode = .scaleAspectFit
        }
        
        let cardLabel = UILabel().then {
            $0.text = "Card view"
            $0.font = UIFont.boldSystemFont(ofSize: 13)
            $0.textColor = ColorUtil.fontColor
            $0.sizeToFit()
        }
        
        list = UIImageView().then {
            $0.image = UIImage(named: "list-1")?.getCopy(withColor: isList ? ColorUtil.baseAccent : ColorUtil.fontColor)
            $0.contentMode = .scaleAspectFit
        }
        let listLabel = UILabel().then {
            $0.text = "List view"
            $0.font = UIFont.boldSystemFont(ofSize: 13)
            $0.textColor = ColorUtil.fontColor
            $0.sizeToFit()
        }

        compact = UIImageView().then {
            $0.image = UIImage(named: "compact-1")?.getCopy(withColor: isCompact ? ColorUtil.baseAccent : ColorUtil.fontColor)
            $0.contentMode = .scaleAspectFit
        }
        let compactLabel = UILabel().then {
            $0.text = "Compact view"
            $0.font = UIFont.boldSystemFont(ofSize: 13)
            $0.textColor = ColorUtil.fontColor
            $0.sizeToFit()
        }
        
        self.view.addSubviews(card, cardLabel, list, listLabel, compact, compactLabel)
        
        card.centerXAnchor == self.view.centerXAnchor
        card.topAnchor == about.bottomAnchor - 8
        card.widthAnchor == 175
        card.heightAnchor == 175
        card.addTapGestureRecognizer {
            self.setCard()
        }
        
        cardLabel.centerXAnchor == self.view.centerXAnchor
        cardLabel.topAnchor == card.bottomAnchor - 8

        list.centerXAnchor == self.view.centerXAnchor
        list.topAnchor == cardLabel.bottomAnchor + 16
        list.widthAnchor == 175
        list.heightAnchor == 100
        list.addTapGestureRecognizer {
            self.setList()
        }
        
        listLabel.centerXAnchor == self.view.centerXAnchor
        listLabel.topAnchor == list.bottomAnchor - 8

        compact.centerXAnchor == self.view.centerXAnchor
        compact.topAnchor == listLabel.bottomAnchor + 16
        compact.widthAnchor == 175
        compact.heightAnchor == 90
        compact.addTapGestureRecognizer {
            self.setCompact()
        }

        compactLabel.centerXAnchor == self.view.centerXAnchor
        compactLabel.topAnchor == compact.bottomAnchor - 8

        self.navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
        self.view.backgroundColor = ColorUtil.backgroundColor
    }
    
    func setCard() {
        UserDefaults.standard.set("card", forKey: SettingValues.pref_postViewMode)
        SettingValues.postViewMode = .CARD
        UserDefaults.standard.synchronize()
        SingleSubredditViewController.cellVersion += 1
        doCells()
    }

    func setList() {
        UserDefaults.standard.set("list", forKey: SettingValues.pref_postViewMode)
        SettingValues.postViewMode = .LIST
        UserDefaults.standard.synchronize()
        SingleSubredditViewController.cellVersion += 1
        doCells()
    }
    
    func setCompact() {
        UserDefaults.standard.set("compact", forKey: SettingValues.pref_postViewMode)
        SettingValues.postViewMode = .COMPACT
        UserDefaults.standard.synchronize()
        SingleSubredditViewController.cellVersion += 1
        doCells()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        switch SettingValues.postViewMode {
        case .LIST:
            UserDefaults.standard.set("thumbnail", forKey: SettingValues.pref_postImageMode)
            SettingValues.postImageMode = .THUMBNAIL
            SettingValues.abbreviateScores = true
            UserDefaults.standard.set(true, forKey: SettingValues.pref_abbreviateScores)
            UserDefaults.standard.synchronize()
        case .COMPACT:
            UserDefaults.standard.set("thumbnail", forKey: SettingValues.pref_postImageMode)
            SettingValues.postImageMode = .THUMBNAIL
            UserDefaults.standard.set("right", forKey: SettingValues.pref_actionbarMode)
            SettingValues.actionBarMode = .SIDE_RIGHT
            SettingValues.abbreviateScores = true
            UserDefaults.standard.set(true, forKey: SettingValues.pref_abbreviateScores)
            UserDefaults.standard.synchronize()
        default:
            break
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        doCells()
    }
}

class SettingsWelcomeMisc: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doCells()
    }
    
    override func loadView() {
        super.loadView()
    }
    
    var parentVC: SettingsWelcome
    
    init(parent: SettingsWelcome) {
        self.parentVC = parent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var tabs = UISwitch()
    var history = UISwitch()
    var data = UISwitch()
    
    func doCells() {
        self.view.backgroundColor = ColorUtil.backgroundColor
        
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        
        //iOS theme
        let about = UILabel.init(frame: CGRect.init(x: 48, y: 70, width: self.view.frame.size.width - 96, height: 100))
        about.textColor = ColorUtil.fontColor
        about.textAlignment = .center
        about.numberOfLines = 0
        about.lineBreakMode = .byWordWrapping
        let attributedTitle = NSMutableAttributedString(string: "Other settings", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 26), NSForegroundColorAttributeName: ColorUtil.fontColor])
        attributedTitle.appendString("\n")
        attributedTitle.append(NSAttributedString(string: "These can be changed later in Settings!", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: ColorUtil.fontColor]))
        about.attributedText = attributedTitle

        self.view.addSubview(about)
        
        let tabsLabel = UILabel().then {
            $0.textColor = ColorUtil.fontColor
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.text = "Enable paged subreddit mode with a tab toolbar"
            $0.numberOfLines = 0
        }
        tabs = UISwitch().then {
            $0.isOn = SettingValues.viewType
            $0.onTintColor = ColorUtil.baseAccent
            $0.addTarget(self, action: #selector(SettingsWelcomeMisc.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        }
        
        let dataLabel = UILabel().then {
            $0.textColor = ColorUtil.fontColor
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.text = "Enable data saving mode"
            $0.numberOfLines = 0
        }
        data = UISwitch().then {
            $0.isOn = SettingValues.dataSavingEnabled
            $0.onTintColor = ColorUtil.baseAccent
            $0.addTarget(self, action: #selector(SettingsWelcomeMisc.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        }

        let historyLabel = UILabel().then {
            $0.textColor = ColorUtil.fontColor
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.text = "Enable local subreddit and post history to be saved"
            $0.numberOfLines = 0
        }
        history = UISwitch().then {
            $0.isOn = SettingValues.saveHistory
            $0.onTintColor = ColorUtil.baseAccent
            $0.addTarget(self, action: #selector(SettingsWelcomeMisc.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        }
        
        self.view.addSubviews(tabsLabel, tabs, dataLabel, data, historyLabel, history)
        
        tabsLabel.topAnchor == about.bottomAnchor + 24
        tabsLabel.leftAnchor == self.view.leftAnchor + 24
        tabsLabel.rightAnchor == self.tabs.leftAnchor - 8
        self.tabs.rightAnchor == self.view.rightAnchor - 24
        self.tabs.centerYAnchor == tabsLabel.centerYAnchor
        self.tabs.widthAnchor == 50
        
        dataLabel.topAnchor == tabs.bottomAnchor + 24
        dataLabel.leftAnchor == self.view.leftAnchor + 24
        dataLabel.rightAnchor == self.data.leftAnchor - 8
        self.data.rightAnchor == self.view.rightAnchor - 24
        self.data.centerYAnchor == dataLabel.centerYAnchor
        self.data.widthAnchor == 50

        historyLabel.topAnchor == data.bottomAnchor + 24
        historyLabel.leftAnchor == self.view.leftAnchor + 24
        historyLabel.rightAnchor == self.history.leftAnchor - 8
        self.history.rightAnchor == self.view.rightAnchor - 24
        self.history.centerYAnchor == historyLabel.centerYAnchor
        self.history.widthAnchor == 50

        self.navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
        self.view.backgroundColor = ColorUtil.backgroundColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doCells()
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if changed == tabs {
            SettingValues.viewType = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_viewType)
        } else if changed == history {
            SettingValues.saveHistory = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_saveHistory)
        } else {
            SettingValues.dataSavingEnabled = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_dataSavingEnabled)
        }
        UserDefaults.standard.synchronize()
    }
}
