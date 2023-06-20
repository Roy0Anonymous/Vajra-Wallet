//
//  NodeIdView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 18/06/23.
//

import SwiftUI

struct NodeIdView: View {
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        VStack {
            CustomText(text: ldkManager.getNodeId())
            Button {
                UIPasteboard.general.string = ldkManager.getNodeId()
            } label: {
                Text("Copy to Clipboard")
                    .foregroundColor(.white)
            }
            .frame(width: 150, height: 50, alignment: .center)
            .background(.blue)
            .cornerRadius(10)
        }
        .navigationTitle(Text("Node Id"))
    }
}
