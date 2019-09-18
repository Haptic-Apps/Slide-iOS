//
//  SceneDelegate.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/17/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import UIKit
@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard (scene as? UIWindowScene) != nil else { return }
    window = (UIApplication.shared.delegate as? AppDelegate)?.doFirstLaunchActions(nil)
  }
}
