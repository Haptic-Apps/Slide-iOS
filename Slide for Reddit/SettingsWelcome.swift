//
//  SettingsWelcome.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/19/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

class SettingsWelcome: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.isHidden = true
        navigationController?.setToolbarHidden(false, animated: false)
        doCells()
        
        let skip = UIButton.init(type: .system)
        skip.setTitle("SKIP", for: .normal)
        skip.titleLabel?.textColor = ColorUtil.fontColor
        skip.setTitleColor(ColorUtil.fontColor, for: .normal)

        skip.addTarget(self, action: #selector(self.skip(_:)), for: UIControlEvents.touchUpInside)
        let skipB = UIBarButtonItem.init(customView: skip)
        
        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)

        toolbarItems = [flexButton, skipB]
    }
    
    override func loadView() {
        super.loadView()
    }
    
    var parentVC: MainViewController
    
    init(parent: MainViewController){
        self.parentVC = parent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var iOS = UIButton()
    var blue = UIButton()
    var dark = UIButton()
    
    func skip(_ sender: AnyObject){
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.synchronize()

        self.dismiss(animated: true, completion: nil)
    }
    
    func doCells() {
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = ""
        
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
        iOS.leftImage(image: (UIImage.init(named: "colors")?.navIcon().withColor(tintColor: GMColor.blue500Color()))!, renderMode: UIImageRenderingMode.alwaysOriginal)
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
        dark.leftImage(image: (UIImage.init(named: "colors")?.navIcon().withColor(tintColor: ColorUtil.Theme.DARK.fontColor))!, renderMode: UIImageRenderingMode.alwaysOriginal)
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
        blue.leftImage(image: (UIImage.init(named: "colors")?.navIcon().withColor(tintColor: ColorUtil.Theme.BLUE.fontColor))!, renderMode: UIImageRenderingMode.alwaysOriginal)
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


        self.view.backgroundColor = ColorUtil.backgroundColor
        self.navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
    }
    
    func setiOS(){
        UserDefaults.standard.set(ColorUtil.Theme.LIGHT.rawValue, forKey: "theme")
        UserDefaults.standard.setColor(color: GMColor.blue500Color(), forKey: "basecolor")
        UserDefaults.standard.setColor(color: GMColor.lightBlueA400Color(), forKey: "accentcolor")
        UserDefaults.standard.set(FontGenerator.Font.SYSTEM.rawValue, forKey: "postfont")
        UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "commentfont")
        SettingValues.viewType = false
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.set(false, forKey: SettingValues.pref_viewType)
        UserDefaults.standard.synchronize()
        ColorUtil.doInit()
        parentVC.hardReset()
        self.dismiss(animated: true, completion: nil)
    }
    
    func setDark(){
        UserDefaults.standard.set(ColorUtil.Theme.DARK.rawValue, forKey: "theme")
        UserDefaults.standard.set(FontGenerator.Font.ROBOTO_BOLD.rawValue, forKey: "postfont")
        UserDefaults.standard.set(FontGenerator.Font.ROBOTO_MEDIUM.rawValue, forKey: "commentfont")
        UserDefaults.standard.setColor(color: GMColor.yellowA400Color(), forKey: "accentcolor")
        UserDefaults.standard.set(true, forKey: "firstOpen")
        SettingValues.viewType = true
        UserDefaults.standard.set(true, forKey: SettingValues.pref_viewType)
        UserDefaults.standard.synchronize()
        ColorUtil.doInit()
        parentVC.hardReset()
        self.dismiss(animated: true, completion: nil)
    }
    
    func setBlue(){
        UserDefaults.standard.set(ColorUtil.Theme.BLUE.rawValue, forKey: "theme")
        UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "postfont")
        UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "commentfont")
        UserDefaults.standard.setColor(color: GMColor.blueGrey800Color(), forKey: "basecolor")
        UserDefaults.standard.setColor(color: GMColor.lightBlueA400Color(), forKey: "accentcolor")
        SettingValues.viewType = false
        UserDefaults.standard.set(true, forKey: "firstOpen")
        UserDefaults.standard.set(false, forKey: SettingValues.pref_viewType)
        UserDefaults.standard.synchronize()
        ColorUtil.doInit()
        parentVC.hardReset()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doCells()
    }
    
    
}
