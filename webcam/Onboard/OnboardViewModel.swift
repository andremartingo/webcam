//
//  OnboardViewModel.swift
//  webcam
//
//  Created by Andre Martingo on 10.12.21.
//

import Foundation

class OnboardViewModel {
    
    let wireframe: OnboardWireframe
    
    init(wireframe: OnboardWireframe) {
        self.wireframe = wireframe
    }
    
    func showShare() {
        self.wireframe.share()
    }
    
    func close() {
        self.wireframe.dismiss()
    }
}
