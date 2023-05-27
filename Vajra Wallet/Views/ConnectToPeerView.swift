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
        VStack {
            TextField(text: $nodeId) {
                Text("Enter the Node ID")
            }
//            TextField(text: $host) {
//                Text("Enter the Host IP")
//            }
            TextField(text: $port) {
                Text("Enter the Port")
            }
            Button("Connect") {
                guard let port = NumberFormatter().number(from: port) else {
                    print("Wrong Port")
                    return
                }
                do {
                    // Change later
//                    try connected = ldkManager.connect(nodeId: nodeId, address: host, port: port)
                    // "02c4ae0b56bad8dc502326a479c0d8a820b0acc7c5470a056da050cedd84afbd36" 9937
                    try connected = ldkManager.connect(nodeId: nodeId, address: "127.0.0.1", port: port)
                } catch {
                    print(error)
                }
            }
            .alert(isPresented: $connected) {
                Alert(title: Text("Connected to Peer"))
            }
        }
    }
}

struct ConnectToPeerView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectToPeerView()
    }
}
