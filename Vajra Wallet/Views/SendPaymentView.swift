//
//  SendPaymentView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 29/05/23.
//

import SwiftUI

struct SendPaymentView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State var invoice: String = ""
    @State var sent: Bool = false
    var body: some View {
        CustomTextField(track: $invoice, name: "Invoice")
        Button {
            sent = ldkManager.sendPayment(invoice: invoice)
        } label: {
            Text("Send")
                .frame(width: 150, height: 50, alignment: .center)
                .background(Color.blue)
                .cornerRadius(10)
                .foregroundColor(.white)
        }
        .alert(isPresented: $sent) {
            Alert(title: Text("Invoice paid Successfully"))
        }
        .navigationTitle(Text("Send Payment"))
    }
}
