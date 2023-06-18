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
    @State var hasLoaded: Bool = false
    let mnemonicIsPresent = FileHandler.fileExists(path: "Mnemonic")
    var body: some Scene {
        WindowGroup {
            if mnemonicIsPresent {
                TabBarView()
                    .environmentObject(ldkManager)
            } else {
                CreateWalletView()
                    .environmentObject(ldkManager)
            }
        }
    }
}
