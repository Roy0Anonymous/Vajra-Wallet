//
//  ListUsableChannels.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct ListUsableChannelsView: View {
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        VStack {
            let channels = ldkManager.listUsableChannelsDict()

            Button("Press me") {
                print("Usable channels: \(channels)")
            }
        }
    }
}

struct ListUsableChannelsView_Previews: PreviewProvider {
    static var previews: some View {
        ListUsableChannelsView()
    }
}
