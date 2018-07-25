//
//  AVControlsPlayer.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/4/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import AVKit
import Foundation

class AVControlsPlayer: AVPlayerViewController {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO:
        if parent is MediaDisplayViewController {
            (parent as! MediaDisplayViewController).handleTap(recognizer: nil)
        }
        super.touchesBegan(touches, with: event)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
}
