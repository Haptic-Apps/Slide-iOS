//
//  SettingsWidget.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 10/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
import Anchorage
import MKColorPicker
import RLBAlertsPickers
import SDCAlertView
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

class SettingsWidget: BubbleSettingTableViewController {
    
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }
    
    var suite: UserDefaults?
    var widgets: [String] = []

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? InsetCell {
            if indexPath.row == 0 {
                cell.top = true
            } else {
                cell.top = false
            }
            if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 || indexPath.section == 1 || indexPath.section == 2 {
                cell.bottom = true
            } else {
                cell.bottom = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.suite = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        self.widgets = suite?.stringArray(forKey: "widgets") ?? []
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func loadView() {
        super.loadView()
        setupViews()
    }
    
    func setupViews() {
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "Widget Configurations"
        self.headers = ["Subreddit Shortcut Widget"]
        self.tableView.separatorStyle = .none
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
        
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.row == widgets.count {
                let cell = InsetCell()
                cell.textLabel?.text = "Create a new shortcut widget"
                cell.textLabel?.textColor = ColorUtil.theme.fontColor
                cell.backgroundColor = ColorUtil.theme.foregroundColor
                cell.accessoryType = .disclosureIndicator
                return cell
            } else {
                let cell = InsetCell()
                cell.textLabel?.text = widgets[indexPath.row]
                cell.textLabel?.textColor = ColorUtil.theme.fontColor
                cell.backgroundColor = ColorUtil.theme.foregroundColor
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        default: fatalError("Unknown section")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == widgets.count {
            createWidget()
        } else {
            let widgetName = widgets[indexPath.row]
            var currentSubs = [String]()
            let suite = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
            currentSubs.append(contentsOf: suite?.stringArray(forKey: "widget+\(widgetName.addPercentEncoding)") ?? [])
            VCPresenter.showVC(viewController: SettingsEditWidget(title: widgetName, currentSubs: currentSubs), popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
        }
    }

    func createWidget() {
        let alert = DragDownAlertMenu(title: "Create a Subreddit Set", subtitle: "Create a name for this widget", icon: nil)
        
        alert.addTextInput(title: "Create", icon: UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "add")?.menuIcon(), enabled: true, action: {
            alert.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                let text = alert.getText() ?? ""
                if text.isEmpty {
                    self.createWidget()
                    return
                }
                self.widgets.append(text)
                self.suite?.setValue(self.widgets, forKey: "widgets")
                self.suite?.synchronize()
                VCPresenter.showVC(viewController: SettingsEditWidget(title: text, currentSubs: []), popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)

            }
        }, inputPlaceholder: "Name...", inputValue: nil, inputIcon: UIImage(named: "wiki")!.menuIcon(), textRequired: true, exitOnAction: false)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return widgets.count + 1
        default: fatalError("Unknown number of sections")
        }
    }
}

class SettingsEditWidget: UITableViewController {
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }

    var widgetName: String

    init(title: String, currentSubs: [String]) {
        self.widgetName = title
        super.init(nibName: nil, bundle: nil)
        self.subs = self.subs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
        subs.append(contentsOf: currentSubs)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var subs: [String] = []
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.isEditing = true
        self.tableView.backgroundColor = ColorUtil.theme.backgroundColor
        
        tableView.reloadData()
        
        let add = UIButton.init(type: .custom)
        add.setImage(UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "add")!.navIcon(), for: UIControl.State.normal)
        add.addTarget(self, action: #selector(self.add(_:)), for: UIControl.Event.touchUpInside)
        add.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let addB = UIBarButtonItem.init(customView: add)
        self.navigationItem.rightBarButtonItem = addB
        
        self.tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let suite = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        suite?.setValue(subs, forKey: "widget+\(widgetName.addPercentEncoding)")
        suite?.synchronize()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    @objc func add(_ selector: AnyObject) {
        let searchVC = SubredditFindReturnViewController(includeSubscriptions: true, includeCollections: true, includeTrending: false, subscribe: false, callback: { (sub) in
            if !self.subs.contains(sub) {
                self.subs.append(sub)
                self.subs = self.subs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
                self.tableView.reloadData()
            }
        })
        VCPresenter.showVC(viewController: searchVC, popupIfPossible: false, parentNavigationController: navigationController, parentViewController: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thing = subs[indexPath.row]
        var cell: SubredditCellView?
        let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
        c.setSubreddit(subreddit: thing, nav: nil)
        cell = c
        cell?.backgroundColor = ColorUtil.theme.foregroundColor
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.separatorStyle = .none
        setupBaseBarColors()
        self.title = "Add shortcuts for " + widgetName
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let sub = subs[indexPath.row]
            subs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
