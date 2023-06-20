//
//  RecoverWalletView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 16/06/23.
//

import SwiftUI

struct RecoverWalletView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State var mnemonicStr: String = ""
    @State var recovered: Bool = false
    var body: some View {
        VStack(spacing: 10) {
            CustomTextField(track: $mnemonicStr, name: "Mnemonic")
            Button {
                recovered = ldkManager.bdkManager.recoverWallet(mnemonicStr: mnemonicStr)
            } label: {
                Text("Recover")
                    .frame(width: 150, height: 50, alignment: .center)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
        }
        .navigationTitle(Text("Recover Wallet"))
        .navigationDestination(isPresented: $recovered) {
            TabBarView()
        }
    }
}
