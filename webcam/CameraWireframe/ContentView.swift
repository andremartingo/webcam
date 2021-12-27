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
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
            ZStack {
                CameraView(didReceivedImage: { viewModel.didReceivedImage.send($0) },
                           changeCamera: viewModel.didChangeCamera,
                           didChangeQuality: viewModel.didChangeQuality,
                           didChangeCompression: viewModel.$compression.eraseToAnyPublisher())
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    HStack {
                        Circle()
                            .fill(viewModel.connectionState == .connected ? Color.green : Color.red)
                            .frame(width: 20, height: 20)
                        
                        Text(viewModel.connectionState == .connected ? "Connected" :"Connecting...")
                            .padding()
                        
                        Spacer()
                    }
                    .offset(x: 6, y: 0)
                    
                    HStack {
                        flipCameraButton
                        changeQuality
                        questionButton
                        Spacer()
                    }

                    
//                    #if DEBUG
//                    Text(viewModel.description)
//
//
//                    Slider(value: $viewModel.compression, in: 0...1)
//                        .padding()
//                    #endif
                }
                .padding()
            }
            .if(isMock()) { view in
                view
                    .background(
                        Image(uiImage: .init(named: "image")!)
                    )
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
    
    var questionButton: some View {
        Button(action: {
            viewModel.showOnbard()
        }, label: {
            Circle()
                .foregroundColor(Color.gray.opacity(0.2))
                .frame(width: 45, height: 45, alignment: .center)
                .overlay(
                    Image(systemName: "questionmark")
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

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(viewModel: .init())
//    }
//}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
