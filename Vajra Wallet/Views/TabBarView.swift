//
//  TabBarView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State var title: String = "Wallet"
    var body: some View {
        TabView {
            WalletView(title: $title)
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass")
                }
                .environmentObject(ldkManager)
            SettingsView(title: $title)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .environmentObject(ldkManager)
        }
        .navigationTitle(Text(title))
        .navigationBarBackButtonHidden()
    }
}
