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
                if $0.isEmpty == false {
                    self?.connectionState = .notConnected
                } else {
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
