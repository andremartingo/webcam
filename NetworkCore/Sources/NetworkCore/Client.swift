//
//  File.swift
//  
//
//  Created by Andre Martingo on 03.03.21.
//

import Foundation
import Network

public class Client {
    private var connection: NWConnection
    private var queue: DispatchQueue

    public init() {
        queue = DispatchQueue(label: "Client Queue")
        // Create connection
        connection = NWConnection(to: .service(name: Constants.serverName,
                                               type: Constants.serviceType,
                                               domain: Constants.domain,
                                               interface: nil),
                                  using: .udp)
        // To increase the size of a UDP packet ?
        if let ipOptions = connection.parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            ipOptions.version = .v6
            ipOptions.useMinimumMTU = false
        }
        // Set the state update handler
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                print("Client ready")
                // Send the initial frame
                self?.sendInitialFrame()
            case .setup:
                print("Client setup")
            case .preparing:
                print("Client preparing")
            case .waiting(let error):
                print("Client waiting error ", error)
            case .cancelled:
                print("Client cancelled")
            case .failed(let error):
                print("Client failed error ", error)
            @unknown default:
                break
            }
        }
        // Start the connection
        connection.start(queue: queue)
    }

    private func sendInitialFrame() {
        let helloMessage = "hello".data(using: .utf8)

        connection.send(content: helloMessage, completion: .contentProcessed({ error in
            if let error = error {
                print("Client send initial frame error ", error)
            }
        }))

        connection.receiveMessage { (content, context, isComplete, error) in
            if let _ = content {
                print("Got connected!")
            }
        }
    }

    // Send frames from the camera to the other device
    public func send(frames: [Data]) {
        // Better to have such context ?
        let ipMetadata = NWProtocolIP.Metadata()
        ipMetadata.serviceClass = .interactiveVideo
        let context = NWConnection.ContentContext(identifier: "InteractiveVideo", metadata: [ ipMetadata ])

        connection.batch {
            for frame in frames {
                connection.send(content: frame, contentContext: context, completion: .contentProcessed({ (error) in
                    if let error = error {
                        print("Client send frames error ", error)
                    }
                }))
            }
        }
    }

}

