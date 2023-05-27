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
            ContentView()
                .tabItem {
                    Label("Transfer", systemImage: "paperplane.fill")
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
