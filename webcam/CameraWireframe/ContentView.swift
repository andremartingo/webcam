//
//  ContentView.swift
//  webcam
//
//  Created by Andre Martingo on 28.02.21.
//

import SwiftUI

struct ContentView: View {
    let viewModel: CameraViewModel
    
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
                    CameraView(didReceivedImage: { viewModel.didReceivedImage.send($0) }, changeCamera: viewModel.didChangeCamera)
                    
                    flipCameraButton
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: .init())
    }
}
