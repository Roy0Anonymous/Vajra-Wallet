//
//  MyBroadcaster.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit

class MyBroacaster: BroadcasterInterface {
    override func broadcastTransaction(tx: [UInt8]) {
        let txId = BlockchainData.broadcastTx(tx: tx)
        print("Broadcast Transaction TxId: \(String(describing: txId))")
    }
}
