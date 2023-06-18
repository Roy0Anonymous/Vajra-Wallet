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
    @State private var ldkRunning = true
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
                Button("Sync") {
                    DispatchQueue.global().async {
                        receiveAddress = ldkManager.bdkManager.getAddress(addressIndex: .new)
                    }
                    do {
                        try ldkManager.sync(completion: { result in
                            switch result {
                            case .success():
                                ldkRunning = true
                            case .failure(_):
                                ldkRunning = false
                            }
                        })
                    } catch {
                        print(error)
                        ldkRunning = false
                    }
                }
                Text(receiveAddress ?? "No Address Found")
                if !ldkRunning {
                    Text("Failed to Start Node")
                }
                Spacer()
            }
            .navigationTitle(Text("Wallet"))
            .multilineTextAlignment(.center)
            .padding()
            .onAppear() {
                title = "Wallet"
                if !hasAppeared {
                    DispatchQueue.main.async {
                        hasAppeared = true
                        ldkManager.bdkManager.sync()
                        do {
                            try ldkManager.start(completion: { result in
                                switch result {
                                case .success():
                                    print("Success")
                                    ldkRunning = true
                                case .failure(_):
                                    ldkRunning = false
                                }
                            })
                        } catch {
                            print(error)
                            ldkRunning = false
                        }
                    }
                    DispatchQueue.global().async {
                        receiveAddress = ldkManager.bdkManager.getAddress(addressIndex: .new)
                    }
                }
            }
            .navigationTitle(Text("Wallet"))
        }
    }
}
