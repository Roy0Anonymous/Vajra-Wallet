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
        let channels = ldkManager.channelManager?.listChannels()
        if channels!.isEmpty {
            VStack() {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .resizable()
                    .frame(width: 125, height: 150)
                    .scaledToFill()
                    .padding(.bottom, 30)
                    .foregroundColor(.red)
                Text("No Channels Available")
                    .font(.title)
            }
            .navigationTitle(Text("Channels"))
        } else {
            ScrollView {
                ForEach(channels!, id: \.self) { channel in
                    ChannelView(channel: channel)
                    Divider()
                }
            }
            .navigationTitle(Text("Channels"))
        }
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
