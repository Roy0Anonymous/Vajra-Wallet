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
        if let txid = txid {
            txIds.append(txid)
            print("Register Tx:\(Utils.bytesToHex32Reversed(bytes: Utils.array_to_tuple32(array: txid)))")
        }
    }

    override func registerOutput(output: Bindings.WatchedOutput) {
        outputs.append(output)
    }
}

