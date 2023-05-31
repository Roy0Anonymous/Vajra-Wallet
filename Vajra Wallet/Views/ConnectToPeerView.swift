//
//  ConnectToPeerView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct ConnectToPeerView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State private var nodeId: String = ""
    @State private var host: String = ""
    @State private var port: String = ""
    @State private var connected: Bool = false
    var body: some View {
        VStack(spacing: 10) {
            CustomTextField(track: $nodeId, name: "Node Id")
            CustomTextField(track: $host, name: "Host")
            CustomTextField(track: $port, name: "Port")
            Button {
                guard let port = NumberFormatter().number(from: port) else {
                    print("Wrong Port")
                    return
                }
                do {
                    connected = try ldkManager.connect(nodeId: nodeId, address: host, port: port)
                } catch {
                    print(error)
                }
            } label: {
                Text("Connect")
                    .frame(width: 150, height: 50, alignment: .center)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            .alert(isPresented: $connected) {
                Alert(title: Text("Connected to Peer"))
            }
        }
        .navigationTitle(Text("Connect to Peer"))
    }
}

struct ConnectToPeerView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectToPeerView()
    }
}

struct CustomTextField: View {
    @Binding var track: String
    let name: String
    var body: some View {
        ZStack {
            TextField("", text: $track)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(10)
                .padding(.horizontal)
                .keyboardType(.decimalPad)
            if track.isEmpty {
                Text("Enter the \(name)")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundColor(.gray.opacity(0.4))
                    .allowsHitTesting(false)
                    .padding(.horizontal)
            }
        }
    }
}
