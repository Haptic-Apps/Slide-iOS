//
//  MainViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/4/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import MKColorPicker
import reddift
import RLBAlertsPickers
import SDCAlertView
import UIKit

class ProfileViewController: TabsContentPagingViewController {
    /// Vars
    var content: [UserContent] = []
    var name: String = ""
    var newColor = UIColor.white
    var friends = false
    var moreB: UIBarButtonItem?
    var sortB: UIBarButtonItem?
    var tagText: String?
    
    lazy var currentAccountTransitioningDelegate = ProfileInfoPresentationManager()

    static func doDefault() -> [UserContent] {
        return [UserContent.overview, UserContent.comments, UserContent.submitted, UserContent.gilded]
    }

    init(name: String) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.titles = []
        
        self.name = name
        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        if let n = (session?.token.flatMap { (token) -> String? in
            return token.name
            }) as String? {
            if name == n {
                friends = true
                self.content = [.overview, .submitted, .comments, .liked, .saved, .disliked, .hidden, .gilded]
            } else {
                self.content = ProfileViewController.doDefault()
            }
        } else {
            self.content = ProfileViewController.doDefault()
        }
        
        if friends {
            self.vCs.append(ContentListingViewController.init(dataSource: FriendsContributionLoader.init()))
            self.titles.append("Friends")
        }
        
        for place in content {
            self.vCs.append(ContentListingViewController.init(dataSource: ProfileContributionLoader.init(name: name, whereContent: place)))
            self.titles.append(place.title)
        }
        
        let sort = UIButton(buttonImage: UIImage(sfString: SFSymbol.arrowUpArrowDownCircle, overrideString: "ic_sort_white"))
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControl.Event.touchUpInside)
        sortB = UIBarButtonItem.init(customView: sort)
        
        let more = UIButton(buttonImage: UIImage(sfString: SFSymbol.infoCircle, overrideString: "info"))
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControl.Event.touchUpInside)
        moreB = UIBarButtonItem.init(customView: more)
    }
    
    /// Overrides
    override func appearOthers() {
        self.title = AccountController.formatUsername(input: name, small: true)
        navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        if navigationController != nil {
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "", true)
            navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white
        }
        
        if navigationController != nil {
            self.navigationController?.navigationBar.shadowImage = UIImage()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func showMenu(_ sender: AnyObject) {
        self.showMenu(sender: sender, user: self.name)
    }

    func showMenu(sender: AnyObject, user: String) {
        let vc = ProfileInfoViewController(accountNamed: user, parent: self)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = currentAccountTransitioningDelegate
        present(vc, animated: true)
    }

    @objc func showSortMenu(_ sender: UIButton?) {
        (self.vCs[currentIndex] as? ContentListingViewController)?.showSortMenu(sender)
    }

    func tagUser() {
        let alert = DragDownAlertMenu(title: AccountController.formatUsername(input: name, small: true), subtitle: "Tag profile", icon: nil, full: true)
        
        alert.addTextInput(title: "Set tag", icon: UIImage(sfString: SFSymbol.tagFill, overrideString: "save-1")?.menuIcon(), action: {
            alert.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                ColorUtil.setTagForUser(name: self.name, tag: alert.getText() ?? "")
            }
        }, inputPlaceholder: "Enter a tag...", inputValue: ColorUtil.getTagForUser(name: name), inputIcon: UIImage(sfString: SFSymbol.tagFill, overrideString: "subs")!.menuIcon(), textRequired: true, exitOnAction: true)

        if !(ColorUtil.getTagForUser(name: name) ?? "").isEmpty {
            alert.addAction(title: "Remove tag", icon: UIImage(sfString: SFSymbol.trashFill, overrideString: "delete")?.menuIcon(), enabled: true) {
                ColorUtil.removeTagForUser(name: self.name)
            }
        }
        
        alert.show(self)
    }
}

extension ProfileViewController: TabsContentPagingViewControllerDelegate {
    func shouldUpdateButtons() {
        if currentIndex >= 0 {
            let current = content[currentIndex]
            if current == .comments || current == .submitted || current == .overview {
                navigationItem.rightBarButtonItems = [ moreB!, sortB!]
            } else {
                navigationItem.rightBarButtonItems = [ moreB!]
            }
        } else {
            navigationItem.rightBarButtonItems = [ moreB!]
        }
    }
}

extension ProfileViewController: ColorPickerViewDelegate {
    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        newColor = colorPickerView.colors[indexPath.row]
        self.navigationController?.navigationBar.barTintColor = SettingValues.reduceColor ? ColorUtil.theme.backgroundColor : colorPickerView.colors[indexPath.row]
    }
    
    func pickColor(sender: AnyObject) {
        if #available(iOS 14, *) {
            let picker = UIColorPickerViewController()
            picker.title = "Profile color"
            picker.supportsAlpha = false
            picker.selectedColor = ColorUtil.getColorForUser(name: name)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
            let margin: CGFloat = 10.0
            let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0: alertController.view.bounds.size.width - margin * 4.0, height: 150)
            let MKColorPicker = ColorPickerView.init(frame: rect)
            MKColorPicker.delegate = self
            MKColorPicker.colors = GMPalette.allColor()
            MKColorPicker.selectionStyle = .check
            MKColorPicker.scrollDirection = .vertical

            MKColorPicker.style = .circle

            alertController.view.addSubview(MKColorPicker)
            
            let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(_: UIAlertAction!) in
                ColorUtil.setColorForUser(name: self.name, color: self.newColor)
            })
            
            alertController.addAction(somethingAction)
            alertController.addCancelButton()
            
            alertController.modalPresentationStyle = .popover
            if let presenter = alertController.popoverPresentationController {
                presenter.sourceView = (moreB!.value(forKey: "view") as! UIView)
                presenter.sourceRect = (moreB!.value(forKey: "view") as! UIView).bounds
            }

            alertController.modalPresentationStyle = .popover
            if let presenter = alertController.popoverPresentationController {
                presenter.sourceView = sender as! UIButton
                presenter.sourceRect = (sender as! UIButton).bounds
            }

            present(alertController, animated: true, completion: nil)
        }
    }
}

@available(iOS 14.0, *)
extension ProfileViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        newColor = viewController.selectedColor
        ColorUtil.setColorForUser(name: name, color: newColor)
    }
}
