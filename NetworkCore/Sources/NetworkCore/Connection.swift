//
//  File.swift
//  
//
//  Created by Andre Martingo on 04.04.21.
//

import Foundation
import Network

public class Connection {

    let connection: NWConnection
    public var didReceive: ((Data) -> Void)?

    // outgoing connection
    public init(endpoint: NWEndpoint) {
        log("PeerConnection outgoing endpoint: \(endpoint)")
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.includePeerToPeer = true
        connection = NWConnection(to: endpoint, using: parameters)
        start()
    }

    // incoming connection
    public init(connection: NWConnection) {
        log("PeerConnection incoming connection: \(connection)")
        self.connection = connection
        start()
    }

    func start() {
        connection.stateUpdateHandler = { newState in
            log("connection.stateUpdateHandler \(newState)")
            if case .ready = newState {
                self.receiveMessage()
            }
        }
        connection.start(queue: .main)
    }

    func send(_ message: Data) {
        connection.send(content: message, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed({ error in
            log("Connection send error: \(String(describing: error))")
        }))
    }

    func receiveMessage() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 900000) { data, _, _, error in
            if let error = error {
                log("Error \(error.debugDescription)")
            }
            if let data = data {
                log("Connection receiveMessage message")
                self.didReceive?(data)
            }
            self.receiveMessage()
        }
    }
}

