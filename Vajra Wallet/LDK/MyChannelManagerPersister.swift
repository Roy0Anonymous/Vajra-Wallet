//
//  MyChannelManagerPersister.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import Foundation
import LightningDevKit
import BitcoinDevKit

class MyChannelManagerPersister: Persister, ExtendedChannelManagerPersister {
    weak var ldkManager: LDKManager? = nil
    func handleEvent(event: Event) {
        if let event = event.getValueAsSpendableOutputs() {
            print("handleEvent: trying to spend output")
            let outputs = event.getOutputs()
            do {
                let address = ldkManager!.bdkManager.getAddress(addressIndex: .new)!
                let script = try Address(address: address).scriptPubkey().toBytes()
                let res = ldkManager!.myKeysManager.spendSpendableOutputs(
                    descriptors: outputs,
                    outputs: [],
                    changeDestinationScript: script,
                    feerateSatPer1000Weight: 1000,
                    locktime: nil)
                if res.isOk() {
                    var txs: [[UInt8]] = []
                    txs.append(res.getValue()!)
                    ldkManager!.broadcaster.broadcastTransactions(txs: txs)
                }
            } catch {
                print(error.localizedDescription)
            }
            
        }
        else if let paymentSentEvent = event.getValueAsPaymentSent() {
            print("handleEvent: Payment Sent \(paymentSentEvent)")
        }
        else if let paymentFailedEvent = event.getValueAsPaymentFailed() {
            print("handleEvent: Payment Failed \(paymentFailedEvent)")
        }
        else if let paymentPathFailedEvent = event.getValueAsPaymentPathFailed() {
            print("handleEvent: Payment Path Failed \(paymentPathFailedEvent)")
        }
        else if let _ = event.getValueAsPendingHtlcsForwardable() {
            print("handleEvent: forward HTLC")
            ldkManager?.channelManager?.processPendingHtlcForwards()
        }
        else if let event = event.getValueAsOpenChannelRequest() {
            let uid = UUID().uuid
            let channelId = Utils.bytesToHex16(bytes: uid)

            let result = ldkManager?.channelManager?.acceptInboundChannel(temporaryChannelId: event.getTemporaryChannelId(), counterpartyNodeId: event.getCounterpartyNodeId(), userChannelId: channelId)
            guard let result = result else {
                print("Error Not Transferred")
                return
            }
            print(result.isOk() ? "Open Channel Accepted" : "Open Channel Failed")
        }

        else if let paymentClaimedEvent = event.getValueAsPaymentClaimable() {
            print("handleEvent: PaymentClaimed")
            let paymentPreimage = paymentClaimedEvent.getPurpose().getValueAsInvoicePayment()?.getPaymentPreimage()
            let _ = ldkManager?.channelManager?.claimFunds(paymentPreimage: paymentPreimage!)
            print("handleEvent: paymentClaimed preimage=\(paymentPreimage!)")
            
        }

        else if let event = event.getValueAsFundingGenerationReady() {
            print("handleEvent: funding generation ready")
            let script = Script(rawOutputScript: event.getOutputScript())
            let channelValue = event.getChannelValueSatoshis()
            let transferred = ldkManager?.bdkManager.fundChannel(script: script, amount: channelValue)
            guard let transferred = transferred else {
                print("Error in Funding Generation Ready")
                return
            }
            let result = ldkManager?.channelManager?.fundingTransactionGenerated(temporaryChannelId: event.getTemporaryChannelId(), counterpartyNodeId: event.getCounterpartyNodeId(), fundingTransaction: transferred.serialize())
            guard let result = result else {
                print("Error Not Transferred")
                return
            }
            print(result.isOk() ? "Transferred Succesfully" : "Transfer Failed")
        }
        else if let _ = event.getValueAsChannelClosed() {
            print("handleEvent: ChannelClosed")
        }
        else if let event = event.getValueAsChannelPending() {
            print("Channel with Channel id \(Utils.bytesToHex(bytes: event.getChannelId())) with peer \(Utils.bytesToHex(bytes: event.getCounterpartyNodeId())) is pending awaiting funding lock-in!")
        }
        else if let event = event.getValueAsChannelReady() {
            print("Channel with Channel id \(Utils.bytesToHex(bytes: event.getChannelId())) with peer \(Utils.bytesToHex(bytes: event.getCounterpartyNodeId())) is ready to be used")
        }
    }

    override func persistManager(channelManager: Bindings.ChannelManager) -> Bindings.Result_NoneErrorZ {
        print("Persisting Channel Manager")
        let channelManagerBytes = channelManager.write()
        let data = Data(channelManagerBytes)
        FileHandler.writeData(data: data, path: "ChannelManager")
        print("persist_manager: saved")
        return Result_NoneErrorZ.initWithOk()
    }
    
    override func persistGraph(networkGraph: NetworkGraph) -> Result_NoneErrorZ {
        print("Persisting Network Graph")
        let networkGraphBytes = networkGraph.write()
        FileHandler.writeData(data: Data(networkGraphBytes), path: "NetworkGraph")
        print("persist_network_graph: saved\n");
        return Result_NoneErrorZ.initWithOk()
    }
    
    override func persistScorer(scorer: WriteableScore) -> Result_NoneErrorZ {
        print("Persisting Scorer")
        let scorerBytes = scorer.write()
        FileHandler.writeData(data: Data(scorerBytes), path: "ProbabilisticScorer")
        print("probabilistic_scorer: save success")
        return Result_NoneErrorZ.initWithOk()
    }
}

