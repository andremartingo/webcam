//
//  BonjourClient.swift
//  webcam
//
//  Created by Andre Martingo on 26.03.21.
//

import UIKit
import CocoaAsyncSocket

enum PacketTag: Int {
    case header = 1
    case body = 2
}

protocol BonjourClientDelegate {
    func connectedTo(_ socket: GCDAsyncSocket!)
    func disconnected()
    func handleBody(_ body: NSString?)
}

class BonjourHost: NSObject {
   
    var delegate: BonjourClientDelegate!

    private var service: NetService!
    private var socket: GCDAsyncSocket!
    
    override init() {
        super.init()
        startBroadCasting()
    }
    
    func send(_ data: Data) {
        var header = data.count
        let headerData = Data(bytes: &header, count: MemoryLayout<UInt>.size)
        socket.write(headerData, withTimeout: -1.0, tag: PacketTag.header.rawValue)
        socket.write(data, withTimeout: -1.0, tag: PacketTag.body.rawValue)
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

    func netServiceDidPublish(_ sender: NetService) {
        print("Bonjour service published. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port)")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Unable to create socket. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port), Error \(errorDict)")
    }
}

extension BonjourHost: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("Did accept new socket")
        socket = newSocket
        socket.readData(toLength: UInt(MemoryLayout<UInt64>.size), withTimeout: -1.0, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket did disconnect: error \(String(describing: err))")
        if socket == socket {
            delegate.disconnected()
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("did read data")
        
        if data.count == MemoryLayout<UInt>.size {
            let bodyLength: UInt = parseHeader(data)
            sock.readData(toLength: bodyLength, withTimeout: -1, tag: PacketTag.body.rawValue)
        } else {
            let body = handleResponseBody(data)
            delegate.handleBody(body)
            sock.readData(toLength: UInt(MemoryLayout<UInt>.size), withTimeout: -1, tag: PacketTag.header.rawValue)
        }
    }
    
    private func parseHeader(_ data: Data) -> UInt {
        var out: UInt = 0
        (data as NSData).getBytes(&out, length: MemoryLayout<UInt>.size)
        return out
    }
    
    private func handleResponseBody(_ data: Data) -> NSString? {
        return NSString(data: data, encoding: String.Encoding.utf8.rawValue)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("did write data with tag: \(tag)")
    }
}

