//
//  MyFilter.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit

class MyFilter: Filter {
    var txIds:[[UInt8]] = [[UInt8]]()
    var outputs:[Bindings.WatchedOutput] = [Bindings.WatchedOutput]()
    override func registerTx(txid: [UInt8]?, scriptPubkey: [UInt8]) {
        debugPrint("Register Tx: \(Utils.bytesToHex32Reversed(bytes: Utils.arrayToTuple32(array: txid!)))")
        if let txid = txid {
            txIds.append(txid)
        }
    }

    override func registerOutput(output: Bindings.WatchedOutput) {
        debugPrint("Register Output: \(Utils.bytesToHex32Reversed(bytes: Utils.arrayToTuple32(array: output.getOutpoint().getTxid()!)))")
        outputs.append(output)
    }
}

