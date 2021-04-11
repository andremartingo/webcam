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
    var receivedData: [Data] = []

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

    func send(_ data: Data) {
        let sizePrefix = withUnsafeBytes(of: UInt64(data.count).bigEndian) { Data($0) }
                
        log("Send \(data.count) bytes")
        
        self.connection.batch {
            self.connection.send(content: sizePrefix, completion: .contentProcessed( { error in
                if let error = error {
                    log("Error \(error.debugDescription)")
                    return
                }
            }))
            
            self.connection.send(content: data, completion: .contentProcessed( { error in
                if let error = error {
                    log("Error \(error.debugDescription)")
                    return
                }
            }))
        }
    }

    func receiveMessage() {
        connection.receive(minimumIncompleteLength: MemoryLayout<UInt64>.size,
                           maximumLength: MemoryLayout<UInt64>.size) { (sizePrefixData, _, isComplete, error) in
            var sizePrefix: UInt64 = 0
                        
                        // Decode the size prefix
                        if let data = sizePrefixData, !data.isEmpty
                        {
                            sizePrefix = data.withUnsafeBytes
                            {
                                $0.bindMemory(to: UInt64.self)[0].bigEndian
                            }
                        }
                        
                        if isComplete
                        {
//                            self.close()
                        }
                        else if let error = error
                        {
//                            self.delegate?.connectionError(connection: self, error: error)
                        }
                        else
                        {
                            // If there is nothing to read
                            if sizePrefix == 0
                            {
                                log("Received size prefix of 0")
                                self.receiveMessage()
                                return
                            }
                            
                            log("Read \(sizePrefix) bytes")
                            
                            // At this point we received a valid message and a valid size prefix
                            self.connection.receive(minimumIncompleteLength: Int(sizePrefix), maximumLength: Int(sizePrefix)) { (data, _, isComplete, error) in
                                if let data = data, !data.isEmpty
                                {
                                    self.didReceive?(data)
                                }
                                if isComplete
                                {
//                                    self.close()
                                }
                                else if let error = error
                                {
//                                    self.delegate?.connectionError(connection: self, error: error)
                                }
                                else
                                {
                                    self.receiveMessage()
                                }
                            }
                        }
        }
    }
}

