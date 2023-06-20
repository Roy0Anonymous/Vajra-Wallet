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
        Text(ldkManager.bdkManager.getRecoveryPhrase()!)
            .font(.title)
            .navigationTitle(Text("Recovery Phrase"))
    }
}
