//
//  CameraViewModel.swift
//  webcam
//
//  Created by Andre Martingo on 28.02.21.
//

import Foundation
import Combine
import Core

protocol CameraViewModelProtocol {
    var didChangeCamera: AnyPublisher<Void, Never> { get }
}

class CameraViewModel: CameraViewModelProtocol {
    
    private var disposables = Set<AnyCancellable>()

    @Published
    private(set) var didReceivedImage = PassthroughSubject<Data, Never>()
    
    let didChangeCamera: AnyPublisher<Void, Never>
    private let _changeCamera = PassthroughSubject<Void, Never>()
    
    public var output: Bool = false
    private let client: Client
    
    init() {
        self.didChangeCamera = _changeCamera.eraseToAnyPublisher()
        self.client = .init()
        setupBindings()
    }
    
    private func setupBindings() {
        didReceivedImage.sink { [weak self] in
            print("Sending Frame")
            self?.client.send(frames: [$0])
        }
        .store(in: &disposables)
    }
    
    func changeCamera() {
        _changeCamera.send(())
    }
}
