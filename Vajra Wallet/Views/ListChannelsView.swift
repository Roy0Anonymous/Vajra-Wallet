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
        let balanceChannel = ldkManager.listChannels()
        if balanceChannel.1.isEmpty {
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
            Text("Total Balance: \(balanceChannel.0)")
                .font(.title3)
                .frame(maxWidth: .infinity)
            ScrollView {
                ForEach(balanceChannel.1, id: \.self) { channel in
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
            Text("Channel Balance:\n \(channel.getBalanceMsat())")
            Text("Outbound Capactity:\n \(channel.getOutboundCapacityMsat())")
            Text("Inbound Capactity:\n \(channel.getInboundCapacityMsat())")
            Button {
                UIPasteboard.general.string = Utils.bytesToHex(bytes: channel.getChannelId()!)
            } label: {
                Text("Copy Channel ID")
                    .foregroundColor(.white)
            }
            .frame(width: 150, height: 50, alignment: .center)
            .background(.blue)
            .cornerRadius(10)
        }
        .multilineTextAlignment(.center)
    }
}
