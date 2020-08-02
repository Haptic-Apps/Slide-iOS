//
//  CommentTapBehindModalDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/2/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation

extension CommentViewController: TapBehindModalViewControllerDelegate {
    func shouldDismiss() -> Bool {
        return false
    }
}
