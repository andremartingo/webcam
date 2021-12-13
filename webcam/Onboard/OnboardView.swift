//
//  OnboardView.swift
//  webcam
//
//  Created by Andre Martingo on 10.12.21.
//

import SwiftUI

struct OnboardView: View {
    let viewModel: OnboardViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Getting Started")
                    .bold()
                    .font(.title2)
                Spacer()
            }
            
            HStack {
                Text("It's easy to get started")
                Spacer()
            }
            
            VStack(spacing: 32) {
                HStack(alignment: .top, spacing: 16) {
                    Text("1")
                        .bold()
                        .font(.system(size: 50))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Download and install in your Mac")
                            .bold()
                        Button(action: { viewModel.showShare() }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.body)
                                    .foregroundColor(.blue)
                                
                                Text("Share")
                                    .bold()
                                    .foregroundColor(.blue)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        
                    }
                    
                    Spacer()
                }
                
                HStack(alignment: .top, spacing: 16) {
                    Text("2")
                        .bold()
                        .font(.system(size: 50))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Connect to Mac")
                            .bold()
                        
                        Text("Connect your iPhone to Mac through Apple cable and make sure both are in the same network.")
                        
                    }
                    
                    Spacer()
                }
                
                HStack(alignment: .top, spacing: 16) {
                    Text("3")
                        .bold()
                        .font(.system(size: 50))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Share Image")
                            .bold()
                        
                        Text("Always open the iPhone app before to connect to any platform (Zoom, Google Meet)")
                    }
                    
                    Spacer()
                }
            }
            .offset(x: 0, y: 16)
            Spacer()
        }
        .padding()
    }
}

struct OnboardView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardView(viewModel: .init(wireframe: OnboardWireframe(navigationController: .init())))
    }
}
