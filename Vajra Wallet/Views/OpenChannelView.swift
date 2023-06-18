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
    var body: some View {
        VStack {
            CustomTextField(track: $peerPubkeyIp, name: "PeerId@Address:Port")
            Button {
                let amount: UInt64 = 100000
                print(ldkManager.openChannel(peerPubkeyIp: peerPubkeyIp, amount: amount, pushMsat: 0) ? "Channel Opened" : "Failed to Open Channel")
            } label: {
                Text("Connect")
                    .frame(width: 150, height: 50, alignment: .center)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }

        }
    }
}

struct OpenChannelView_Previews: PreviewProvider {
    static var previews: some View {
        OpenChannelView()
    }
}
