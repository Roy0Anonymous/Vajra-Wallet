//
//  SettingsView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI
import LightningDevKit

struct CustomText: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
    }
}

struct SettingsView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State private var showAlert = false
    @State private var nodeId: String = ""
    @State private var selection: String?
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Button {
                        showAlert = true
                    } label: {
                        CustomText(text: "Node ID")
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("\(ldkManager.getNodeId())"), message: nil, primaryButton: .default(Text("Copy"), action: {
                            UIPasteboard.general.string = nodeId
                        }), secondaryButton: .cancel(Text("Cancel")))
                    }
                    
                    NavigationLink (destination: ListPeersView()) {
                        CustomText(text: "List Peers")
                    }
                    NavigationLink (destination: ConnectToPeerView()) {
                        CustomText(text: "Connect to a Peer")
                    }
                    NavigationLink (destination: OpenChannelView()) {
                        CustomText(text: "Open a Channel")
                    }
                    NavigationLink (destination: ListChannelsView()) {
                        CustomText(text: "List Channel")
                    }
                    NavigationLink (destination: ListUsableChannelsView()) {
                        CustomText(text: "List Usable Channel")
                    }
                }
                .navigationTitle(Text("Settings"))
                .environmentObject(ldkManager)
            }
        }
    }
}
