//
//  Tx.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import Foundation

public class WatchedTransaction {
    public let id: [UInt8]
    public let scriptPubKey: [UInt8]
    
    init(id: [UInt8], scriptPubKey: [UInt8]) {
        self.id = id
        self.scriptPubKey = scriptPubKey
    }
}

public struct Tx: Codable {
    let txid: String
    let status: TxStatus
}

public struct TxStatus: Codable {
    let confirmed: Bool
    let block_height: Int32
    let block_hash: String
}

public struct ConfirmedTx {
    let txId: String
    let tx: [UInt8]
    let block_height: Int32
    let block_header: String
    let merkle_proof_pos: UInt
}

public struct OutSpent: Codable {
    let spent: Bool
    let txid: String?
    let vin: Int?
}
