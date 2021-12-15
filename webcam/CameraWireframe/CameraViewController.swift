//
//  CameraViewController.swift
//  webcam
//
//  Created by Andre Martingo on 28.02.21.
//


import SwiftUI
import AVFoundation
import UIKit
import Combine
import TinyConstraints

struct CameraView: UIViewRepresentable {
    let didReceivedImage: (Frame) -> Void
    let changeCamera: AnyPublisher<Void, Never>
    let didChangeQuality: AnyPublisher<Quality, Never>
    let didChangeCompression: AnyPublisher<Float, Never>
    
    init(didReceivedImage: @escaping (Frame) -> Void,
         changeCamera: AnyPublisher<Void, Never>,
         didChangeQuality: AnyPublisher<Quality, Never>,
         didChangeCompression: AnyPublisher<Float, Never>) {
        self.didReceivedImage = didReceivedImage
        self.changeCamera = changeCamera
        self.didChangeQuality = didChangeQuality
        self.didChangeCompression = didChangeCompression
    }
    
    func makeUIView(context: Context) -> CameraViewController {
        return CameraViewController(didReceivedImage: didReceivedImage,
                                    changeCamera: changeCamera,
                                    changeQuality: didChangeQuality,
                                    changeCompression: didChangeCompression)
    }
    
    func updateUIView(_ uiView: CameraViewController, context: Context) {}
}

class CameraViewController: UIView {
    private var session: AVCaptureSession?
    private var captureVideoOutput: AVCaptureVideoDataOutput?
    private var deviceInput: AVCaptureDeviceInput?
    let didReceivedImage: (Frame) -> Void
    
    let didChangeCamera: AnyPublisher<Void, Never>
    let didChangeQuality: AnyPublisher<Quality, Never>
    let didChangeCompression: AnyPublisher<Float, Never>
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera,
                                                                                             .builtInDualCamera,
                                                                                             .builtInTrueDepthCamera],
                                                                               mediaType: .video,
                                                                               position: .unspecified)
    
    private var disposables = Set<AnyCancellable>()
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var compression: Float = 0.1

    init(didReceivedImage: @escaping (Frame) -> Void,
         changeCamera: AnyPublisher<Void, Never>,
         changeQuality: AnyPublisher<Quality, Never>,
         changeCompression: AnyPublisher<Float, Never>) {
        self.didReceivedImage = didReceivedImage
        self.didChangeCamera = changeCamera
        self.didChangeQuality = changeQuality
        self.didChangeCompression = changeCompression
        super.init(frame: .zero)
        setupCamera()
        setupCameraOutput()
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }

        do {
//            captureDevice.configureDesiredFrameRate(10)
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            session = AVCaptureSession()
            session?.sessionPreset = AVCaptureSession.Preset.medium
            session?.addInput(deviceInput)
            self.deviceInput = deviceInput
            videoPreviewLayer.session = session
        } catch {
            print("Setup camera error ", error)
        }

        session?.startRunning()
        
        didChangeCamera
            .sink { self.switchCamera() }
            .store(in: &disposables)
        
        didChangeQuality
            .sink { self.changeQuality(quality: $0) }
            .store(in: &disposables)
        
        didChangeCompression
            .sink {
                print($0)
                self.compression = $0
            }
            .store(in: &disposables)
    }

    private func setupCameraOutput() {
        captureVideoOutput = AVCaptureVideoDataOutput()
        let connection = captureVideoOutput?.connection(with: .video)
        connection?.videoOrientation = .portrait
        connection?.isVideoMirrored = true
        session?.addOutput(captureVideoOutput!)

        captureVideoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Sample buffer queue"))
    }
    
    func switchCamera() {
        session?.beginConfiguration()
        let currentInput = session?.inputs.first as? AVCaptureDeviceInput
        session?.removeInput(currentInput!)
        let newCameraDevice = currentInput?.device.position == .back ? getCamera(with: .front) : getCamera(with: .back)
        let newVideoInput = try? AVCaptureDeviceInput(device: newCameraDevice!)
        session?.addInput(newVideoInput!)
        session?.commitConfiguration()
    }

    func changeQuality(quality: Quality) {
        session?.beginConfiguration()
        let preset: AVCaptureSession.Preset = {
            switch quality {
            case .sd:
                self.compression = 0.1
                return .medium
            case .hd:
                self.compression = 0.9
                return .medium
            }
        }()
        
        session?.sessionPreset = preset
        session?.commitConfiguration()
    }

    func getCamera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return videoDeviceDiscoverySession.devices.filter { $0.position == position }.first
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Captured frame!
        guard let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let frame = ciImage.oriented(.left).compressed(by: .init(self.compression))
        let origin = ciImage.compressed(by: 1)
//        print(">>> Uncompressed Size: \(origin?.description)")
//        print(">>> Compressed Size: \(frame?.description)")
        
        // Max bytes is 8K
        didReceivedImage(.init(topHalf: frame!, bottomHalf: frame!))
    }

}

struct Frame {
    let topHalf: Data
    let bottomHalf: Data
}


extension CIImage {

    // Effective compression should be done, better solutions could be
    // https://developer.apple.com/documentation/compression
    // https://github.com/DroidsOnRoids/SwiftCompressor
    func compressed(by factor: CGFloat) -> Data? {
        let context = CIContext()
        let cgImage = context.createCGImage(self, from: self.extent)!
        let topHalf = UIImage(cgImage: cgImage).topHalf!
        let bottomHalf = UIImage(cgImage: cgImage).bottomHalf!
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: factor)
//        do {
//            return try image.heicData(compressionQuality: factor)
//        } catch {
//            print("Error creating HEIC data: \(error.localizedDescription)")
//            return nil
//        }
    }
}

extension UIImage {
  enum HEICError: Error {
    case heicNotSupported
    case cgImageMissing
    case couldNotFinalize
  }
  
  func heicData(compressionQuality: CGFloat) throws -> Data {
    let data = NSMutableData()
    guard let imageDestination =
      CGImageDestinationCreateWithData(
        data, AVFileType.heic as CFString, 1, nil
      )
      else {
        throw HEICError.heicNotSupported
    }
    
    guard let cgImage = self.cgImage else {
      throw HEICError.cgImageMissing
    }
    
    let options: NSDictionary = [
      kCGImageDestinationLossyCompressionQuality: compressionQuality
    ]
    
    CGImageDestinationAddImage(imageDestination, cgImage, options)
    guard CGImageDestinationFinalize(imageDestination) else {
      throw HEICError.couldNotFinalize
    }
    
    return data as Data
  }
}

extension AVCaptureDevice {

    /// http://stackoverflow.com/questions/21612191/set-a-custom-avframeraterange-for-an-avcapturesession#27566730
    func configureDesiredFrameRate(_ desiredFrameRate: Int) {

        var isFPSSupported = false

        do {

            if let videoSupportedFrameRateRanges = activeFormat.videoSupportedFrameRateRanges as? [AVFrameRateRange] {
                for range in videoSupportedFrameRateRanges {
                    if (range.maxFrameRate >= Double(desiredFrameRate) && range.minFrameRate <= Double(desiredFrameRate)) {
                        isFPSSupported = true
                        break
                    }
                }
            }

            if isFPSSupported {
                try lockForConfiguration()
                activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFrameRate))
                activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFrameRate))
                unlockForConfiguration()
            }

        } catch {
            print("lockForConfiguration error: \(error.localizedDescription)")
        }
    }

}

extension UIImage {
    var topHalf: UIImage? {
        guard let cgImage = cgImage, let image = cgImage.cropping(to: CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height/2))) else { return nil }
        return UIImage(cgImage: image, scale: scale, orientation: imageOrientation)
    }
    
    var bottomHalf: UIImage? {
        guard let cgImage = cgImage, let image = cgImage.cropping(to: CGRect(origin: CGPoint(x: 0,  y: CGFloat(Int(size.height)-Int(size.height/2))), size: CGSize(width: size.width, height: CGFloat(Int(size.height) - Int(size.height/2))))) else { return nil }
        return UIImage(cgImage: image, scale: scale, orientation: imageOrientation)
    }
    
    var leftHalf: UIImage? {
        guard let cgImage = cgImage, let image = cgImage.cropping(to: CGRect(origin: .zero, size: CGSize(width: size.width/2, height: size.height))) else { return nil }
        return UIImage(cgImage: image, scale: scale, orientation: imageOrientation)
    }
    
    var rightHalf: UIImage? {
        guard let cgImage = cgImage, let image = cgImage.cropping(to: CGRect(origin: CGPoint(x: CGFloat(Int(size.width)-Int((size.width/2))), y: 0), size: CGSize(width: CGFloat(Int(size.width)-Int((size.width/2))), height: size.height)))
            else { return nil }
        return UIImage(cgImage: image, scale: scale, orientation: imageOrientation)
    }
    
    var splitedInFourParts: [UIImage] {
        guard case let topHalf = topHalf,
              case let bottomHalf = bottomHalf,
            let topLeft = topHalf?.leftHalf,
            let topRight = topHalf?.rightHalf,
            let bottomLeft = bottomHalf?.leftHalf,
            let bottomRight = bottomHalf?.rightHalf else{ return [] }
        return [topLeft, topRight, bottomLeft, bottomRight]
    }
}
