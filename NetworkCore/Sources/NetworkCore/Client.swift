//
//  File.swift
//  
//
//  Created by Andre Martingo on 03.03.21.
//

import Foundation
import Network
import os.log

public func log(_ message: String) {
    let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "WEBCAM")
    os_log(">>> %@", log: log, type: .debug, message)
}

public class Client {

    let browser = Browser()

    public var connection: Connection?
    
    @Published
    public var connected: Bool = false
    
    public var didReceive: ((Data) -> Void)? {
        didSet {
            connection?.didReceive = didReceive
        }
    }
    
    public init() {}

    public func send() {
        if let connection = connection {
//            connection.send("super message from the server! \(Int(Date().timeIntervalSince1970))")
        }
    }
    
    public func start() {
        browser.start { [weak self] result in
            guard let self = self,
                  self.connection == nil else { return }
            log("client.handler result: \(result)")
            self.connection = Connection(endpoint: result.endpoint)
            self.connected = true
        }
    }
}

import Foundation
import Network

class Browser {

    let browser: NWBrowser

    init() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: Constants.serviceType, domain: nil), using: parameters)
    }

    func start(handler: @escaping (NWBrowser.Result) -> Void) {
        browser.stateUpdateHandler = { newState in
            log("browser.stateUpdateHandler \(newState)")
        }
        browser.browseResultsChangedHandler = { results, changes in
            for result in results {
                if case NWEndpoint.service = result.endpoint {
                    handler(result)
                }
            }
        }
        browser.start(queue: .main)
    }
}
