//
//  OnboardWireframe.swift
//  webcam
//
//  Created by Andre Martingo on 10.12.21.
//

import Foundation
import UIKit
import SwiftUI

class OnboardWireframe {
    let navigationController: UINavigationController

    internal init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    static func present(rootViewController: UIViewController) {
        let navigation = UINavigationController()
        let wireframe = OnboardWireframe(navigationController: navigation)
        let viewModel = OnboardViewModel(wireframe: wireframe)
        let hosting = UIHostingController(rootView: OnboardView(viewModel: viewModel))
        navigation.viewControllers = [hosting]
        navigation.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        rootViewController.present(navigation, animated: true, completion: nil)
    }
    
    func share() {
        guard let path = Bundle(for: CameraWireframe.self).path(forResource: "virtualcamera", ofType: "pkg") else { return }
        let url = URL(fileURLWithPath: path)
        let activityViewController = UIActivityViewController(activityItems: [url] , applicationActivities: nil)
        navigationController.present(activityViewController,
                                     animated: true,
                                     completion: nil)
    }
    
    @objc
    func addTapped() {}
    
    func dismiss() {
        self.navigationController.dismiss(animated: true, completion: nil)
    }
}

