//
//  ServerViewModel.swift
//  server
//
//  Created by Andre Martingo on 05.03.21.
//

import Combine
import UIKit
import NetworkCore

enum State {
    case connected
    case notConnected
}

class ServerViewModel: ObservableObject {
    @Published
    private (set) var image: UIImage
    
    @Published
    var connectionState: State

    let client: Client?
    
    private var disposables = Set<AnyCancellable>()
    
    init() {
        self.image = .init()
        self.connectionState = .notConnected
        self.client = try? Client()
        client?.start()
        client?.$connected
            .receive(on: DispatchQueue.main)
            .sink {
                self.connectionState = $0 ? .connected : .notConnected
                self.client?.connection?.didReceive = {
                    guard let image = UIImage(data: $0) else {
                        return log("Couldn't create image")
                    }
                    DispatchQueue.main.async {
                        self.connectionState = .connected
                        self.image = image.rotate(deg: 90)
                    }
                }
            }
            .store(in: &disposables)
    }
}

extension UIImage {
    func rotate(deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

}
