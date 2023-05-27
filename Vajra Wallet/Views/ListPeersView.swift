//
//  ListPeersView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct ListPeersView: View {
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        VStack {
            let connectedPeers = ldkManager.listPeers()
            ForEach(connectedPeers, id: \.self) { peer in
                CustomText(text: peer)
            }
        }
    }
}

struct ListPeersView_Previews: PreviewProvider {
    static var previews: some View {
        ListPeersView()
    }
}
