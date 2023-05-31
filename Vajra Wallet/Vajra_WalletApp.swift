//
//  Vajra_WalletApp.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

@main
struct Vajra_WalletApp: App {
    @ObservedObject var ldkManager: LDKManager = LDKManager(net: .Testnet)
    var body: some Scene {
        WindowGroup {
            if ldkManager.bdkManager.wallet == nil {
                CreateWalletView()
                    .environmentObject(ldkManager)
            } else {
                TabBarView()
                    .environmentObject(ldkManager)
            }
        }
    }
}
