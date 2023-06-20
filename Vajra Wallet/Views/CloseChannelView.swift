//
//  CloseChannelView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 31/05/23.
//

import SwiftUI

struct CloseChannelView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State private var channelId: String = ""
    @State private var counterpartyNodeId: String = ""
    @State private var closed: Bool = false
    var body: some View {
        CustomTextField(track: $channelId, name: "Channel Id")
        CustomTextField(track: $counterpartyNodeId, name: "Counterparty Node Id")
        Button {
            closed = ldkManager.closeChannel(channelId: Utils.hexStringToByteArray(channelId), counterpartyNodeId:  Utils.hexStringToByteArray(counterpartyNodeId))
        } label: {
            Text("Close Channel")
                .frame(width: 150, height: 50, alignment: .center)
                .background(Color.blue)
                .cornerRadius(10)
                .foregroundColor(.white)
        }
        .alert(isPresented: $closed) {
            Alert(title: Text("Channel Closed Successfully"))
        }
        .navigationTitle(Text("Close Channel"))
    }
}
