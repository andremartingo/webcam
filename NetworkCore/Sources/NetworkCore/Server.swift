//
//  Server.swift
//  
//
//  Created by Andre Martingo on 05.03.21.
//

import Foundation
import Network

public class Server {

    var listener: NWListener
    var queue: DispatchQueue

    var connected = false

    public var didReceive: ((Data) -> Void)?
    
    public init?() {
        queue = DispatchQueue(label: "Server Queue")
        // Create listener
        listener = try! NWListener(using: .udp)
        // To increase the size of a UDP packet ?
        if let ipOptions = listener.parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            ipOptions.version = .v6
            ipOptions.useMinimumMTU = false
        }
        // Set up the listener with the _camera._udp service
        listener.service = NWListener.Service(name: Constants.serverName, type: Constants.serviceType)
        listener.serviceRegistrationUpdateHandler = { serviceChange in
            switch serviceChange {
            case .add(let endpoint):
                print("Server adding listener endpoint ", endpoint)
                switch endpoint {
                case .service(let name, _, _, _):
                    print("Server listening as ", name)
                default:
                    break
                }
            case .remove(let endpoint):
                print("Server removing listener enpoint ", endpoint)
            }
        }
        // Handle incoming connections
        listener.newConnectionHandler = { [weak self] newConnection in
            if let self = self {
                newConnection.start(queue: self.queue)

//                self.controller?.serverDidConnect()
                self.receive(on: newConnection)
            }
        }
        // handle listener state changes
        listener.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                print("Server ready on random port \(String(describing: self?.listener.port))")
            case .setup:
                print("Server listener setup")
            case .waiting(let error):
                print("Server listener waiting error ", error)
            case .cancelled:
                print("Server listener cancelled")
            case .failed(let error):
                print("Server listener failed error ", error)
            }
        }

        // Start the listener
        listener.start(queue: queue)
    }

    // Receive packets from the other side and push to screen as video frames
    private func receive(on connection: NWConnection) {
        connection.receiveMessage { (content, context, isComplete, error) in
            if let frame = content {
                if !self.connected {
                    connection.send(content: frame, completion: .idempotent)
                    print("Echoed the initial content ", frame)
                    self.connected = true
                } else {
                    print("Server Received image")
                    self.didReceive?(frame)
                }

                if error == nil {
                    self.receive(on: connection)
                }
            }
        }
    }

}

