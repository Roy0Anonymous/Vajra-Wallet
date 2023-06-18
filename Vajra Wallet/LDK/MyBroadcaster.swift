//
//  MyBroadcaster.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit

class MyBroacaster: BroadcasterInterface {
    var ldkManager: LDKManager? = nil
    override func broadcastTransaction(tx: [UInt8]) {
        var txId: String?
        if ldkManager!.network == .Regtest {
            txId = BlockchainData.broadcastTx(tx: tx, network: .Regtest)
        } else {
            txId = BlockchainData.broadcastTx(tx: tx, network: .Testnet)
        }
        print("Broadcast Transaction TxId: \(String(describing: txId))")
    }
}
