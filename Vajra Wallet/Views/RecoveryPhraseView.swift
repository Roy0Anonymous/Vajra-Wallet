//
//  RecoveryPhraseView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 28/05/23.
//

import SwiftUI

struct RecoveryPhraseView: View {
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        VStack {
            Text(ldkManager.bdkManager.getRecoveryPhrase()!)
                .font(.title)
                .navigationTitle(Text("Recovery Phrase"))
            Button {
                UIPasteboard.general.string = ldkManager.bdkManager.getRecoveryPhrase()!
            } label: {
                Text("Copy to Clipboard")
                    .foregroundColor(.white)
            }
            .frame(width: 150, height: 50, alignment: .center)
            .background(.blue)
            .cornerRadius(10)
        }
    }
}
