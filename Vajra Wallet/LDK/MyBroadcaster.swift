//
//  MyBroadcaster.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit

class MyBroacaster: BroadcasterInterface {
    weak var ldkManager: LDKManager? = nil
    override func broadcastTransactions(txs: [[UInt8]]) {
        var txId: [String]?
        if ldkManager!.network == .Regtest {
            txId = BlockchainData.broadcastTx(txs: txs, network: .Regtest)
        } else {
            txId = BlockchainData.broadcastTx(txs: txs, network: .Testnet)
        }
        print("Broadcast Transaction TxId: \(String(describing: txId))")
    }
}
