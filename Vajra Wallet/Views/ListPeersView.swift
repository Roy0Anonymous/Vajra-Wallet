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
        ScrollView {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                let connectedPeers = ldkManager.listPeers()
                VStack(spacing: 10) {
                    ForEach(connectedPeers, id: \.self) { peer in
                        CustomText(text: peer)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle(Text("Peers"))
    }
}

struct ListPeersView_Previews: PreviewProvider {
    static var previews: some View {
        ListPeersView()
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
