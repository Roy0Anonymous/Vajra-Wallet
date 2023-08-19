//
//  SendPaymentOnChainView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 01/06/23.
//

import SwiftUI
import BitcoinDevKit

struct SendPaymentOnChainView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State private var address: String = ""
    @State private var amount: String = ""
    @State private var success: Bool = false
    var body: some View {
        CustomTextField(track: $address, name: "Address")
        CustomTextField(track: $amount, name: "Amount")
        Button {
            do {
                let script = try Address(address: address).scriptPubkey()
                guard let amount = UInt64(amount) else {
                    print("Could not convert amount to UInt64")
                    return
                }
                let transaction = ldkManager.bdkManager.fundChannel(script: script, amount: amount)
                if let transaction = transaction {
                    success = ldkManager.bdkManager.broadcast(transaction: transaction)
                } else {
                    success = false
                }
            } catch {
                print(error.localizedDescription)
            }
        } label: {
            Text("Send")
                .frame(width: 150, height: 50, alignment: .center)
                .background(Color.blue)
                .cornerRadius(10)
                .foregroundColor(.white)
        }
        .alert(isPresented: $success) {
            Alert(title: Text("Payment Sent"))
        }
        .navigationTitle(Text("Send Payment On-Chain"))
    }
}
