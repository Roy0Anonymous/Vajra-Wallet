//
//  ReceivePaymentView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 30/05/23.
//

import SwiftUI

struct GenerateInvoiceView: View {
    @EnvironmentObject var ldkManager: LDKManager
    @State var amount: String = ""
    @State var expiry: String = ""
    @State private var generated: Bool = false
    @State var invoice: String? = ""
    var body: some View {
        CustomTextField(track: $amount, name: "Amount")
        CustomTextField(track: $expiry, name: "Expiry")
        Button {
            if let amount = UInt64(amount), let expiry = UInt32(expiry) {
                invoice = ldkManager.generateInvoice(amount: amount, expiry: expiry)
            } else {
                invoice = nil
            }
            generated = true
        } label: {
            Text("Generate Invoice")
                .frame(width: 150, height: 50, alignment: .center)
                .background(Color.blue)
                .cornerRadius(10)
                .foregroundColor(.white)
        }
        .alert(isPresented: $generated) {
            Alert(title: Text("\(invoice != nil ? invoice! : "Could not Generate Invoice")"), message: nil, primaryButton: .default(Text("Copy"), action: {
                UIPasteboard.general.string = invoice
            }), secondaryButton: .cancel(Text("Cancel")))
        }
    }
}

struct ReceivePaymentView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateInvoiceView()
    }
}
