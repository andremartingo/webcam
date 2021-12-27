//
//  SceneDelegate.swift
//  webcam
//
//  Created by Andre Martingo on 28.02.21.
//

import UIKit
import SwiftUI

func isMock() -> Bool {
    return ProcessInfo.processInfo.environment["-isMock"] != nil
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene  else { return }
        let window = UIWindow(windowScene: windowScene)
        let navigation = UINavigationController()
        window.rootViewController = CameraWireframe.build(navigationController: navigation)
        self.window = window
        window.makeKeyAndVisible()
    }
}

