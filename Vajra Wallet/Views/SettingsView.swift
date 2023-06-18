//
//  SettingsView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI
import LightningDevKit

struct SettingsView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @Binding var title: String
    @State private var showAlert = false
    @State private var nodeId: String = ""
    @State private var selection: String?
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    List {
                        Section("Lightning Node") {
                            NavigationLink(destination: NodeIdView()) {
                                Text("Node ID")
                            }
                            NavigationLink (destination: ListPeersView()) {
                                Text("List Peers")
                            }
                            NavigationLink (destination: ConnectToPeerView()) {
                                Text("Connect to a Peer")
                            }
                            NavigationLink (destination: OpenChannelView()) {
                                Text("Open a Channel")
                            }
                            NavigationLink (destination: ListChannelsView()) {
                                Text("List Channels")
                            }
                            NavigationLink (destination: SendPaymentView()) {
                                Text("Send Payment")
                            }
                            NavigationLink (destination: GenerateInvoiceView()) {
                                Text("Generate Invoice")
                            }
                            NavigationLink (destination: CloseChannelView()) {
                                Text("Close Channel")
                            }
                        }
                        
                        Section("On-chain Wallet") {
                            NavigationLink (destination: RecoveryPhraseView()) {
                                Text("Recovery Phrase")
                            }
                            NavigationLink (destination: SendPaymentOnChainView()) {
                                Text("Send Payment On-chain")
                            }
                        }
                    }
                }
                .navigationTitle(Text(title))
            }
        }
        .environmentObject(ldkManager)
        .onAppear() {
            title = "Settings"
        }
    }
}
