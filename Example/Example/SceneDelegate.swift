//
//  SceneDelegate.swift
//  Example
//
//  Created by wuyong on 2025/8/7.
//  Copyright © 2025 wuyong.site. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
            window?.backgroundColor = .white
            window?.rootViewController = UINavigationController(rootViewController: ViewController())
            window?.makeKeyAndVisible()
        }
    }
}
