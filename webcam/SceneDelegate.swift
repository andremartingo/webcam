//
//  SceneDelegate.swift
//  webcam
//
//  Created by Andre Martingo on 28.02.21.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene  else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = CameraWireframe.view()
        self.window = window
        window.makeKeyAndVisible()
    }
}

