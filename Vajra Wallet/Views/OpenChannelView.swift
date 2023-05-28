//
//  OpenChannelView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct OpenChannelView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State private var nodeId: String = ""
    var body: some View {
        VStack {
            CustomTextField(track: $nodeId, name: "Node Id")
            Button("Connect") {
                print(ldkManager.openChannel(nodeId: nodeId, amount: 10000000, pushMsat: 10000) ? "Channel Opened" : "Failed to Open Channel")
            }
        }
    }
}

struct OpenChannelView_Previews: PreviewProvider {
    static var previews: some View {
        OpenChannelView()
    }
}
