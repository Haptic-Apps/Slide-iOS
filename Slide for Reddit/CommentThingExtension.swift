//
//  CommentThingExtension.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/2/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import reddift

extension Thing {
    func getId() -> String {
        return Self.kind + "_" + id
    }
}
