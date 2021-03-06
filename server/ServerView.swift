//
//  ServerView.swift
//  server
//
//  Created by Andre Martingo on 05.03.21.
//

import SwiftUI

struct ServerView: View {
    @ObservedObject var viewModel = ServerViewModel()
    
    var body: some View {
        VStack {
            Image(uiImage: viewModel.image)
            HStack {
                Circle()
                    .fill(viewModel.connectionState == .connected ? Color.green : Color.red)
                    .frame(width: 50, height: 50)
                
                Text(viewModel.connectionState == .connected ? "Connected" :"Connecting...")
                    .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ServerView()
    }
}
