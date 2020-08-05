//
//  CommentViewController+Thing.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import reddift

extension Thing {
    // MARK: - Methods
    func getId() -> String {
        return Self.kind + "_" + id
    }
}
