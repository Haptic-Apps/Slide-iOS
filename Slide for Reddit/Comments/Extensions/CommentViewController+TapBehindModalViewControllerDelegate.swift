//
//  CommentViewController+TapBehindModalViewControllerDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation

extension CommentViewController: TapBehindModalViewControllerDelegate {
    // MARK: - Methods
    func shouldDismiss() -> Bool {
        return false
    }
}
