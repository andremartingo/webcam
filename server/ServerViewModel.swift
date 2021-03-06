//
//  ServerViewModel.swift
//  server
//
//  Created by Andre Martingo on 05.03.21.
//

import Combine
import UIKit
import Core

enum State {
    case connected
    case notConnected
}

class ServerViewModel: ObservableObject {
    @Published
    private (set) var image: UIImage
    
    @Published
    var connectionState: State

    let server: Server?
    
    init() {
        self.image = .init()
        self.connectionState = .notConnected
        self.server = Server()
        server?.didReceive = {
            guard let image = UIImage(data: $0) else { return }
            DispatchQueue.main.async {
                self.connectionState = .connected
                self.image = image
            }
        }
    }
}
