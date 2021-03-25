//
//  ContentView.swift
//  webcam
//
//  Created by Andre Martingo on 28.02.21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject
    var viewModel: CameraViewModel
    
    //    let binding: Binding<Bool>
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        //        let binding = Binding<Bool>.init(get: { return viewModel.output }, set: { _ in viewModel.changeCamera() })
        //        self.binding = binding
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    CameraView(didReceivedImage: { viewModel.didReceivedImage.send($0) },
                               changeCamera: viewModel.didChangeCamera,
                               didChangeQuality: viewModel.didChangeQuality,
                               didChangeCompression: viewModel.$compression.eraseToAnyPublisher())
                    HStack {
                        Spacer()
                        flipCameraButton
                        changeQuality
                        Spacer()
                    }
                    
                    
                    Slider(value: $viewModel.compression, in: 0...1)
                        .padding()
                }
            }
        }
    }
    
    var flipCameraButton: some View {
        Button(action: {
            viewModel.changeCamera()
        }, label: {
            Circle()
                .foregroundColor(Color.gray.opacity(0.2))
                .frame(width: 45, height: 45, alignment: .center)
                .overlay(
                    Image(systemName: "camera.rotate.fill")
                        .foregroundColor(.white))
        })
    }
    
    var changeQuality: some View {
        Picker("Quality", selection: $viewModel.quality, content: {
            Text("SD")
                .tag(0)
            
            Text("HD")
                .tag(1)
        })
        .pickerStyle(SegmentedPickerStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: .init())
    }
}
