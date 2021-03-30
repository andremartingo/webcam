//
//  BonjourServer.swift
//  server
//
//  Created by Andre Martingo on 26.03.21.
//

import Cocoa
import CocoaAsyncSocket

enum PacketTag: Int {
    case header = 1
    case body = 2
}

protocol BonjourServerDelegate {
    func connected()
    func disconnected()
    func handleBody(_ body: NSString?)
    func didChangeServices()
}

class BonjourClient: NSObject {
    
    var delegate: BonjourServerDelegate!
    
    var coServiceBrowser: NetServiceBrowser!
    
    var netService: NetService?
    
    var connectedService: NetService!
    
    var sockets: [String : GCDAsyncSocket]!
    
    @Published
    var connected = false
    
    override init() {
        super.init()
        self.sockets = [:]
        self.startService()
    }
    
    func parseHeader(_ data: Data) -> UInt {
        var out: UInt = 0
        (data as NSData).getBytes(&out, length: MemoryLayout<UInt>.size)
        return out
    }
    
    func handleResponseBody(_ data: Data) {
        if let message = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            self.delegate.handleBody(message)
        }
    }
    
    func connectTo(_ service: NetService) {
        service.delegate = self
        service.resolve(withTimeout: 15)
    }
    
    func startService() {
        self.coServiceBrowser = NetServiceBrowser()
        self.coServiceBrowser.delegate = self
        self.coServiceBrowser.searchForServices(ofType: "_webcam._tcp.", inDomain: "local.")
    }
    
    func send(_ data: Data) {
        print("send data")
        
        if let socket = self.getSelectedSocket() {
            var header = data.count
            let headerData = Data(bytes: &header, count: MemoryLayout<UInt>.size)
            socket.write(headerData, withTimeout: -1.0, tag: PacketTag.header.rawValue)
            socket.write(data, withTimeout: -1.0, tag: PacketTag.body.rawValue)
        }
    }
}

extension BonjourClient: NetServiceBrowserDelegate {
    
    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didFind aNetService: NetService, moreComing: Bool) {
        print("NetServiceBrowser Found device \(aNetService.name)")
        netService = aNetService
        netService?.delegate = self
        netService?.resolve(withTimeout: 5)
    }
    
    func netServiceBrowserDidStopSearch(_ aNetServiceBrowser: NetServiceBrowser) {
        print("NetServiceBrowser did stop search")
        self.stopBrowsing()
    }
    
    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("NetServiceBrowser did not search")
        self.stopBrowsing()
    }
    
    private func stopBrowsing() {
        if self.coServiceBrowser != nil {
            self.coServiceBrowser.stop()
            self.coServiceBrowser.delegate = nil
            self.coServiceBrowser = nil
        }
    }
}

extension BonjourClient: NetServiceDelegate {
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("did resolve address \(sender.name)")
        if self.connectToServer(sender) {
            print("connected to \(sender.name)")
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("net service did no resolve. errorDict: \(errorDict)")
    }
    
    func connectToServer(_ service: NetService) -> Bool {
        var connected = false
        
        let addresses: Array = service.addresses!
        var socket = self.sockets[service.name]
        
        if !(socket?.isConnected != nil) {
            socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            
            while !connected && !addresses.isEmpty {
                let address: Data = addresses[0]
                do {
                    if (try socket?.connect(toAddress: address) != nil) {
                        self.sockets.updateValue(socket!, forKey: service.name)
                        self.connectedService = service
                        connected = true
                    }
                } catch {
                    print(error);
                }
            }
        }
        
        return true
    }
}

extension BonjourClient: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("connected to host \(String(describing: host)), on port \(port)")
        connected = true
        sock.readData(toLength: UInt(MemoryLayout<UInt64>.size), withTimeout: -1.0, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket did disconnect \(String(describing: sock)), error: \(String(describing: err?._userInfo))")
        connected = false
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("socket did read data. tag: \(tag)")
        
        if self.getSelectedSocket() == sock {
            
            if data.count == MemoryLayout<UInt>.size {
                let bodyLength: UInt = self.parseHeader(data)
                sock.readData(toLength: bodyLength, withTimeout: -1, tag: PacketTag.body.rawValue)
            } else {
                self.handleResponseBody(data)
                sock.readData(toLength: UInt(MemoryLayout<UInt>.size), withTimeout: -1, tag: PacketTag.header.rawValue)
            }
        }
    }
    
    func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        print("socket did close read stream")
    }
    
    // MARK: helpers
    
    func getSelectedSocket() -> GCDAsyncSocket? {
        var sock: GCDAsyncSocket?
        if self.connectedService != nil {
            sock = self.sockets[self.connectedService.name]!
        }
        return sock
    }
}
 
