//
//  MerkleProof.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import Foundation

public struct MerkleProof: Codable {
    let block_height: Int32
    let merkle: [String]
    let pos: UInt
}
