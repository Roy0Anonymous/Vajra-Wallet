//
//  ConnectToPeerView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct ConnectToPeerView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State private var peerPubkeyIp: String = ""
    @State private var connected: Bool = false
    var body: some View {
        VStack(spacing: 10) {
            CustomTextField(track: $peerPubkeyIp, name: "PeerId@Address:Port")
            Button {
                connected = ldkManager.connect(peerPubkeyIp: peerPubkeyIp)
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
