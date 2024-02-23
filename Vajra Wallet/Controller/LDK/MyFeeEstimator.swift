//
//  MyFeeEstimator.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit

class MyFeeEstimator: FeeEstimator {
    override func getEstSatPer1000Weight(confirmationTarget: Bindings.ConfirmationTarget) -> UInt32 {
        if confirmationTarget == .MinAllowedNonAnchorChannelRemoteFee {
            return 253
        } else if confirmationTarget == .ChannelCloseMinimum {
            return 1000
        } else if confirmationTarget == .NonAnchorChannelFee {
            return 7500
        } else if confirmationTarget == .OnChainSweep {
            return 7500
        }
        return 7500
    }
}
