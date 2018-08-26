//
//  SettingsLinkHandling.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsLinkHandling: UITableViewController, UISearchBarDelegate {

    var domainEnter = UISearchBar()

    var internalGifCell: UITableViewCell = UITableViewCell()
    var internalGif = UISwitch()

    var internalImageCell: UITableViewCell = UITableViewCell()
    var internalImage = UISwitch()

    var internalAlbumCell: UITableViewCell = UITableViewCell()
    var internalAlbum = UISwitch()

    var internalYouTubeCell: UITableViewCell = UITableViewCell()
    var internalYouTube = UISwitch()
    
    var chromeIcon: UIImage?
    var safariIcon: UIImage?
    var safariInternalIcon: UIImage?
    var internalIcon: UIImage?
    var firefoxIcon: UIImage?
    var focusIcon: UIImage?

    //for future var dontLoadImagePreviewsCell: UITableViewCell = UITableViewCell()
    // var dontLoadImagePreviews = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()

        testBrowsers()
        doImages()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func doImages() {
        var first = GMColor.blue500Color()
        var second = first.add(overlay: UIColor.white.withAlphaComponent(0.4))
        var coloredIcon = UIImage.convertGradientToImage(colors: [first, second], frame: CGSize.square(size: 40))
        safariIcon = coloredIcon.overlayWith(image: UIImage(named: "nav")!.getCopy(withSize: CGSize.square(size: 20), withColor: .white), posX: 10, posY: 10)
        
        first = GMColor.lightBlue500Color()
        second = first.add(overlay: UIColor.white.withAlphaComponent(0.4))
        coloredIcon = UIImage.convertGradientToImage(colors: [first, second], frame: CGSize.square(size: 40))
        safariInternalIcon = coloredIcon.overlayWith(image: UIImage(named: "nav")!.getCopy(withSize: CGSize.square(size: 20), withColor: .white), posX: 10, posY: 10)

        internalIcon = UIImage(named: "roundicon")?.getCopy(withSize: CGSize.square(size: 40))
        
        first = GMColor.orange500Color()
        second = first.add(overlay: UIColor.white.withAlphaComponent(0.4))
        coloredIcon = UIImage.convertGradientToImage(colors: [first, second], frame: CGSize.square(size: 40))
        firefoxIcon = coloredIcon.overlayWith(image: UIImage(named: "nav")!.getCopy(withSize: CGSize.square(size: 20), withColor: .black), posX: 10, posY: 10)

        first = GMColor.yellow500Color()
        second = first.add(overlay: UIColor.white.withAlphaComponent(0.4))
        coloredIcon = UIImage.convertGradientToImage(colors: [first, second], frame: CGSize.square(size: 40))
        chromeIcon = coloredIcon.overlayWith(image: UIImage(named: "nav")!.getCopy(withSize: CGSize.square(size: 20), withColor: GMColor.orange700Color()), posX: 10, posY: 10)
        
        first = GMColor.purple500Color()
        second = GMColor.pink500Color()
        coloredIcon = UIImage.convertGradientToImage(colors: [first, second], frame: CGSize.square(size: 40))
        focusIcon = coloredIcon.overlayWith(image: UIImage(named: "nav")!.getCopy(withSize: CGSize.square(size: 20), withColor: .white), posX: 10, posY: 10)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    var browsers = [String]()
    
    func testBrowsers() {
        browsers.removeAll()
        let safariURL = URL(string: "http://google.com")!
        let chromeURL = URL(string: "googlechrome://google.com")!
        let operaURL = URL(string: "opera-http://google.com")!
        let firefoxURL = URL(string: "firefox://google.com")!
        let focusURL = URL(string: "firefox-focus://google.com")!

        let sharedApplication = UIApplication.shared
        
        browsers.append(SettingValues.BROWSER_INTERNAL)

        if sharedApplication.canOpenURL(safariURL) {
            browsers.append(SettingValues.BROWSER_SAFARI)
        }
        
        if #available(iOS 10, *) {
            browsers.append(SettingValues.BROWSER_SAFARI_INTERNAL)
        }
        
        if sharedApplication.canOpenURL(chromeURL) {
            browsers.append(SettingValues.BROWSER_CHROME)
        }
        
        if sharedApplication.canOpenURL(operaURL) {
            browsers.append(SettingValues.BROWSER_OPERA)
        }
        
        if sharedApplication.canOpenURL(firefoxURL) {
            browsers.append(SettingValues.BROWSER_FIREFOX)
        }
        
        if sharedApplication.canOpenURL(focusURL) {
            browsers.append(SettingValues.BROWSER_FOCUS)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 2
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch indexPath.section {
            case 2:
                PostFilter.openExternally.remove(at: indexPath.row)
            default: fatalError("Unknown section")
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
            PostFilter.saveAndUpdate()
        }
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if changed == internalImage {
            SettingValues.internalImageView = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_internalImageView)
        } else if changed == internalGif {
            SettingValues.internalGifView = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_internalGifView)
        } else if changed == internalAlbum {
            SettingValues.internalAlbumView = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_internalAlbumView)
        } else if changed == internalYouTube {
            SettingValues.internalYouTube = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_internalYouTube)
        }
        UserDefaults.standard.synchronize()
        tableView.reloadData()
    }

    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.fontColor
        cell.backgroundColor = ColorUtil.foregroundColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let s = switchV {
            s.isOn = isOn
            s.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.none
    }

    override func loadView() {
        super.loadView()

        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Link Handling"
        self.tableView.separatorStyle = .none

        createCell(internalGifCell, internalGif, isOn: !SettingValues.internalGifView, text: "Open videos (gifs, v.redd.it, streamable.com) externally")
        createCell(internalAlbumCell, internalAlbum, isOn: !SettingValues.internalAlbumView, text: "Open Imgur albums externally")
        createCell(internalImageCell, internalImage, isOn: !SettingValues.internalImageView, text: "Open images (Imgur, direct image links) externally")
        createCell(internalYouTubeCell, internalYouTube, isOn: !SettingValues.internalYouTube, text: "Open YouTube videos externally")

        self.tableView.tableFooterView = UIView()

        domainEnter.searchBarStyle = UISearchBarStyle.minimal
        domainEnter.placeholder = "Enter domain to open externally"
        domainEnter.delegate = self
        domainEnter.returnKeyType = .done
        domainEnter.textColor = ColorUtil.fontColor
        domainEnter.setImage(UIImage(), for: .search, state: .normal)
        domainEnter.autocapitalizationType = .none
        domainEnter.isTranslucent = false

    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        PostFilter.openExternally.append(domainEnter.text! as NSString)
        domainEnter.text = ""
        PostFilter.saveAndUpdate()
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = UITableViewCell()
            cell.backgroundColor = ColorUtil.foregroundColor
            cell.backgroundColor = ColorUtil.foregroundColor
            cell.textLabel?.textColor = ColorUtil.fontColor
            
            let text = browsers[indexPath.row]
            if text == SettingValues.BROWSER_SAFARI {
                cell.textLabel?.text = "External Safari"
                cell.imageView?.image = safariIcon
            } else if text == SettingValues.BROWSER_SAFARI_INTERNAL {
                cell.textLabel?.text = "Internal Safari"
                cell.imageView?.image = safariInternalIcon
            } else if text == SettingValues.BROWSER_CHROME {
                cell.textLabel?.text = "Chrome"
                cell.imageView?.image = chromeIcon
            } else if text == SettingValues.BROWSER_OPERA {
                cell.textLabel?.text = "Opera"
                cell.imageView?.image = UIImage.init(named: "world")?.toolbarIcon()
            } else if text == SettingValues.BROWSER_FIREFOX {
                cell.textLabel?.text = "FireFox"
                cell.imageView?.image = firefoxIcon
            } else if text == SettingValues.BROWSER_FOCUS {
                cell.textLabel?.text = "FireFox Focus"
                cell.imageView?.image = focusIcon
            } else if text == SettingValues.BROWSER_INTERNAL {
                cell.textLabel?.text = "Internal browser (supports ad-blocking with Pro)"
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = internalIcon
            }
            
            cell.imageView?.layer.cornerRadius = 15
            cell.imageView?.clipsToBounds = true
            
            if SettingValues.browser == browsers[indexPath.row] {
                cell.accessoryType = .checkmark
            }
            
            return cell
        case 1:
            switch indexPath.row {
            case 0: return self.internalImageCell
            case 1: return self.internalGifCell
            case 2: return self.internalAlbumCell
            case 3: return self.internalYouTubeCell
            default: fatalError("Unknown row in section 0")
            }
        case 2:
            let cell = UITableViewCell()
            cell.backgroundColor = ColorUtil.foregroundColor
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = ColorUtil.foregroundColor
            cell.textLabel?.textColor = ColorUtil.fontColor
            cell.textLabel?.text = PostFilter.openExternally[indexPath.row] as String
            return cell

        default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 2: return domainEnter
        default: return UIView()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            SettingValues.browser = browsers[indexPath.row]
            UserDefaults.standard.set(browsers[indexPath.row], forKey: SettingValues.pref_browser)
            UserDefaults.standard.synchronize()
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        label.numberOfLines = 0
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        let contentAttribute = NSMutableAttributedString(string: "Content Settings", attributes: [NSFontAttributeName: label.font, NSForegroundColorAttributeName: label.textColor])
        contentAttribute.append(NSMutableAttributedString(string: "\nAdditionally, you can set specific domains to open externally in the External Domains section below", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 16, submission: true), NSForegroundColorAttributeName: label.textColor]))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        switch section {
        case 0: label.text = "Web browser"
        case 1: label.attributedText = contentAttribute
        case 2: label.text =  "External Domains"
        default: label.text  = ""
        }
        return toReturn
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return browsers.count
        case 1: return 4   // section 0 has 2 rows
        case 2: return PostFilter.openExternally.count
        default: fatalError("Unknown number of sections")
        }
    }
}
