//
// Created by Carlos Crane on 2/15/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import Foundation
import SafariServices

class SFHideSafariViewController: SFSafariViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.isLightTheme && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }
}
