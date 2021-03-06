//
//  SceneDelegate.swift
//  server
//
//  Created by Andre Martingo on 05.03.21.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 400, height: 700)
//            windowScene.sizeRestrictions?.maximumSize = CGSize(width: 400, height: 500)
        }
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: ServerView())
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}

