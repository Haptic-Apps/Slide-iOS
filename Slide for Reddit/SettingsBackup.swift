//
//  SettingsBackup
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/11/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import BiometricAuthentication
import LicensesViewController
import RealmSwift
import RLBAlertsPickers
import SDWebImage
import UIKit

class SettingsBackup: UITableViewController {
    
    static var changed = false

    var restore: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "restore")
    var backup: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "backup")

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.setToolbarHidden(true, animated: false)
        doCells()
    }

    override func loadView() {
        super.loadView()
    }
    
    func doCells(_ reset: Bool = true) {
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Backup"
        self.tableView.separatorStyle = .none

        self.backup.textLabel?.text = "Backup"
        self.backup.detailTextLabel?.text = "Backup your Slide data to iCloud"
        self.backup.backgroundColor = ColorUtil.foregroundColor
        self.backup.detailTextLabel?.textColor = ColorUtil.fontColor
        self.backup.textLabel?.textColor = ColorUtil.fontColor
        self.backup.imageView?.image = UIImage.init(named: "download")?.toolbarIcon().getCopy(withColor: ColorUtil.fontColor)
        self.backup.imageView?.tintColor = ColorUtil.fontColor
        
        self.restore.textLabel?.text = "Restore"
        self.restore.backgroundColor = ColorUtil.foregroundColor
        self.restore.detailTextLabel?.textColor = ColorUtil.fontColor
        self.restore.textLabel?.textColor = ColorUtil.fontColor
        self.restore.detailTextLabel?.text = "Restore your backup data from iCloud"
        self.restore.imageView?.image = UIImage.init(named: "restore")?.toolbarIcon().getCopy(withColor: ColorUtil.fontColor)
        self.restore.imageView?.tintColor = ColorUtil.fontColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 70
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.backup
            case 1: return self.restore
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            doBackup()
        } else {
            doRestore()
        }
    }
    
    func doBackup() {
        let alert = UIAlertController.init(title: "Really back up your data?", message: "This will overwrite any previous backups", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .destructive, handler: { (_) in
            self.backupSync()
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (_) in
        }))
        present(alert, animated: true)
    }
    
    func doRestore() {
        let alert = UIAlertController.init(title: "Really restore your data?", message: "This will overwrite all current Slide settings and you will have to restart Slide for the changes to take place", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .destructive, handler: { (_) in
            self.restoreSync()
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (_) in
        }))
        present(alert, animated: true)
    }
    
    func backupSync() {
        let icloud = NSUbiquitousKeyValueStore.default()
        for item in UserDefaults.standard.dictionaryRepresentation() {
            icloud.set(item.value, forKey: item.key)
        }
        icloud.synchronize()
        let alert = UIAlertController.init(title: "Your data has been synced!", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true)

    }
    
    func restoreSync() {
        let icloud = NSUbiquitousKeyValueStore.default()
        for item in icloud.dictionaryRepresentation {
            UserDefaults.standard.set(item.value, forKey: item.key)
        }
        UserDefaults.standard.synchronize()
        let alert = UIAlertController.init(title: "Your data has been restored!", message: "Slide will now close to apply changes", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Close Slide", style: .cancel, handler: { (_) in
            exit(0)
        }))
        present(alert, animated: true)

    }
   
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

        switch section {
        case 0: label.text = "General"
        case 1: label.text = "Already a Slide supporter?"
        default: label.text = ""
        }
        return toReturn
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        default: fatalError("Unknown number of sections")
        }
    }

}
