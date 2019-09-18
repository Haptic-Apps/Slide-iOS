//
//  VideoView.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/11/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import AVFoundation

final class VideoView: UIView {

    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
            playerLayer.videoGravity = .resizeAspectFill
        }
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        guard layer == self.layer else {
            return
        }
        layer.frame = self.frame
    }
}
