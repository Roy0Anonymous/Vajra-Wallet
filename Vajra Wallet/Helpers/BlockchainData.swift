//
//  BlockchainData.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import Foundation

class BlockchainData {
    static func broadcastTx(tx: [UInt8]) -> String? {
        print("Broadcasting Transaction")
        guard let url = URL(string: "http://127.0.0.1:3002/tx") else {
            print("Invalid URL")
            return nil
        }
        do {
            let res = try DataGetPost.post(url: url, body: Utils.bytesToHex(bytes: tx))
            guard let res = res else {
                print("No Result found")
                return nil
            }
            let txId = String(decoding: res, as: UTF8.self)
            return txId
        } catch {
            print("Error while data POST: \(error.localizedDescription)")
            return nil
        }
    }

    static func getTx(txid: String) -> Tx? {
        print("Getting Transaction")
        guard let url = URL(string: "http://127.0.0.1:3002/tx/\(txid)") else {
            debugPrint("Invalid URL")
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let data = DataGetPost.get(url: url)
            guard let data = data else {
                print("No data found")
                return nil
            }
            let tx = try decoder.decode(Tx.self, from: data)
            return tx
        } catch {
            print("Error while decoding data: \(error.localizedDescription)")
            return nil
        }
    }

    static func getTxHex(txid: String) -> String? {
        print("Getting Transaction Hex")
        guard let url = URL(string: "http://127.0.0.1:3002/tx/\(txid)/hex") else {
            print("Invalid URL")
            return nil
        }
        let data = DataGetPost.get(url: url)
        guard let data = data else {
            print("No data found")
            return nil
        }
        return String(data: data, encoding: .utf8)!
    }

    static func getBlockHeader(hash: String) -> String? {
        print("Getting Block Header")
        guard let url = URL(string: "http://127.0.0.1:3002/block/\(hash)/header") else {
            print("Invalid URL")
            return nil
        }
        let data = DataGetPost.get(url: url)
        guard let data = data else {
            print("No data found")
            return nil
        }
        return String(data: data, encoding: .utf8)!
    }
    
    static func getMerkleProof(txid: String) -> MerkleProof? {
        print("Getting Merkle Proof")
        guard let url = URL(string: "http://127.0.0.1:3002/tx/\(txid)/merkle-proof") else {
            print("Invalid URL")
            return nil
        }
        do {
            let data = DataGetPost.get(url: url)
            guard let data = data else {
                print("No data found")
                return nil
            }
            let res: MerkleProof? = try JSONDecoder().decode(MerkleProof.self, from: data)
            return res
        }
        catch {
            print("Error while decoding Merkle Proof: \(error.localizedDescription)")
            return nil
        }
    }

    static func getTxStatus(txid: String) -> TxStatus? {
        print("Getting Transaction Status")
        guard let url = URL(string: "http://127.0.0.1:3002/tx/\(txid)/status") else {
            print("Invalid URL")
            return nil
        }
        do {
            let data = DataGetPost.get(url: url)
            guard let data = data else {
                print("No data found")
                return nil
            }
            let res: TxStatus? = try JSONDecoder().decode(TxStatus.self, from: data)
            return res
        }
        catch {
            print("Error while decoding Transaction Status: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func getTxRaw(txid: String) -> Data? {
        print("Getting Transaction Raw")
        guard let url = URL(string: "http://127.0.0.1:3002/tx/\(txid)/raw") else {
            print("Invalid URL")
            return nil
        }
        let data = DataGetPost.get(url: url)
        return data
    }
    
    public static func outSpend(txid: String, index: UInt16) -> OutSpent? {
        print("Getting OutSpend")
        guard let url = URL(string: "http://127.0.0.1:3002/tx/\(txid)/outspend/\(index)") else {
            print("Invalid URL")
            return nil
        }
        do {
            let data = DataGetPost.get(url: url)
            guard let data = data else {
                print("No data found")
                return nil
            }
            let res: OutSpent? = try JSONDecoder().decode(OutSpent.self, from: data)
            return res
        }
        catch {
            print("Error while decoding OutSpend: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func getTipHeight() -> Int32? {
        print("Getting Tip Height")
        guard let url = URL(string: "http://127.0.0.1:3002/blocks/tip/height") else {
            print("Invalid URL")
            return nil
        }
        let data = DataGetPost.get(url: url)
        guard let data = data else {
            print("No data found")
            return nil
        }
        let text = String(decoding: data, as: UTF8.self)
        let res = Int32(text)
        return res
    }
    
    static func getTipHash() -> String? {
        print("Getting Tip Hash")
        guard let url = URL(string: "http://127.0.0.1:3002/blocks/tip/hash") else {
            print("Invalid URL")
            return nil
        }
        let data = DataGetPost.get(url: url)
        guard let data = data else {
            print("No data found")
            return nil
        }
        let res = String(decoding: data, as: UTF8.self)
        return res
    }
}
