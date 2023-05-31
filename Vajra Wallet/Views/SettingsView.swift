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
    @State private var showAlert = false
    @State private var nodeId: String = ""
    @State private var selection: String?
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                ScrollView {
                    Text("Lightning Node")
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 25)
                        .padding(.top, 20)
                    Divider()
                    VStack(spacing: 15) {
                        Button {
                            nodeId = ldkManager.getNodeId()
                            showAlert = true
                        } label: {
                            SettingsText(text: "Node ID")
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("\(ldkManager.getNodeId())"), message: nil, primaryButton: .default(Text("Copy"), action: {
                                UIPasteboard.general.string = nodeId
                            }), secondaryButton: .cancel(Text("Cancel")))
                        }
                        NavigationLink (destination: ListPeersView()) {
                            SettingsText(text: "List Peers")
                        }
                        NavigationLink (destination: ConnectToPeerView()) {
                            SettingsText(text: "Connect to a Peer")
                        }
                        NavigationLink (destination: OpenChannelView()) {
                            SettingsText(text: "Open a Channel")
                        }
                        NavigationLink (destination: ListChannelsView()) {
                            SettingsText(text: "List Channels")
                        }
                        NavigationLink (destination: SendPaymentView()) {
                            SettingsText(text: "Send Payment")
                        }
                        NavigationLink (destination: GenerateInvoiceView()) {
                            SettingsText(text: "Generate Invoice")
                        }
                        NavigationLink (destination: CloseChannelView()) {
                            SettingsText(text: "Close Channel")
                        }
                    }
                    Text("On Chain Wallet")
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 25)
                        .padding(.top, 30)
                    Divider()
                    VStack(spacing: 15) {
                        NavigationLink (destination: RecoveryPhraseView()) {
                            SettingsText(text: "Recovery Phrase")
                        }
                        NavigationLink (destination: SendPaymentOnChainView()) {
                            SettingsText(text: "Send Payment On-chain")
                        }
                    }
                }
                .navigationTitle(Text("Settings"))
                .environmentObject(ldkManager)
                
            }
        }
    }
}

struct SettingsText: View {
    var text: String
    var body: some View {
        HStack {
            Text(text)
                .font(.title3)
                .padding(.leading)
            Spacer()
            Image(systemName: "chevron.right")
                .padding(.trailing)
        }
        .frame(maxWidth: .infinity, idealHeight: 50)
        .background(Color.init(uiColor: UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .edgesIgnoringSafeArea(.horizontal)
        .padding(.horizontal)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
