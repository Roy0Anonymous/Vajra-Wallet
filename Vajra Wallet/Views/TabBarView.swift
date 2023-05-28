//
//  TabBarView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        TabView {
            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass")
                }
                .environmentObject(ldkManager)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .environmentObject(ldkManager)
        }
    }
}
