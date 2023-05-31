//
//  ContentView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State private var receiveAddress: String?
    @State private var hasAppeared = false
    var body: some View {
        VStack(spacing: 15) {
            Text("Wallet")
                .font(.title)
                .bold()
                .padding(.bottom, 50)
            switch ldkManager.bdkManager.syncState {
            case .syncing:
                Text("Syncing")
            case .synced:
                HStack(alignment: .firstTextBaseline) {
                    Text((ldkManager.bdkManager.balance?.total.description)!)
                    Text("Sats")
                }
            case .notsynced:
                Text("Not synced")
            case .failed:
                Text("Sync failed")
            }
            Button("Sync") {
                receiveAddress = ldkManager.bdkManager.getAddress(addressIndex: .new)
                ldkManager.sync()
            }
            Text(receiveAddress ?? "No Address Found")
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
//        .onAppear {
//            if !hasAppeared {
//                hasAppeared = true
//                receiveAddress = ldkManager.bdkManager.getAddress(addressIndex: .new)
//            }
//            ldkManager.bdkManager.sync()
//        }
    }
}
