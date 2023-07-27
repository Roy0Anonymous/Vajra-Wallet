//
//  MyKeysManager.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 28/07/23.
//

import Foundation
import LightningDevKit
import BitcoinDevKit

class MyKeysManager {
    let keysManager: KeysManager
    let nodeSigner: MyNodeSigner
    let entropySource: MyEntropySource
    let signerProvider: MySignerProvider
    
    let wallet: Wallet
    init(seed: [UInt8], startingTimeSecs: UInt64, startingTimeNanos: UInt32, wallet: Wallet) {
        self.keysManager = KeysManager(seed: seed, startingTimeSecs: startingTimeSecs, startingTimeNanos: startingTimeNanos)
        self.wallet = wallet
        nodeSigner = MyNodeSigner()
        entropySource = MyEntropySource()
        signerProvider = MySignerProvider()
        nodeSigner.myKeysManager = self
        entropySource.myKeysManager = self
        signerProvider.myKeysManager = self
    }
}

class MyNodeSigner: NodeSigner {
    var myKeysManager: MyKeysManager?
    override func ecdh(recipient: Bindings.Recipient, otherKey: [UInt8], tweak: [UInt8]?) -> Bindings.Result_SharedSecretNoneZ {
        print("Getting ecdh")
        return myKeysManager!.keysManager.asNodeSigner().ecdh(recipient: recipient, otherKey: otherKey, tweak: tweak)
    }
    
    override func getNodeId(recipient: Bindings.Recipient) -> Bindings.Result_PublicKeyNoneZ {
        print("Getting getNodeId")
//        print(Utils.bytesToHex(bytes: myKeysManager!.keysManager.getNodeSecretKey()))
        return myKeysManager!.keysManager.asNodeSigner().getNodeId(recipient: recipient)
    }
    
    override func getInboundPaymentKeyMaterial() -> [UInt8] {
        print("Getting getInboundPaymentKeyMaterial")
        return myKeysManager!.keysManager.asNodeSigner().getInboundPaymentKeyMaterial()
    }
    
    override func signGossipMessage(msg: Bindings.UnsignedGossipMessage) -> Bindings.Result_SignatureNoneZ {
        print("Getting signGossipMessage")
        return myKeysManager!.keysManager.asNodeSigner().signGossipMessage(msg: msg)
    }
    
    override func signInvoice(hrpBytes: [UInt8], invoiceData: [UInt8], recipient: Bindings.Recipient) -> Bindings.Result_RecoverableSignatureNoneZ {
        print("Getting signInvoice")
        return myKeysManager!.keysManager.asNodeSigner().signInvoice(hrpBytes: hrpBytes, invoiceData: invoiceData, recipient: recipient)
    }
}

class MyEntropySource: EntropySource {
    var myKeysManager: MyKeysManager?
    override func getSecureRandomBytes() -> [UInt8] {
        print("Getting getSecureRandomBytes")
        return myKeysManager!.keysManager.asEntropySource().getSecureRandomBytes()
    }
}

class MySignerProvider: SignerProvider {
    var myKeysManager: MyKeysManager?
    override func deriveChannelSigner(channelValueSatoshis: UInt64, channelKeysId: [UInt8]) -> Bindings.WriteableEcdsaChannelSigner {
        print("Getting deriveChannelSigner")
        return myKeysManager!.keysManager.asSignerProvider().deriveChannelSigner(channelValueSatoshis: channelValueSatoshis, channelKeysId: channelKeysId)
    }
    
    override func generateChannelKeysId(inbound: Bool, channelValueSatoshis: UInt64, userChannelId: [UInt8]) -> [UInt8] {
        print("Getting generateChannelKeysId")
        return myKeysManager!.keysManager.asSignerProvider().generateChannelKeysId(inbound: inbound, channelValueSatoshis: channelValueSatoshis, userChannelId: userChannelId)
    }
    
    override func readChanSigner(reader: [UInt8]) -> Bindings.Result_WriteableEcdsaChannelSignerDecodeErrorZ {
        print("Getting readChanSigner")
        return myKeysManager!.keysManager.asSignerProvider().readChanSigner(reader: reader)
    }

    override func getDestinationScript() -> [UInt8] {
        print("Getting getDestinationScript")
        do {
            let address = try myKeysManager!.wallet.getAddress(addressIndex: .new)
            return address.address.scriptPubkey().toBytes()
        } catch {
            print("Failed to get Address")
            return myKeysManager!.keysManager.asSignerProvider().getDestinationScript()
        }
    }

    override func getShutdownScriptpubkey() -> Bindings.ShutdownScript {
        print("Getting getShutdownScriptpubkey")
        do {
            print(Utils.bytesToHex(bytes: myKeysManager!.keysManager.asSignerProvider().getShutdownScriptpubkey().intoInner()))
            let address = try myKeysManager!.wallet.getAddress(addressIndex: .new).address
            let payload = address.payload()
            if case let .witnessProgram(`version`, `program`) = payload {
                let ver: UInt8
                switch version {
                case .v0:
                    ver = 0
                case .v1:
                    ver = 1
                case .v2:
                    ver = 2
                case .v3:
                    ver = 3
                case .v4:
                    ver = 4
                case .v5:
                    ver = 5
                case .v6:
                    ver = 6
                case .v7:
                    ver = 7
                case .v8:
                    ver = 8
                case .v9:
                    ver = 9
                case .v10:
                    ver = 10
                case .v11:
                    ver = 11
                case .v12:
                    ver = 12
                case .v13:
                    ver = 13
                case .v14:
                    ver = 14
                case .v15:
                    ver = 15
                case .v16:
                    ver = 16
                }
                print("Payload \(program) Version \(ver)")
                let res = ShutdownScript.newWitnessProgram(version: ver, program: program)
                if res.isOk() {
                    print("Res okay")
                    print(Utils.bytesToHex(bytes: res.getValue()!.intoInner()))
                    return res.getValue()!
                }
            }
            return myKeysManager!.keysManager.asSignerProvider().getShutdownScriptpubkey()
        } catch {
            print("Failed to get Address")
            return myKeysManager!.keysManager.asSignerProvider().getShutdownScriptpubkey()
        }
    }
}


//override func getDestinationScript() -> [UInt8] {
//    print("Getting getDestinationScript")
//    return myKeysManager!.keysManager.asSignerProvider().getDestinationScript()
//}
//
//override func getShutdownScriptpubkey() -> Bindings.ShutdownScript {
//    print("Getting getShutdownScriptpubkey")
//    return myKeysManager!.keysManager.asSignerProvider().getShutdownScriptpubkey()
//}
