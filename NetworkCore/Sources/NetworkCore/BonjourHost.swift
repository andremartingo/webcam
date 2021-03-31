//
//  BonjourClient.swift
//  webcam
//
//  Created by Andre Martingo on 26.03.21.
//

import UIKit
import CocoaAsyncSocket

public protocol BonjourHostDelegate {
    func connectedTo(_ socket: GCDAsyncSocket!)
    func disconnected()
    func handleBody(_ body: NSString?)
}

public class BonjourHost: NSObject {
    
    public var delegate: BonjourHostDelegate!
    
    private var service: NetService!
    private var socket: GCDAsyncSocket!
    var cannonicalThread: [Message] = []
    let socketQueue = DispatchQueue(label: "SocketQueue")
    let clientArrayQueue = DispatchQueue(label: "ConnectedSocketsQueue", attributes: .concurrent)
    let messagesArrayQueue = DispatchQueue(label: "CannonicalThreadQueue", attributes: .concurrent)
    var connectedSockets: [GCDAsyncSocket] = []
    let namesQueue = DispatchQueue(label: "SocketNamesQueue", attributes: .concurrent)
    var socketNames: [GCDAsyncSocket: String] = [:]
    
    public var didReceive: ((UIImage) -> Void)?
    
    @Published
    public var connected: Bool = false
    
    override public init() {
        super.init()
        startBroadCasting()
    }
    
    private func startBroadCasting() {
        socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        var error: NSError?
        do {
            try socket.accept(onPort: 0)
            service = NetService(domain: "local.", type: "_webcam._tcp.", name: UIDevice.current.name, port: Int32(socket.localPort))
            service.delegate = self
            service.publish()
        } catch let error1 as NSError {
            error = error1
            print("Unable to create socket. Error \(String(describing: error))")
        }
    }
}

extension BonjourHost: NetServiceDelegate {
    
    public func netServiceDidPublish(_ sender: NetService) {
        print("Bonjour service published. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port)")
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Unable to create socket. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port), Error \(errorDict)")
    }
}

extension BonjourHost: GCDAsyncSocketDelegate {
    
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("Socket didAcceptNewSocket")
        clientArrayQueue.async(flags: .barrier) {
            self.connectedSockets.append(newSocket)
        }
        self.connected = true
        
        // Wait for a message
        newSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket did disconnect: error \(String(describing: err))")
        connected = false
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("did read data")
        
        // Incoming message
//        let messageData = data.dropLast(2)
        guard let image = UIImage(data: data) else {
            return print("ERROR: Couldnt create image from data")
        }
        self.didReceive?(image)
        
//        DispatchQueue.main.async {
//            self.addMessage(message, toTextView: self.textView)
//        }
        
        // Update the cannonical thread
//        messagesArrayQueue.async {
//            self.cannonicalThread.append(message)
//        }
        
        // Forward the message to clients
        clientArrayQueue.async {
            for client in self.connectedSockets {
                if client == sock {
                    // Don't send the message back to the client who sent it
                    continue
                }
                client.write(data, withTimeout: -1, tag: 0)
            }
        }
        
        
        // Read the next message
        sock.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    private func parseHeader(_ data: Data) -> UInt {
        var out: UInt = 0
        (data as NSData).getBytes(&out, length: MemoryLayout<UInt>.size)
        return out
    }
    
    private func handleResponseBody(_ data: Data) -> NSString? {
        return NSString(data: data, encoding: String.Encoding.utf8.rawValue)
    }
}

