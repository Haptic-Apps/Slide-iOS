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
    static let slp = SwiftLinkPreview(session: URLSession.shared,
                               workQueue: SwiftLinkPreview.defaultWorkQueue,
                               responseQueue: DispatchQueue.main,
                               cache: DisabledCache.instance)

}
