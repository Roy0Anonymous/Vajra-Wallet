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
    var ldkManager: LDKManager? = nil
    func handleEvent(event: Event) {
        if let _ = event.getValueAsSpendableOutputs() {
            print("handleEvent: trying to spend output")
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
        // payment was claimed, so return preimage
        else if let paymentClaimedEvent = event.getValueAsPaymentClaimable() {
            let paymentPreimage = paymentClaimedEvent.getPurpose().getValueAsInvoicePayment()?.getPaymentPreimage()
            let _ = ldkManager?.channelManager?.claimFunds(paymentPreimage: paymentPreimage!)
            print("handleEvent: paymentClaimed preimage=\(paymentPreimage!)")
            
        }
        // channel is ready to be funded
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
        else if event.getValueAsPaymentForwarded() != nil {
            // we don't route as we are a light mobile node
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
        let channel_manager_bytes = channelManager.write()
        do {
            let data = Data(channel_manager_bytes)
            try FileHandler.writeData(data: data, path: "channel_manager")
            print("persist_manager: saved")
        }
        catch {
            NSLog("persist_manager: there was a problem persisting the channel \(error)")
        }
        return Result_NoneErrorZ.initWithOk()
    }
    
    override func persistGraph(networkGraph: NetworkGraph) -> Result_NoneErrorZ {
        do {
            let network_graph_bytes = networkGraph.write()
            try FileHandler.writeData(data: Data(network_graph_bytes), path: "network_graph")
            print("persist_network_graph: saved\n");
        }
        catch {
            NSLog("persist_network_graph: error \(error)");
        }
        return Result_NoneErrorZ.initWithOk()
    }
    
    override func persistScorer(scorer: WriteableScore) -> Result_NoneErrorZ {
        do {
            let scorerBytes = scorer.write()
            try FileHandler.writeData(data: Data(scorerBytes), path: "probabilistic_scorer")
            print("probabilistic_scorer: save success")
        }
        catch {
            NSLog("persistScorer: Error \(error)");
            
        }
        return Result_NoneErrorZ.initWithOk()
    }
}

