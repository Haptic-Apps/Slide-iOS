//
// Created by Carlos Crane on 2/15/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import Foundation
import SafariServices

class SFHideSafariViewController: SFSafariViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        UIApplication.shared.statusBarStyle = ColorUtil.theme.isLight ? .default : .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        UIApplication.shared.statusBarStyle = .lightContent
    }
}
