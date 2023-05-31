//
//  LDKManager.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit
import BitcoinDevKit
import Combine

public class LDKManager: ObservableObject {
    // logger for ldk
    var logger: MyLogger!
    
    // filter for transactions
    var filter: MyFilter? = nil
    
    // graph of routes
    var router: NetworkGraph? = nil
    
    // scores routes
    var scorer: MultiThreadedLockableScore? = nil
    
    // manages keys for signing
    var keysManager: KeysManager? = nil
    
    // monitors the block chain
    var chainMonitor: ChainMonitor? = nil
    
    // constructor for creating the channel manager.
    var channelManagerConstructor: ChannelManagerConstructor? = nil
    
    // the channel manager
    var channelManager: LightningDevKit.ChannelManager? = nil
    
    // persister for the channel manager
    var channelManagerPersister: MyChannelManagerPersister? = nil
    
    // manages the peer that node is connected to
    var peerManager: LightningDevKit.PeerManager? = nil
    
    // handle peer communications
    var peerHandler: TCPPeerHandler? = nil
    
    // port number for lightning
    let port = UInt16(9735)
    
    // which currency will be setup?  Testnet or Regtest?
    let currency: Bindings.Currency

    // Bitcoin network, or the Testnet network
    let network: Bindings.Network
    
    @Published var bdkManager: BDKManager {
        didSet {
            subscribeToInnerObject()
        }
    }
    
    private var innerObjectSubscription: AnyCancellable?
    
    private func subscribeToInnerObject() {
        // subscribe to the inner object and propagate the objectWillChange notification if it changes
        innerObjectSubscription = bdkManager.objectWillChange.sink(receiveValue: objectWillChange.send)
    }
    
    
    public init(net: Bindings.Network) {
        print("LDK Setup Started")
        
        if net == .Regtest {
            network = Bindings.Network.Regtest
            currency = Bindings.Currency.Regtest
            self.bdkManager = BDKManager(net: .regtest)
        } else {
            network = Bindings.Network.Testnet
            currency = Bindings.Currency.BitcoinTestnet
            self.bdkManager = BDKManager(net: .testnet)
        }
        do {
            let keyData = try getKeyData()
            let descriptor = try Descriptor(descriptor: keyData.descriptor, network: bdkManager.network)
            bdkManager.loadWallet(descriptor: descriptor, changeDescriptor: nil)
        } catch let error {
            debugPrint(error)
        }
        bdkManager.sync()
        let feeEstimator = MyFeeEstimator()

        logger = MyLogger()
        let broadcaster = MyBroacaster()
        let persister = MyPersister()
        filter = MyFilter()

        chainMonitor = ChainMonitor(chainSource: filter, broadcaster: broadcaster, logger: logger, feeest: feeEstimator, persister: persister)

        let seed = bdkManager.getPrivKey()
        let timestampSeconds = UInt64(NSDate().timeIntervalSince1970)
        let timestampNanos = UInt32.init(truncating: NSNumber(value: timestampSeconds * 1000 * 1000))

        keysManager = KeysManager(seed: seed, startingTimeSecs: timestampSeconds, startingTimeNanos: timestampNanos)

        let userConfig = UserConfig.initWithDefault()
        let newChannelConfig = ChannelConfig.initWithDefault()
        newChannelConfig.setForwardingFeeProportionalMillionths(val: 10000)
        newChannelConfig.setForwardingFeeBaseMsat(val: 1000)
        userConfig.setChannelConfig(val: newChannelConfig)

        let channelHandshakeConfig = ChannelHandshakeConfig.initWithDefault()
        channelHandshakeConfig.setMinimumDepth(val: 1)
        channelHandshakeConfig.setAnnouncedChannel(val: false)
        userConfig.setChannelHandshakeConfig(val: channelHandshakeConfig)

        var netGraph: NetworkGraph
        if FileHandler.fileExists(path: "network_graph") {
            do {
                let file = try FileHandler.readData(path: "network_graph")
                let readResult = NetworkGraph.read(ser: [UInt8](file), arg: logger)

                if readResult.isOk() {
                    netGraph = readResult.getValue()!
                    print("Network Graph loaded")
                } else {
                    print("Failed to load Network Graph loaded, creating new one")
                    print(String(describing: readResult.getError()))
                    netGraph = NetworkGraph(network: self.network, logger: logger)
                }
            } catch {
                print("Error reading Network Graph Data")
                netGraph = NetworkGraph(network: self.network, logger: logger)
            }
        } else {
            netGraph = NetworkGraph(network: self.network, logger: logger)
            print("New Network Graph Created")
        }

        if FileHandler.fileExists(path: "probabilistic_scorer") {
            do {
                let file = try FileHandler.readData(path: "probabilistic_scorer")

                let scoringParams = ProbabilisticScoringParameters.initWithDefault()
                let scorerReadResult = ProbabilisticScorer.read(ser: [UInt8](file), argA: scoringParams, argB: netGraph, argC: logger)

                guard let readResult = scorerReadResult.getValue() else {
                    throw LightningError.probabilisticScorer(msg: "failed to load probabilsticScorer")
                }

                let probabilisticScorer = readResult
                let score = probabilisticScorer.asScore()
                self.scorer = MultiThreadedLockableScore(score: score)
                print("Probabilistic Scorer loaded and running")
            } catch {
                print("Error loading Probabilistic Scorer")
                let params = ProbabilisticScoringParameters.initWithDefault()
                let probabilisticScorer = ProbabilisticScorer(params: params, networkGraph: netGraph, logger: logger)
                let score = probabilisticScorer.asScore()
                self.scorer = MultiThreadedLockableScore(score: score)
                print("Creating new Probabilistic Scorer")
            }
        }
        else {
            let params = ProbabilisticScoringParameters.initWithDefault()
            let probabilisticScorer = ProbabilisticScorer(params: params, networkGraph: netGraph, logger: logger)
            let score = probabilisticScorer.asScore()
            self.scorer = MultiThreadedLockableScore(score: score)
            print("Probabilistic Scorer loaded and running")
        }

        var serializedChannelManager: [UInt8] = [UInt8]()
        if FileHandler.fileExists(path: "channel_manager") {
            do {
                let channelManagerData = try FileHandler.readData(path: "channel_manager")
                serializedChannelManager = [UInt8](channelManagerData)
                print("Serialized Channel Manager Loaded")
            } catch {
                print("Failed to load Serialized Channel Manager")
            }
        } else {
            print("Serialized Channel Manager not Available")
        }

        var serializedChannelMonitors: [[UInt8]] = [[UInt8]]()
        if FileHandler.fileExists(path: "channels") {
            do {
                let urls = try FileHandler.contentsOfDirectory(atPath: "channels")
                for url in urls {
                    let channelData = try FileHandler.readData(url: url)
                    let channelBytes = [UInt8](channelData)
                    serializedChannelMonitors.append(channelBytes)
                }
                print("Serialized Channel Monitors Loaded")
            } catch {
                print("Failed to load Serialized Channel Monitors")
            }
        } else {
            print("Serialized Channel Monitors not Available")
        }

        let channelManagerConstructionParameters = ChannelManagerConstructionParameters(config: userConfig, entropySource: keysManager!.asEntropySource(), nodeSigner: keysManager!.asNodeSigner(), signerProvider: keysManager!.asSignerProvider(), feeEstimator: feeEstimator, chainMonitor: chainMonitor!, txBroadcaster: broadcaster, logger: logger, enableP2PGossip: true, scorer: scorer)


        let latestBlockHash = Utils.hexStringToByteArray(bdkManager.getBlockHash()!)
        let latestBlockHeight = bdkManager.getBlockHeight()!
        print("Latest Block Hash: \(latestBlockHash)")
        print("Latest Block Hash: \(latestBlockHeight)")
        
        if !serializedChannelManager.isEmpty {
            do {
                self.channelManagerConstructor = try ChannelManagerConstructor(channelManagerSerialized: serializedChannelManager, channelMonitorsSerialized: serializedChannelMonitors, networkGraph: NetworkGraphArgument.instance(netGraph), filter: filter, params: channelManagerConstructionParameters)
                print("Channel Manager Constructor Loaded")
            } catch {
                print("Failed to load Channel Manager Constructor, creating new one")
                self.channelManagerConstructor = ChannelManagerConstructor(network: network, currentBlockchainTipHash: latestBlockHash, currentBlockchainTipHeight: latestBlockHeight, netGraph: netGraph, params: channelManagerConstructionParameters)
                print("New Channel Manager Constructor Created")
            }
        } else {
            self.channelManagerConstructor = ChannelManagerConstructor(network: network, currentBlockchainTipHash: latestBlockHash, currentBlockchainTipHeight: latestBlockHeight, netGraph: netGraph, params: channelManagerConstructionParameters)
            print("New Channel Manager Constructor Created")
        }
        self.channelManager = channelManagerConstructor?.channelManager
        self.peerManager = channelManagerConstructor?.peerManager
        self.peerHandler = channelManagerConstructor?.getTCPPeerHandler()
        self.router = channelManagerConstructor?.netGraph
        self.channelManagerPersister = MyChannelManagerPersister()
        channelManagerPersister?.ldkManager = self
        broadcaster.ldkManager = self
        subscribeToInnerObject()
        self.sync()
//
        print("LDK Setup Finished")
    }
    
    func sync() {
        bdkManager.sync()
        
        let relevantTxIds1 = channelManager?.asConfirm().getRelevantTxids()
        let relevantTxIds2 = chainMonitor?.asConfirm().getRelevantTxids()
        guard let relevantTxIds1 = relevantTxIds1, let relevantTxIds2 = relevantTxIds2 else {
            print("RelevantTxIds1 and RelevantTxIds2 are nil")
            return
        }
        var relevantTxIds: [[UInt8]] = [[UInt8]]()
        for tx in relevantTxIds1 {
            relevantTxIds.append(tx.0)
        }
        for tx in relevantTxIds2 {
            relevantTxIds.append(tx.0)
        }
        
        var confirmedTxs: [ConfirmedTx] = []
        
        // Sync unconfirmed Transactions
        for txId in relevantTxIds {
            let txId = Utils.bytesToHex(bytes: txId)
            let tx = BlockchainData.getTx(txid: txId, network: network)
            if let tx = tx {
                if tx.status.confirmed {
                    let txHex = BlockchainData.getTxHex(txid: txId, network: network)!
                    let blockHeader = BlockchainData.getBlockHeader(hash: tx.status.block_hash, network: network)
                    let merkleProof = BlockchainData.getMerkleProof(txid: txId, network: network)!
                    if tx.status.block_height == merkleProof.block_height {
                        let newConfirmedTx = ConfirmedTx(tx: Utils.hexStringToByteArray(txHex), block_height: tx.status.block_height, block_header: blockHeader!, merkle_proof_pos: merkleProof.pos)
                        confirmedTxs.append(newConfirmedTx)
                    }
                } else {
                    channelManager?.asConfirm().transactionUnconfirmed(txid: Utils.hexStringToByteArray(txId))
                    chainMonitor?.asConfirm().transactionUnconfirmed(txid: Utils.hexStringToByteArray(txId))
                }
            }
        }
        
        // Add confirmed Tx from filter Transaction Id
        if let filteredTxIds = filter?.txIds {
            for txId in filteredTxIds {
                let txIdHex = Utils.bytesToHex32Reversed(bytes: Utils.array_to_tuple32(array: txId))
                let tx = BlockchainData.getTx(txid: txIdHex, network: network)
                if let tx = tx, tx.status.confirmed {
                    let txHex = BlockchainData.getTxHex(txid: txIdHex, network: network)!
                    let blockHeader = BlockchainData.getBlockHeader(hash: tx.status.block_hash, network: network)!
                    let merkleProof = BlockchainData.getMerkleProof(txid: txIdHex, network: network)!
                    if tx.status.block_height == merkleProof.block_height {
                        let newConfirmedTx = ConfirmedTx(tx: Utils.hexStringToByteArray(txHex), block_height: tx.status.block_height, block_header: blockHeader, merkle_proof_pos: merkleProof.pos)
                        confirmedTxs.append(newConfirmedTx)
                    }
                }
            }
        }
        
        // Add confirmed Tx from filter Transaction Output
        if let filteredOutputs = filter?.outputs {
            for output in filteredOutputs {
                let outpoint = output.getOutpoint()
                let txId = outpoint.getTxid()
                let txIdHex = Utils.bytesToHex32Reversed(bytes: Utils.array_to_tuple32(array: txId!))
                let outputIdx = outpoint.getIndex()
                
                if let res = BlockchainData.outSpend(txid: txIdHex, index: outputIdx, network: network) {
                    if res.spent {
                        let tx = BlockchainData.getTx(txid: res.txid!, network: network)
                        if let tx = tx, tx.status.confirmed {
                            let txHex = BlockchainData.getTxHex(txid: txIdHex, network: network)!
                            let blockHeader = BlockchainData.getBlockHeader(hash: tx.status.block_hash, network: network)!
                            let merkleProof = BlockchainData.getMerkleProof(txid: txIdHex, network: network)!
                            if tx.status.block_height == merkleProof.block_height {
                                let newConfirmedTx = ConfirmedTx(tx: Utils.hexStringToByteArray(txHex), block_height: tx.status.block_height, block_header: blockHeader, merkle_proof_pos: merkleProof.pos)
                                confirmedTxs.append(newConfirmedTx)
                            }
                        }
                    }
                }
                
            }
        }
        
        // Understand why we are doing this as without this also the channel is getting open and is usable
        confirmedTxs.sort { (tx1, tx2) -> Bool in
            if tx1.block_height != tx2.block_height {
                return tx1.block_height < tx2.block_height
            } else {
                return tx1.merkle_proof_pos < tx2.merkle_proof_pos
            }
        }
        // <--
        
        // Sync Confirmed Transactions
        for cTx in confirmedTxs {
            var twoTuple: [(UInt, [UInt8])] = []
            let x: (UInt, [UInt8]) = (UInt, [UInt8])(cTx.merkle_proof_pos.magnitude, cTx.tx)
            twoTuple.append(x)

            channelManager?.asConfirm().transactionsConfirmed(header: Utils.hexStringToByteArray(cTx.block_header), txdata: twoTuple, height: UInt32(cTx.block_height))

            chainMonitor?.asConfirm().transactionsConfirmed(header: Utils.hexStringToByteArray(cTx.block_header), txdata: twoTuple, height: UInt32(cTx.block_height))
        }
        
        // Sync Best Blocks
        syncBestBlockConnected()
        
        channelManagerConstructor!.chainSyncCompleted(persister: channelManagerPersister!)
        
    }

    func syncBestBlockConnected() {
        let height = BlockchainData.getTipHeight(network: network)
        let hash = BlockchainData.getTipHash(network: network)
        let header = BlockchainData.getBlockHeader(hash: hash!, network: network)
        
        channelManager?.asConfirm().bestBlockUpdated(header: Utils.hexStringToByteArray(header!), height: UInt32(height!))
        chainMonitor?.asConfirm().bestBlockUpdated(header: Utils.hexStringToByteArray(header!), height: UInt32(height!))

        print("Synced Best Block Connected Successfully")
    }

    func getNodeId() -> String {
        guard let channelManager = channelManager else {
            return "failed to get nodeID"
        }
        let nodeId = channelManager.getOurNodeId()
        let res = Utils.bytesToHex(bytes: nodeId)
        return res
    }

    func connect(nodeId: String, address: String, port: NSNumber) throws -> Bool {
        guard let peerHandler = peerHandler else {
            throw LightningError.peerManager(msg: "peerHandler not working")
        }
        
        let res = peerHandler.connect(address: address,
                                       port: UInt16(truncating: port),
                                       theirNodeId: Utils.hexStringToByteArray(nodeId))
        
        if (!res) {
            throw LightningError.connectPeer(msg: "failed to connect to peer")
        }
        
        return res
    }
    
    func listPeers() -> [String] {
        guard let peerManager = peerManager else {
            print("PeerManager was not available for listPeers")
            return []
        }
        let peerNodeIds = peerManager.getPeerNodeIds()
        var res = [String]()
        for it in peerNodeIds {
            let nodeId = Utils.bytesToHex(bytes: it.0)
            let address = Utils.bytesToIpAddress(bytes: it.1!.getValueAsIPv4()!.getAddr())
            let port = it.1!.getValueAsIPv4()!.getPort()
            res.append("\(nodeId)@\(address):\(port)")
        }
        return res
    }
    
    func listChannelsDict() -> [[String:Any]] {
        guard let channelManager = channelManager else {
            print("Channel Manager not initialized")
            return []
        }

        let channels = channelManager.listChannels().isEmpty ? [] : channelManager.listChannels()
        var channelsDict = [[String:Any]]()
        _ = channels.map { (it: ChannelDetails) in
            let channelDict = self.channel2ChannelDictionary(it: it)
            channelsDict.append(channelDict)
        }

        return channelsDict
    }
    
    func listUsableChannelsDict() -> [[String:Any]] {
        guard let channelManager = channelManager else {
            print("Channel Manager not initialized")
            return []
        }

        let channels = channelManager.listUsableChannels().isEmpty ? [] : channelManager.listChannels()
        var channelsDict = [[String:Any]]()
        _ = channels.map { (it: ChannelDetails) in
            let channelDict = self.channel2ChannelDictionary(it: it)
            channelsDict.append(channelDict)
        }

        return channelsDict
    }
    
    
    
    /// Convert ChannelDetails to a string
    func channel2ChannelDictionary(it: ChannelDetails) -> [String:Any] {
        
        var channelsDict = [String: Any]()
        
//        channelsDict["short_channel_id"] = it.getShortChannelId() ?? 0;
        channelsDict["confirmations_required"] = it.getConfirmationsRequired() ?? 0;
//        channelsDict["force_close_spend_delay"] = it.getForceCloseSpendDelay() ?? 0;
//        channelsDict["unspendable_punishment_reserve"] = it.getUnspendablePunishmentReserve() ?? 0;
        
        channelsDict["channel_id"] = Utils.bytesToHex(bytes: it.getChannelId()!)
        channelsDict["channel_value_satoshis"] = String(it.getChannelValueSatoshis())
        channelsDict["inbound_capacity_msat"] = String(it.getInboundCapacityMsat())
        channelsDict["outbound_capacity_msat"] = String(it.getOutboundCapacityMsat())
        channelsDict["next_outbound_htlc_limit"] = String(it.getNextOutboundHtlcLimitMsat())
        
        channelsDict["is_usable"] = it.getIsUsable() ? "true" : "false"
        channelsDict["is_channel_ready"] = it.getIsChannelReady() ? "true" : "false"
//        channelsDict["is_outbound"] = it.getIsOutbound() ? "true" : "false"
        channelsDict["is_public"] = it.getIsPublic() ? "true" : "false"
        channelsDict["remote_node_id"] = Utils.bytesToHex(bytes: it.getCounterparty().getNodeId())

        if let funding_txo = it.getFundingTxo() {
            //channelsDict["funding_txo_txid"] = Utils.bytesToHex(bytes: funding_txo.getTxid()!)
            channelsDict["funding_txo_txid"] =  Utils.bytesToHex32Reversed(bytes: Utils.array_to_tuple32(array: funding_txo.getTxid()!))
            
            channelsDict["funding_txo_index"] = String(funding_txo.getIndex())
        }
        return channelsDict
    }
    
    
    func openChannel(nodeId: String, amount: UInt64, pushMsat: UInt64) -> Bool {
        let uid = UUID().uuid
        let channelId = Utils.bytesToHex16(bytes: uid)
        
        let userConfig = UserConfig.initWithDefault()
        let channelConfig = ChannelHandshakeConfig.initWithDefault()
        channelConfig.setAnnouncedChannel(val: false)
        userConfig.setChannelHandshakeConfig(val: channelConfig)
        let createChannelResults = channelManager?.createChannel(theirNetworkKey: Utils.hexStringToByteArray(nodeId), channelValueSatoshis: amount, pushMsat: pushMsat, userChannelId: channelId, overrideConfig: userConfig)
        if createChannelResults == nil {
            return false
        }
        print(createChannelResults?.getError()?.getValueAsApiMisuseError()?.getErr())
        return createChannelResults!.isOk()
    }
    
    func sendPayment(invoice: String) -> Bool {
        let invoiceResult = Invoice.fromStr(s: invoice)
        guard let invoice = invoiceResult.getValue(), let channelManager = self.channelManager else {
            print("Could not parse invoice")
            return false
        }

        let invoicePaymentResult = Bindings.payInvoice(invoice: invoice, retryStrategy: Bindings.Retry.initWithTimeout(a: 15), channelmanager: channelManager)

        if invoicePaymentResult.isOk() {
            return true
        }
        return false
    }
    
    func generateInvoice(amount: UInt64, expiry: UInt32) -> String? {
        let invoice = Bindings.createInvoiceFromChannelmanager(channelmanager: channelManager!, nodeSigner: keysManager!.asNodeSigner(), logger: logger, network: currency, amtMsat: amount, description: "Test Invoice", invoiceExpiryDeltaSecs: expiry, minFinalCltvExpiryDelta: nil)
        if invoice.isOk() {
            return invoice.getValue()!.toStr()
        }
        print("Could not create Invoice")
        return nil
    }
    
    func closeChannel(channelId: [UInt8], counterpartyNodeId: [UInt8]) -> Bool {
        let res = channelManager?.closeChannel(channelId: channelId, counterpartyNodeId: counterpartyNodeId)
        return res!.isOk()
    }
}

public enum LightningError: Error {
    case peerManager(msg:String)
    case networkGraph(msg:String)
    case parseInvoice(msg:String)
    case channelManager(msg:String)
    case nodeId(msg:String)
    case bindNode(msg:String)
    case connectPeer(msg:String)
    case Invoice(msg:String)
    case payInvoice(msg:String)
    case chainMonitor(msg:String)
    case probabilisticScorer(msg:String)
}

public struct PayInvoiceResult {
    public let bolt11:String
    public let memo:String
    public let amt:UInt64
}
