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
            return 1250
        } else if confirmationTarget == .Normal {
            return 1250
        } else if confirmationTarget == .HighPriority {
            return 1250
        }
        return 1250
    }
}
