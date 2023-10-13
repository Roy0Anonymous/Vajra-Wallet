//
//  OpenChannelView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct OpenChannelView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State private var peerPubkeyIp: String = ""
    @State private var channelOpened: Bool = false
    @State private var amount: String = ""
    var body: some View {
        VStack {
            CustomTextField(track: $amount, name: "Amount")
            CustomTextField(track: $peerPubkeyIp, name: "PeerId@Address:Port")
            Button {
                if let amount = UInt64(amount) {
                    channelOpened = ldkManager.openChannel(peerPubkeyIp: peerPubkeyIp, amount: amount, pushMsat: 0)
                }
            } label: {
                Text("Open Channel")
                    .frame(width: 150, height: 50, alignment: .center)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            .alert(isPresented: $channelOpened) {
                Alert(title: Text("Channel Opened"))
            }
        }
        .navigationTitle(Text("Open a Channel"))
    }
}
