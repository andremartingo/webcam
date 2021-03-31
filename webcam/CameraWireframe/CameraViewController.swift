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

struct CameraView: UIViewRepresentable {
    
    let didReceivedImage: (Data) -> Void
    let changeCamera: AnyPublisher<Void, Never>
    let didChangeQuality: AnyPublisher<Quality, Never>
    let didChangeCompression: AnyPublisher<Float, Never>
    
    init(didReceivedImage: @escaping (Data) -> Void,
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
    let didReceivedImage: (Data) -> Void
    
    let didChangeCamera: AnyPublisher<Void, Never>
    let didChangeQuality: AnyPublisher<Quality, Never>
    let didChangeCompression: AnyPublisher<Float, Never>
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera,
                                                                                             .builtInDualCamera, .builtInTrueDepthCamera],
                                                                               mediaType: .video,
                                                                               position: .unspecified)
    
    private var disposables = Set<AnyCancellable>()
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var compression: Float = 0

    init(didReceivedImage: @escaping (Data) -> Void,
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }

        do {
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
        session?.sessionPreset = quality == Quality.sd ? .medium : .hd1280x720
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

        let frame = ciImage.compressed(by: .init(self.compression))
        let origin = ciImage.compressed(by: 1)
//        print(">>> Uncompressed Size: \(origin?.description)")
//        print(">>> Compressed Size: \(frame?.description)")
        
        // Max bytes is 8K
        didReceivedImage(frame!)
    }

}


extension CIImage {

    // Effective compression should be done, better solutions could be
    // https://developer.apple.com/documentation/compression
    // https://github.com/DroidsOnRoids/SwiftCompressor
    func compressed(by factor: CGFloat) -> Data? {
        let context = CIContext()
        let cgImage = context.createCGImage(self, from: self.extent)!
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: factor)
    }
}
