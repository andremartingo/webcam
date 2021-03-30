//
//  CameraViewModel.swift
//  webcam
//
//  Created by Andre Martingo on 28.02.21.
//

import Foundation
import Combine
import NetworkCore

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
    private(set) var didReceivedImage = PassthroughSubject<Data, Never>()
    
    @Published
    var quality: Int = 0
    
    @Published
    var compression: Float = 0
    
    let didChangeCamera: AnyPublisher<Void, Never>
    private let _changeCamera = PassthroughSubject<Void, Never>()

    let didChangeQuality: AnyPublisher<Quality, Never>
    private let _changeQuality = PassthroughSubject<Quality, Never>()
    
    public var output: Bool = false
    private let host = BonjourHost()
    
    init() {
        self.didChangeCamera = _changeCamera.eraseToAnyPublisher()
        self.didChangeQuality = _changeQuality.eraseToAnyPublisher()
        setupBindings()
    }
    
    private func setupBindings() {
        didReceivedImage.sink { [weak self] _ in
//            self?.client.send(frames: [$0])
        }
        .store(in: &disposables)
        
        $quality
            .sink { [weak self] in
                guard let value = Quality(rawValue: $0) else { return }
                self?.changeQuality(quality: value)
            }
            .store(in: &disposables)
    }
    
    func changeCamera() {
        _changeCamera.send(())
    }
    
    func changeQuality(quality: Quality) {
        _changeQuality.send(quality)
    }
}
