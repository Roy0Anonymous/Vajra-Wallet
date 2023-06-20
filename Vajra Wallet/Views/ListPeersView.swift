//
//  ListPeersView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct ListPeersView: View {
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        let connectedPeers = ldkManager.listPeers()
        if connectedPeers.isEmpty {
            VStack() {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .resizable()
                    .frame(width: 125, height: 150)
                    .scaledToFill()
                    .padding(.bottom, 30)
                    .foregroundColor(.red)
                Text("No Peers Available")
                    .font(.title)
            }
            .navigationTitle(Text("Peers"))
        } else {
            ScrollView {
                ForEach(connectedPeers, id: \.self) { peer in
                    CustomText(text: peer)
                }
            }
            .navigationTitle(Text("Peers"))
        }
    }
}

struct CustomText: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.title3)
            .padding(.leading)
            .frame(maxWidth: .infinity)
            .background(Color.init(uiColor: UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .edgesIgnoringSafeArea(.horizontal)
            .padding(.horizontal)
    }
}
