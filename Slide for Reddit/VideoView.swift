//
//  VideoView.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/11/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import AVFoundation

final class VideoView: UIView {

    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

}
