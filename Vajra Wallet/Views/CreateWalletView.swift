//
//  CreateWalletView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI
import BitcoinDevKit

struct CreateWalletView: View {
    @State var walletCreated: Bool = false
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        NavigationStack {
            VStack {
                Button {
                    walletCreated = true
                    ldkManager.bdkManager.createWallet()
                } label: {
                    Text("Create Wallet")
                        .foregroundColor(.white)
                }
                .frame(width: 150, height: 50, alignment: .center)
                .background(.orange)
                .cornerRadius(15)
                .navigationTitle(Text("Create Wallet"))
                .navigationDestination(isPresented: $walletCreated) {
                    if walletCreated {
                        TabBarView()
                            .environmentObject(ldkManager)
                    }
                }
                
                NavigationLink {
                    RecoverWalletView()
                } label: {
                    Text("Recover Wallet")
                }

            }
        }
    }
}

struct CreateWalletView_Previews: PreviewProvider {
    static var previews: some View {
        CreateWalletView()
    }
}
