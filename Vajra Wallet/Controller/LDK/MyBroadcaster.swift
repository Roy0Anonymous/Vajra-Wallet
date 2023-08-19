//
//  MyBroadcaster.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit
import BitcoinDevKit

class MyBroacaster: BroadcasterInterface {
    weak var ldkManager: LDKManager? = nil
    override func broadcastTransactions(txs: [[UInt8]]) {
        var txId: [String] = []
        let esploraURL: String
        if ldkManager!.network == .Regtest {
            esploraURL = "http://127.0.0.1:3002"
        } else {
            esploraURL = "https://mempool.space/testnet/api"
        }
        let esploraConfig = EsploraConfig(baseUrl: esploraURL, proxy: nil, concurrency: 5, stopGap: 20, timeout: nil)
        let blockchainConfig = BlockchainConfig.esplora(config: esploraConfig)
        do {
            let blockchain = try Blockchain(config: blockchainConfig)
            for tx in txs {
                let transaction = try Transaction(transactionBytes: tx)
                try blockchain.broadcast(transaction: transaction)
                txId.append(transaction.txid())
            }
        } catch {
            print("Failed to broadcast transaction: \(error.localizedDescription)")
        }
        print("Broadcast Transaction TxId: \(String(describing: txId))")
    }
}
