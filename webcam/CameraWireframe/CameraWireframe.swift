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
    static func view() -> UIViewController {
        return UIHostingController(rootView: ContentView(viewModel: .init()))
    }
}
