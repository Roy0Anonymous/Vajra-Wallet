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
    let inner: KeysManager
    let wallet: BitcoinDevKit.Wallet
    let signerProvider: MySignerProvider
    
    init(seed: [UInt8], startingTimeSecs: UInt64, startingTimeNanos: UInt32, wallet: BitcoinDevKit.Wallet) {
        self.inner = KeysManager(seed: seed, startingTimeSecs: startingTimeSecs, startingTimeNanos: startingTimeNanos)
        self.wallet = wallet
        signerProvider = MySignerProvider()
        signerProvider.myKeysManager = self
    }

    // We drop all occurences of `SpendableOutputDescriptor::StaticOutput` (since they will be
    // spendable by the BDK wallet) and forward any other descriptors to
    // `KeysManager::spend_spendable_outputs`.
    //
    // Note you should set `locktime` to the current block height to mitigate fee sniping.
    // See https://bitcoinops.org/en/topics/fee-sniping/ for more information.
    func spendSpendableOutputs(descriptors: [SpendableOutputDescriptor], outputs: [Bindings.TxOut],
                               changeDestinationScript: [UInt8], feerateSatPer1000Weight: UInt32,
                               locktime: UInt32?) -> Result_TransactionNoneZ {
        let onlyNonStatic: [SpendableOutputDescriptor] = descriptors.filter { desc in
            if desc.getValueType() == .StaticOutput {
                return false
            }
            return true
        }
        let res = self.inner.spendSpendableOutputs(
            descriptors: onlyNonStatic,
            outputs: outputs,
            changeDestinationScript: changeDestinationScript,
            feerateSatPer1000Weight: feerateSatPer1000Weight,
            locktime: locktime
        )
        return res
    }
}

class MySignerProvider: SignerProvider {
    weak var myKeysManager: MyKeysManager?
    
    // We return the destination and shutdown scripts derived by the BDK wallet.
    override func getDestinationScript(channelKeysId: [UInt8]) -> Bindings.Result_CVec_u8ZNoneZ {
        return Bindings.Result_CVec_u8ZNoneZ.initWithOk(o: channelKeysId)
    }
    
    override func getShutdownScriptpubkey() -> Bindings.Result_ShutdownScriptNoneZ {
        do {
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
                let res = ShutdownScript.newWitnessProgram(witnessProgram: .init(version: ver, program: program))
                if res.isOk() {
                    return Bindings.Result_ShutdownScriptNoneZ.initWithOk(o: res.getValue()!)
                }
            }
            return .initWithErr()
        } catch {
            return .initWithErr()
        }
    }
    
    // ... and redirect all other trait method implementations to the `inner` `KeysManager`.
    override func deriveChannelSigner(channelValueSatoshis: UInt64, channelKeysId: [UInt8]) -> Bindings.WriteableEcdsaChannelSigner {
        return myKeysManager!.inner.asSignerProvider().deriveChannelSigner(
            channelValueSatoshis: channelValueSatoshis,
            channelKeysId: channelKeysId
        )
    }
    
    override func generateChannelKeysId(inbound: Bool, channelValueSatoshis: UInt64, userChannelId: [UInt8]) -> [UInt8] {
        return myKeysManager!.inner.asSignerProvider().generateChannelKeysId(
            inbound: inbound,
            channelValueSatoshis: channelValueSatoshis,
            userChannelId: userChannelId
        )
    }
    
    override func readChanSigner(reader: [UInt8]) -> Bindings.Result_WriteableEcdsaChannelSignerDecodeErrorZ {
        return myKeysManager!.inner.asSignerProvider().readChanSigner(reader: reader)
    }
}
