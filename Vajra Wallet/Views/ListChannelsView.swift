//
//  ListChannelsView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI
import LightningDevKit

struct ListChannelsView: View {
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        ScrollView {
            VStack {
                let channels = ldkManager.channelManager?.listChannels()
                ForEach(channels!, id: \.self) { channel in
                    ChannelView(channel: channel)
                    Divider()
                }
                Spacer()
            }
        }
        .navigationTitle(Text("Channels"))
    }
}

struct ListChannelsView_Previews: PreviewProvider {
    static var previews: some View {
        ListChannelsView()
    }
}

struct ChannelView: View {
    let channel: ChannelDetails
    var body: some View {
        VStack {
            if channel.getIsUsable() {
                Text("Active")
                    .foregroundColor(.green)
            } else {
                Text("Not Active")
                    .foregroundColor(.red)
            }
            Text("Channel Id")
            Text("\(Utils.bytesToHex(bytes: channel.getChannelId()!))")
            Text("Total Balance:\n \(channel.getBalanceMsat())")
            Text("Outbound Capactity:\n \(channel.getOutboundCapacityMsat())")
            Text("Inbound Capactity:\n \(channel.getInboundCapacityMsat())")
        }
        .multilineTextAlignment(.center)
    }
}
