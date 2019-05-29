//
//  LinkBubble.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 5/29/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import UIKit
import SwiftLinkPreview

public class LinkBubble: UIView {
    static let slp = SwiftLinkPreview(session: URLSession = URLSession.shared,
                               workQueue: DispatchQueue = SwiftLinkPreview.defaultWorkQueue,
                               responseQueue: DispatchQueue = DispatchQueue.main,
                               cache: Cache = DisabledCache.instance)

}
