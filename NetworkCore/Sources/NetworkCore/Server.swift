//
//  Server.swift
//  
//
//  Created by Andre Martingo on 05.03.21.
//

import Foundation
import Network

public class Server {
    let listener: NWListener

    @Published
    public var connections: [Connection] = []
    
    @Published
    public var connected: Bool = false
    
    public var didReceive: ((Data) -> Void)?

    public init() throws {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.includePeerToPeer = true
        listener = try NWListener(using: parameters)
        
        listener.service = NWListener.Service(name: Constants.serverName, type: Constants.serviceType)
    }

    public func start() {
        listener.stateUpdateHandler = { newState in
            log("listener.stateUpdateHandler \(newState)")
        }
        listener.newConnectionHandler = { [weak self] newConnection in
            log("listener.newConnectionHandler \(newConnection)")
            let connection = Connection(connection: newConnection)
            self?.connected = true
            self?.connections += [connection]
        }
        listener.start(queue: .main)
    }

    public func send(_ data: [Data]) {
        connections.forEach { connection in
            connection.send(data.first!)
        }
    }
}
