//
//  BonjourServer.swift
//  server
//
//  Created by Andre Martingo on 26.03.21.
//

import CocoaAsyncSocket

public enum PacketTag: Int {
    case header = 1
    case body = 2
}

public protocol BonjourClientDelegate {
    func connected()
    func disconnected()
    func handleBody(_ body: NSString?)
    func didChangeServices()
}

public class BonjourClient: NSObject {
    
    var delegate: BonjourClientDelegate!
    
    var coServiceBrowser: NetServiceBrowser!
    
    var netService: NetService?
    
    var connectedService: NetService!
    
    var socket: GCDAsyncSocket?
    var serverAddresses: [Data]?
    
    @Published
    public var connected = false
    
    override public init() {
        super.init()
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
    
    public func send(_ data: Data) {
        var newData = data
        newData.append(GCDAsyncSocket.crlfData())
        socket?.write(newData, withTimeout: -1, tag: 0)
    }
}

extension BonjourClient: NetServiceBrowserDelegate {
    
    public func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didFind aNetService: NetService, moreComing: Bool) {
        print("NetServiceBrowser Found device \(aNetService.name)")
        netService = aNetService
        netService?.delegate = self
        netService?.resolve(withTimeout: 5)
    }
    
    public func netServiceBrowserDidStopSearch(_ aNetServiceBrowser: NetServiceBrowser) {
        print("NetServiceBrowser did stop search")
        self.stopBrowsing()
    }
    
    public func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
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
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        print("did resolve address \(sender.name)")
        if serverAddresses == nil {
            serverAddresses = sender.addresses
        }
        if socket == nil {
            socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            connectToNextAddress()
        }
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("net service did no resolve. errorDict: \(errorDict)")
    }
    
    func connectToNextAddress() {
        var done = false
        while (!done && serverAddresses?.count ?? 0 > 0) {
            if let addr = serverAddresses?.remove(at: 0) {
                do {
                    try socket?.connect(toAddress: addr)
                    done = true
                } catch let error {
                    print("ERROR: \(error)")
                }
            }
        }
        
        if !done {
            print("Unable to connect to any resolved address")
        }
    }
}

extension BonjourClient: GCDAsyncSocketDelegate {
    
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("connected to host \(String(describing: host)), on port \(port)")
        connected = true
        socket?.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket did disconnect \(String(describing: sock)), error: \(String(describing: err?._userInfo))")
        connected = false
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
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
    
    public func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        print("socket did close read stream")
    }
    
    // MARK: helpers
    
    func getSelectedSocket() -> GCDAsyncSocket? {
        var sock: GCDAsyncSocket?
        if self.connectedService != nil {
            sock = self.socket
        }
        return sock
    }
}
 
