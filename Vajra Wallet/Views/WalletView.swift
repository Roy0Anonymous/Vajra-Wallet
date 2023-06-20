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
    @State private var ldkFailed = false
    @Binding var title: String
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
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
                Text(receiveAddress ?? "No Address Found")
                HStack {
                    Button {
                        LDKManager.ldkQueue.async {
                            receiveAddress = ldkManager.bdkManager.getAddress(addressIndex: .new)
                        }
                        LDKManager.ldkQueue.async {
                            do {
                                try ldkManager.sync()
                            } catch {
                                ldkFailed = true
                            }
                        }
                    } label: {
                        Text("Sync")
                            .frame(width: 150, height: 50, alignment: .center)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        UIPasteboard.general.string = receiveAddress
                    } label: {
                        Text("Copy to Clipboard")
                            .foregroundColor(.white)
                    }
                    .frame(width: 150, height: 50, alignment: .center)
                    .background(.blue)
                    .cornerRadius(10)
                }
                Spacer()
            }
            .navigationTitle(Text("Wallet"))
            .multilineTextAlignment(.center)
            .padding()
            .onAppear() {
                title = "Wallet"
                if !hasAppeared {
                    hasAppeared = true
                    LDKManager.ldkQueue.async {
                        receiveAddress = ldkManager.bdkManager.getAddress(addressIndex: .new)
                    }
                    LDKManager.ldkQueue.async {
                        do {
                            try ldkManager.start()
                        } catch {
                            ldkFailed = true
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $ldkFailed) {
                NodeErrorView()
            }
        }
    }
}
