//
//  CameraViewModel.swift
//  webcam
//
//  Created by Andre Martingo on 28.02.21.
//

import Foundation
import Combine
import UIKit
import NetworkCore
import StoreKit

enum State {
    case connected
    case notConnected
}

protocol CameraViewModelProtocol {
    var didChangeCamera: AnyPublisher<Void, Never> { get }
}

enum Quality: Int {
    case sd = 0
    case hd = 1
}

class CameraViewModel: ObservableObject, CameraViewModelProtocol {
    
    private var disposables = Set<AnyCancellable>()
    
    @Published
    private(set) var didReceivedImage = PassthroughSubject<Frame, Never>()
    
    @Published
    var quality: Int = 0
    
    @Published
    var compression: Float = 0.1
    
    @Published
    var description: String = ""
    
    @Published
    var connectionState: State = .notConnected
    
    let didChangeCamera: AnyPublisher<Void, Never>
    private let _changeCamera = PassthroughSubject<Void, Never>()
    
    let didChangeQuality: AnyPublisher<Quality, Never>
    private let _changeQuality = PassthroughSubject<Quality, Never>()
    
    public var output: Bool = false
    private let server: Server?
    private var timer: Timer?
    private let images = [UIImage(named: "balance-light")!, UIImage(named: "cardColor-light")!]
    private let wireframe: CameraWireframe
    
    init(wireframe: CameraWireframe) {
        self.wireframe = wireframe
        self.didChangeCamera = _changeCamera.eraseToAnyPublisher()
        self.didChangeQuality = _changeQuality.eraseToAnyPublisher()
        self.server = try? Server()
        server?.start()
        setupBindings()
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
//            self.server?.send(self.images.randomElement()!.jpegData(compressionQuality: 0.3)!)
//        }
    }
    
    private func setupBindings() {
        didReceivedImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.description = $0.topHalf.description
                self?.server?.send([$0.topHalf, $0.bottomHalf])
            }
            .store(in: &disposables)
        
        $quality
            .sink { [weak self] in
                guard let value = Quality(rawValue: $0) else { return }
                self?.changeQuality(quality: value)
            }
            .store(in: &disposables)
        
        server?.$connections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if $0.isEmpty {
                    self?.connectionState = .notConnected
                } else {
                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                    self?.connectionState = .connected
                }
            }
            .store(in: &disposables)
    }
    
    func showOnbard() {
        wireframe.showOnbarding()
    }
    
    func share() {
        wireframe.share()
    }
    
    func changeCamera() {
        _changeCamera.send(())
    }
    
    func changeQuality(quality: Quality) {
        _changeQuality.send(quality)
    }
}

extension UIImage {
    func rotate(deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

}
