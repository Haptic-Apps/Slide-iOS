//
//  SettingsWelcome.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/27/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

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
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        
        if ColorUtil.theme.isLight() {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }

        if current == pages.count - 1 {
            let start = UIButton.init(type: .system)
            start.setTitle("LET'S GO!", for: .normal)
            start.titleLabel?.textColor = ColorUtil.fontColor
            start.setTitleColor(ColorUtil.fontColor, for: .normal)
            
            start.addTarget(self, action: #selector(self.skip(_:)), for: UIControl.Event.touchUpInside)
            let startB = UIBarButtonItem.init(customView: start)
            let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
            start.sizeToFit()
            toolbarItems = [flexButton, startB]
        } else {
            let skip = UIButton.init(type: .system)
            skip.setTitle("SKIP", for: .normal)
            skip.titleLabel?.textColor = ColorUtil.fontColor
            skip.setTitleColor(ColorUtil.fontColor, for: .normal)
            skip.sizeToFit()
            skip.addTarget(self, action: #selector(self.skip(_:)), for: UIControl.Event.touchUpInside)
            let skipB = UIBarButtonItem.init(customView: skip)
            
            let next = UIButton.init(type: .system)
            next.setTitle("CONTINUE", for: .normal)
            next.titleLabel?.textColor = ColorUtil.fontColor
            next.setTitleColor(ColorUtil.fontColor, for: .normal)
            next.sizeToFit()
            next.addTarget(self, action: #selector(self.next(_:)), for: UIControl.Event.touchUpInside)
            let nextB = UIBarButtonItem.init(customView: next)
            
            let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
            
            toolbarItems = [skipB, flexButton, nextB]
        }
        
        self.navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
    }

    @objc func skip(_ sender: AnyObject) {
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.synchronize()
        navigationController?.navigationBar.isHidden = false

        self.navigationController?.viewControllers = [MainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)]
        self.dismiss(animated: true, completion: nil)
    }
    
    var current = 0
    
    @objc func next(_ sender: AnyObject) {
        current += 1
        setViewControllers([pages[current]], direction: .forward, animated: true, completion: nil)
        doToolbar()
    }
    
    @objc func close(_ sender: AnyObject) {
        SubredditReorderViewController.changed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        
        self.pages.append(SettingsWelcomeStart())
        self.pages.append(SettingsWelcomeTheme(parent: self))
        //self.pages.append(SettingsWelcomeLayout(parent: self))

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
        
        if #available(iOS 11, *) {} else {
            self.edgesForExtendedLayout = []
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        // set the pageControl.currentPage to the index of the current viewController in pages
        if let viewControllers = pageViewController.viewControllers {
            if let viewControllerIndex = self.pages.index(of: viewControllers[0]) {
                self.pageControl.currentPage = viewControllerIndex
                current = viewControllerIndex
                self.doToolbar()
            }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = self.pages.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard self.pages.count > previousIndex else {
            return nil
        }
        
        return self.pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = self.pages.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = self.pages.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return self.pages[nextIndex]
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
    var deep = UIButton()

    func doCells() {
        self.view.backgroundColor = ColorUtil.backgroundColor
        
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        
        //iOS theme
        let about = UILabel.init(frame: CGRect.init(x: 48, y: 70, width: self.view.frame.size.width - 96, height: 150))
        about.textColor = ColorUtil.fontColor
        about.font = UIFont.boldSystemFont(ofSize: 26)
        let attributedTitle = NSMutableAttributedString(string: "Choose a theme to get started!", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 26), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor]))
        attributedTitle.appendString("\n")
        attributedTitle.append(NSAttributedString(string: "There are more themes available in Settings after setup", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor])))
        about.attributedText = attributedTitle
        about.textAlignment = .center
        about.numberOfLines = 0
        about.lineBreakMode = .byWordWrapping
        self.view.addSubview(about)
        
        let stack = UIStackView().then {
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .equalCentering
            $0.spacing = 12
            $0.accessibilityIdentifier = "Select a theme!"
        }
        
        let inner = UIView()
        self.view.addSubview(inner)
        inner.centerXAnchor == self.view.centerXAnchor
        inner.widthAnchor == 250
        inner.topAnchor == about.topAnchor
        inner.bottomAnchor == self.view.bottomAnchor + 48
        inner.addSubview(stack)

        stack.horizontalAnchors == inner.horizontalAnchors
        stack.heightAnchor == 216
        stack.centerYAnchor == inner.centerYAnchor

        iOS = UIButton(frame: CGRect.init(x: 48, y: 220, width: self.view.frame.size.width - 96, height: 45))
        iOS.backgroundColor = .white
        iOS.layer.cornerRadius = 22.5
        iOS.clipsToBounds = true
        iOS.setTitle("  Light", for: .normal)
        iOS.leftImage(image: (UIImage.init(named: "colors")?.navIcon().getCopy(withColor: GMColor.blue500Color()))!, renderMode: UIImage.RenderingMode.alwaysOriginal)
        iOS.elevate(elevation: 2)
        iOS.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        iOS.setTitleColor(GMColor.blue500Color(), for: .normal)
        iOS.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
        
        iOS.addTapGestureRecognizer {
            self.setiOS()
        }
        
        //Dark theme
        dark = UIButton(frame: CGRect.init(x: 48, y: 290, width: self.view.frame.size.width - 96, height: 45))
        dark.backgroundColor = ColorUtil.Theme.DARK.foregroundColor
        dark.layer.cornerRadius = 22.5
        dark.clipsToBounds = true
        dark.setTitle("  Dark gray", for: .normal)
        dark.leftImage(image: (UIImage.init(named: "colors")?.navIcon().getCopy(withColor: ColorUtil.Theme.DARK.fontColor))!, renderMode: UIImage.RenderingMode.alwaysOriginal)
        dark.elevate(elevation: 2)
        dark.titleLabel?.font = FontGenerator.Font.ROBOTO_BOLD.font.withSize(18)
        dark.setTitleColor(ColorUtil.Theme.DARK.fontColor, for: .normal)
        dark.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
        
        dark.addTapGestureRecognizer {
            self.setDark()
        }
        
        //Blue theme
        blue = UIButton(frame: CGRect.init(x: 48, y: 360, width: self.view.frame.size.width - 96, height: 45))
        blue.backgroundColor = ColorUtil.Theme.BLUE.foregroundColor
        blue.layer.cornerRadius = 22.5
        blue.clipsToBounds = true
        blue.setTitle("  Deep blue", for: .normal)
        blue.leftImage(image: (UIImage.init(named: "colors")?.navIcon().getCopy(withColor: ColorUtil.Theme.BLUE.fontColor))!, renderMode: UIImage.RenderingMode.alwaysOriginal)
        blue.elevate(elevation: 2)
        blue.titleLabel?.font = FontGenerator.Font.HELVETICA.font.withSize(18)
        blue.setTitleColor(ColorUtil.Theme.BLUE.fontColor, for: .normal)
        blue.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
        
        blue.addTapGestureRecognizer {
            self.setBlue()
        }
        
        //Deep theme
        deep = UIButton(frame: CGRect.init(x: 48, y: 430, width: self.view.frame.size.width - 96, height: 45))
        deep.backgroundColor = ColorUtil.Theme.DEEP.foregroundColor
        deep.layer.cornerRadius = 22.5
        deep.clipsToBounds = true
        deep.setTitle("  Dark Purple", for: .normal)
        deep.leftImage(image: (UIImage.init(named: "colors")?.navIcon().getCopy(withColor: ColorUtil.Theme.DEEP.fontColor))!, renderMode: UIImage.RenderingMode.alwaysOriginal)
        deep.elevate(elevation: 2)
        deep.titleLabel?.font = FontGenerator.Font.HELVETICA.font.withSize(18)
        deep.setTitleColor(ColorUtil.Theme.DEEP.fontColor, for: .normal)
        deep.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
        
        deep.addTapGestureRecognizer {
            self.setDeep()
        }
        
        stack.addArrangedSubviews(iOS, dark, blue, deep)
        
        dark.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.dark.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: nil)
        
        dark.heightAnchor == 45
        blue.heightAnchor == 45
        deep.heightAnchor == 45
        iOS.heightAnchor == 45
        dark.horizontalAnchors == stack.horizontalAnchors
        blue.horizontalAnchors == stack.horizontalAnchors
        deep.horizontalAnchors == stack.horizontalAnchors
        iOS.horizontalAnchors == stack.horizontalAnchors

        blue.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.blue.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: nil)

        deep.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.deep.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: nil)
        
        iOS.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.iOS.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
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
        SettingValues.subredditBar = true
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.set(true, forKey: SettingValues.pref_viewType)
        UserDefaults.standard.synchronize()
        _ = ColorUtil.doInit()
        doCells()
        parentVC.doToolbar()
    }
    
    func setDark() {
        UserDefaults.standard.set(ColorUtil.Theme.DARK.rawValue, forKey: "theme")
        UserDefaults.standard.setColor(color: GMColor.blueA400Color(), forKey: "accentcolor")
        UserDefaults.standard.set(true, forKey: "firstOpen")
        SettingValues.subredditBar = true
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
        SettingValues.subredditBar = true
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.set(true, forKey: SettingValues.pref_viewType)
        UserDefaults.standard.synchronize()
        _ = ColorUtil.doInit()
        doCells()
        parentVC.doToolbar()
    }
    
    func setDeep() {
        UserDefaults.standard.set(ColorUtil.Theme.DEEP.rawValue, forKey: "theme")
        UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "postfont")
        UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "commentfont")
        UserDefaults.standard.setColor(color: GMColor.deepPurple600Color(), forKey: "basecolor")
        UserDefaults.standard.setColor(color: GMColor.pinkA400Color(), forKey: "accentcolor")
        SettingValues.subredditBar = true
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.set(true, forKey: SettingValues.pref_viewType)
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
        let attributedTitle = NSMutableAttributedString(string: "Welcome to Slide!", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 26), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor]))
        attributedTitle.appendString("\n")
        attributedTitle.append(NSAttributedString(string: "Let's get started", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor])))
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
        let attributedTitle = NSMutableAttributedString(string: "Choose a view mode", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 26), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor]))
        attributedTitle.appendString("\n")
        attributedTitle.append(NSAttributedString(string: "This can be changed later in Settings!", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor])))
        about.attributedText = attributedTitle
        self.view.addSubview(about)
        
        let isCard = SettingValues.postViewMode == .CARD
        let isList = SettingValues.postViewMode == .LIST
        let isCompact = SettingValues.postViewMode == .COMPACT
        
        let stack = UIStackView().then {
            $0.axis = .vertical
            $0.alignment = .center
            $0.spacing = 5
            $0.accessibilityIdentifier = "Select a layout type!"
        }
        
        let inner = UIView()
        self.view.addSubview(inner)
        
        inner.horizontalAnchors == self.view.horizontalAnchors + 16
        inner.topAnchor == about.topAnchor
        inner.bottomAnchor == self.view.bottomAnchor + 48
        inner.addSubview(stack)
        
        stack.horizontalAnchors == inner.horizontalAnchors
        stack.centerYAnchor == inner.centerYAnchor

        card = UIImageView().then {
            $0.image = UIImage(named: "card-1")?.getCopy(withColor: isCard ? ColorUtil.baseAccent : ColorUtil.fontColor)
            $0.contentMode = .scaleAspectFit
        }
        
        let cardLabel = UILabel().then {
            $0.text = "Card view with banner images"
            $0.font = UIFont.boldSystemFont(ofSize: 13)
            $0.textColor = ColorUtil.fontColor
            $0.sizeToFit()
        }
        
        cardLabel.heightAnchor == 15
        
        list = UIImageView().then {
            $0.image = UIImage(named: "list-1")?.getCopy(withColor: isList ? ColorUtil.baseAccent : ColorUtil.fontColor)
            $0.contentMode = .scaleAspectFit
        }
        let listLabel = UILabel().then {
            $0.text = "List view with thumbnails"
            $0.font = UIFont.boldSystemFont(ofSize: 13)
            $0.textColor = ColorUtil.fontColor
            $0.sizeToFit()
        }
        
        listLabel.heightAnchor == 15

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
        
        compactLabel.heightAnchor == 15
        
        stack.addArrangedSubviews(card, cardLabel, list, listLabel, compact, compactLabel)
        
        print(UIScreen.main.bounds.size.height)
        if UIScreen.main.bounds.size.height > 670 {
            stack.heightAnchor == 435
            card.centerXAnchor == stack.centerXAnchor
            card.widthAnchor == 175
            card.heightAnchor == 175
            card.addTapGestureRecognizer {
                self.setCard()
            }
            
            cardLabel.centerXAnchor == stack.centerXAnchor
            
            list.centerXAnchor == stack.centerXAnchor
            list.widthAnchor == 175
            list.heightAnchor == 100
            list.addTapGestureRecognizer {
                self.setList()
            }
            
            listLabel.centerXAnchor == stack.centerXAnchor
            
            compact.centerXAnchor == self.view.centerXAnchor
            compact.widthAnchor == 175
            compact.heightAnchor == 90
            compact.addTapGestureRecognizer {
                self.setCompact()
            }
            
            compactLabel.centerXAnchor == stack.centerXAnchor
        } else {
            stack.heightAnchor == 278
            card.centerXAnchor == stack.centerXAnchor
            card.widthAnchor == 100
            card.heightAnchor == 100
            card.addTapGestureRecognizer {
                self.setCard()
            }
            
            cardLabel.centerXAnchor == stack.centerXAnchor
            
            list.centerXAnchor == stack.centerXAnchor
            list.widthAnchor == 100
            list.heightAnchor == 57
            list.addTapGestureRecognizer {
                self.setList()
            }
            
            listLabel.centerXAnchor == stack.centerXAnchor
            
            compact.centerXAnchor == self.view.centerXAnchor
            compact.widthAnchor == 100
            compact.heightAnchor == 51
            compact.addTapGestureRecognizer {
                self.setCompact()
            }
            
            compactLabel.centerXAnchor == stack.centerXAnchor
        }

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
    var fab = UISwitch()
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
        let attributedTitle = NSMutableAttributedString(string: "Other settings", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 26), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor]))
        attributedTitle.appendString("\n")
        attributedTitle.append(NSAttributedString(string: "These can be changed later in Settings!", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 18), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor])))
        about.attributedText = attributedTitle

        self.view.addSubview(about)
        
        let tabsLabel = UILabel().then {
            $0.textColor = ColorUtil.fontColor
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.text = "Enable paged subreddit mode with a tab toolbar"
            $0.numberOfLines = 0
        }
        tabs = UISwitch().then {
            $0.isOn = SettingValues.subredditBar
            $0.onTintColor = ColorUtil.baseAccent
            $0.addTarget(self, action: #selector(SettingsWelcomeMisc.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        }

        let fabLabel = UILabel().then {
            $0.textColor = ColorUtil.fontColor
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.text = "Enable floating action button"
            $0.numberOfLines = 0
        }
        fab = UISwitch().then {
            $0.isOn = !SettingValues.hiddenFAB
            $0.onTintColor = ColorUtil.baseAccent
            $0.addTarget(self, action: #selector(SettingsWelcomeMisc.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
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
            $0.addTarget(self, action: #selector(SettingsWelcomeMisc.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
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
            $0.addTarget(self, action: #selector(SettingsWelcomeMisc.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        }
        
        self.view.addSubviews(tabsLabel, tabs,
                              fabLabel, fab,
                              dataLabel, data,
                              historyLabel, history)
        
        tabsLabel.topAnchor == about.bottomAnchor + 24
        tabsLabel.leftAnchor == self.view.leftAnchor + 24
        tabsLabel.rightAnchor == self.tabs.leftAnchor - 8
        self.tabs.rightAnchor == self.view.rightAnchor - 24
        self.tabs.centerYAnchor == tabsLabel.centerYAnchor
        self.tabs.widthAnchor == 50

        fabLabel.topAnchor == tabs.bottomAnchor + 24
        fabLabel.leftAnchor == self.view.leftAnchor + 24
        fabLabel.rightAnchor == self.fab.leftAnchor - 8
        self.fab.rightAnchor == self.view.rightAnchor - 24
        self.fab.centerYAnchor == fabLabel.centerYAnchor
        self.fab.widthAnchor == 50
        
        dataLabel.topAnchor == fab.bottomAnchor + 24
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
    
    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == tabs {
            SettingValues.subredditBar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_viewType)
        } else if changed == fab {
            SettingValues.hiddenFAB = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_hiddenFAB)
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

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
