//
//  MyFeeEstimator.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit

class MyFeeEstimator: FeeEstimator {
    override func getEstSatPer1000Weight(confirmationTarget: Bindings.ConfirmationTarget) -> UInt32 {
        if confirmationTarget == .Background {
            return 12500
        } else if confirmationTarget == .Normal {
            return 12500
        } else if confirmationTarget == .HighPriority {
            return 12500
        }
        return 12500
    }
}
