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
            TextField(text: $nodeId) {
                Text("Enter the Node ID")
            }
            Button("Connect") { //"02c4ae0b56bad8dc502326a479c0d8a820b0acc7c5470a056da050cedd84afbd36"
                print(ldkManager.openChannel(nodeId: nodeId, amount: 10000000, pushMsat: 10000) ? "Sab Change" : "Ghanta Change")
            }
        }
    }
}

struct OpenChannelView_Previews: PreviewProvider {
    static var previews: some View {
        OpenChannelView()
    }
}
