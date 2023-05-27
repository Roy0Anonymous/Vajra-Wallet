//
//  ListChannelsView.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import SwiftUI

struct ListChannelsView: View {
    @EnvironmentObject var ldkManager: LDKManager
    var body: some View {
        VStack {
            let channels = ldkManager.listChannelsDict()

            Button("Press me") {
                print("all channels: \(channels)")
            }
        }
    }
}

struct ListChannelsView_Previews: PreviewProvider {
    static var previews: some View {
        ListChannelsView()
    }
}
