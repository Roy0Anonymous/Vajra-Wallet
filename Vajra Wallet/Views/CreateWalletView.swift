//
//  CreateWalletView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI
import BitcoinDevKit

struct CreateWalletView: View {
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        Button {
            ldkManager.bdkManager.createWallet()
            ldkManager.objectWillChange.send()
        } label: {
            Text("Create Wallet")
        }
        .frame(width: 150, height: 50, alignment: .center)
        .background(.orange)
        .cornerRadius(15)
    }
}

struct CreateWalletView_Previews: PreviewProvider {
    static var previews: some View {
        CreateWalletView()
    }
}
