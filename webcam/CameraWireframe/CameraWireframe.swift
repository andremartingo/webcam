//
//  CameraWireframe.swift
//  webcam
//
//  Created by Andre Martingo on 03.03.21.
//

import Foundation
import UIKit
import SwiftUI

class CameraWireframe {
    let navigationController: UINavigationController

    private init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    static func build(navigationController: UINavigationController) -> UINavigationController {
        let wireframe = CameraWireframe(navigationController: navigationController)
        let viewModel = CameraViewModel(wireframe: wireframe)
        let hosting = UIHostingController(rootView: ContentView(viewModel: viewModel))
        navigationController.viewControllers = [hosting]
        return navigationController
    }
    
    func showOnbarding() {
        OnboardWireframe.present(rootViewController: navigationController)
    }
    
    func share() {
        guard let path = Bundle(for: CameraWireframe.self).path(forResource: "virtualcamera", ofType: "pkg") else { return }
        let url = URL(fileURLWithPath: path)
        let activityViewController = UIActivityViewController(activityItems: [url] , applicationActivities: nil)
        navigationController.present(activityViewController,
                                     animated: true,
                                     completion: nil)
    }
}
