//
//  LDKManager.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit
import BitcoinDevKit
import Combine
import os

public class LDKManager: ObservableObject {
    static let activityLogger = Logger(subsystem: "com.Roy0Anonymous.Vajra-Wallet", category: "LDKLogger")
    private var logger: MyLogger!
    private var filter: MyFilter!
    private var netGraph: NetworkGraph!
    private var scorer: MultiThreadedLockableScore!
    private var chainMonitor: ChainMonitor!
    private var channelManagerConstructor: ChannelManagerConstructor!
    private var channelManagerPersister: MyChannelManagerPersister!
    private var peerManager: LightningDevKit.PeerManager!
    private var peerHandler: TCPPeerHandler!
    private let currency: Bindings.Currency
    static let ldkQueue = DispatchQueue(label: "ldkQueue", qos: .userInitiated)
    private var innerObjectSubscription: AnyCancellable?
    private func subscribeToInnerObject() {
        innerObjectSubscription = bdkManager.objectWillChange.sink(receiveValue: objectWillChange.send)
    }
    
    @Published var bdkManager: BDKManager {
        didSet {
            subscribeToInnerObject()
        }
    }
    var broadcaster: MyBroacaster!
//    var keysManager: KeysManager!
    var myKeysManager: MyKeysManager!
    var channelManager: LightningDevKit.ChannelManager!
    let network: Bindings.Network
    
    init(network: Bindings.Network) {
        if network == .Regtest {
            self.network = Bindings.Network.Regtest
            self.currency = Bindings.Currency.Regtest
            self.bdkManager = BDKManager(network: .regtest)
        } else {
            self.network = Bindings.Network.Testnet
            self.currency = Bindings.Currency.BitcoinTestnet
            self.bdkManager = BDKManager(network: .testnet)
        }
        subscribeToInnerObject()
    }
    
    func start() throws {
        LDKManager.activityLogger.info("LDK Setup Started")
        let feeEstimator = MyFeeEstimator()
        self.logger = MyLogger()
        self.broadcaster = MyBroacaster()
        let persister = MyPersister()
        self.filter = MyFilter()
        
        self.chainMonitor = ChainMonitor(chainSource: filter, broadcaster: broadcaster, logger: logger, feeest: feeEstimator, persister: persister)
        
        let seed = bdkManager.getPrivKey()
        let timestampSeconds = UInt64(NSDate().timeIntervalSince1970)
        let timestampNanos = UInt32.init(truncating: NSNumber(value: timestampSeconds * 1000 * 1000))
//        self.keysManager = KeysManager(seed: seed, startingTimeSecs: timestampSeconds, startingTimeNanos: timestampNanos)
        self.myKeysManager = MyKeysManager(seed: seed, startingTimeSecs: timestampSeconds, startingTimeNanos: timestampNanos, wallet: bdkManager.wallet!)
        
        let handshakeConfig = ChannelHandshakeConfig.initWithDefault()
        handshakeConfig.setMinimumDepth(val: 1)
        handshakeConfig.setAnnouncedChannel(val: false)
        
        let handshakeLimits = ChannelHandshakeLimits.initWithDefault()
        handshakeLimits.setForceAnnouncedChannelPreference(val: false)
        
        let userConfig = UserConfig.initWithDefault()
        userConfig.setChannelHandshakeConfig(val: handshakeConfig)
        userConfig.setChannelHandshakeLimits(val: handshakeLimits)
        userConfig.setAcceptInboundChannels(val: true)
        
        if FileHandler.fileExists(path: "NetworkGraph") {
            let file = FileHandler.readData(path: "NetworkGraph")
            let readResult = NetworkGraph.read(ser: [UInt8](file!), arg: logger)
            if readResult.isOk() {
                self.netGraph = readResult.getValue()!
                print("Network Graph loaded")
            } else {
                print("Failed to load Network Graph loaded, creating new one")
                print(String(describing: readResult.getError()))
                self.netGraph = NetworkGraph(network: self.network, logger: logger)
            }
        } else {
            self.netGraph = NetworkGraph(network: self.network, logger: logger)
            print("New Network Graph Created")
        }
        
        if network != .Regtest {
            let rgs = RapidGossipSync(networkGraph: netGraph, logger: logger)
            if let lastSync = netGraph.getLastRapidGossipSyncTimestamp(), let snapshot = getSnapshot(lastSyncTimeStamp: lastSync) {
                let timestampSeconds = UInt64(NSDate().timeIntervalSince1970)
                let res = rgs.updateNetworkGraphNoStd(updateData: snapshot, currentTimeUnix: timestampSeconds)
                if res.isOk() {
                    print("RGS updated")
                }
            } else if let snapshot = getSnapshot(lastSyncTimeStamp: 0) {
                let timestampSeconds = UInt64(NSDate().timeIntervalSince1970)
                let res = rgs.updateNetworkGraphNoStd(updateData: snapshot, currentTimeUnix: timestampSeconds)
                if res.isOk() {
                    print("RGS initialized for the first time")
                }
            }
        }
        
        if FileHandler.fileExists(path: "ProbabilisticScorer") {
            let file = FileHandler.readData(path: "ProbabilisticScorer")
            let scoringParams = ProbabilisticScoringParameters.initWithDefault()
            let scorerReadResult = ProbabilisticScorer.read(ser: [UInt8](file!), argA: scoringParams, argB: netGraph, argC: logger)
            if let readResult = scorerReadResult.getValue() {
                let probabilisticScorer = readResult
                let score = probabilisticScorer.asScore()
                self.scorer = MultiThreadedLockableScore(score: score)
                print("Probabilistic Scorer loaded and running")
            } else {
                print("Couldn't loading Probabilistic Scorer")
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
            print("Creating new Probabilistic Scorer")
        }
        
        var serializedChannelManager: [UInt8]? = nil
        if FileHandler.fileExists(path: "ChannelManager") {
            let channelManagerData = FileHandler.readData(path: "ChannelManager")
            serializedChannelManager = [UInt8](channelManagerData!)
            print("Serialized Channel Manager Loaded")
        } else {
            print("Serialized Channel Manager not Available")
        }
        
        var serializedChannelMonitors: [[UInt8]] = []
        if FileHandler.fileExists(path: "Channels") {
            do {
                let urls = try FileHandler.contentsOfDirectory(atPath: "Channels")
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
        
//        let channelManagerConstructionParameters = ChannelManagerConstructionParameters(config: userConfig, entropySource: keysManager.asEntropySource(), nodeSigner: keysManager.asNodeSigner(), signerProvider: keysManager.asSignerProvider(), feeEstimator: feeEstimator, chainMonitor: chainMonitor, txBroadcaster: broadcaster, logger: logger, enableP2PGossip: true, scorer: scorer)
        let channelManagerConstructionParameters = ChannelManagerConstructionParameters(config: userConfig, entropySource: myKeysManager.keysManager.asEntropySource(), nodeSigner: myKeysManager.keysManager.asNodeSigner(), signerProvider: myKeysManager.signerProvider, feeEstimator: feeEstimator, chainMonitor: chainMonitor, txBroadcaster: broadcaster, logger: logger, enableP2PGossip: true, scorer: scorer)
        
        var latestBlockHash: [UInt8]? = nil
        var latestBlockHeight: UInt32? = nil
        guard let blockHashHex = bdkManager.getBlockHash(), let blockHeight = bdkManager.getBlockHeight() else {
            print("Failed to Start Node")
            throw LDKError.failedToGetBlockData
        }
        latestBlockHash = Utils.hexStringToByteArray(blockHashHex)
        latestBlockHeight = blockHeight
        
        if serializedChannelManager != nil && !serializedChannelManager!.isEmpty {
            do {
                self.channelManagerConstructor = try ChannelManagerConstructor(channelManagerSerialized: serializedChannelManager!, channelMonitorsSerialized: serializedChannelMonitors, networkGraph: NetworkGraphArgument.instance(netGraph), filter: filter, params: channelManagerConstructionParameters)
                print("Channel Manager Constructor Loaded")
            } catch {
                print("Failed to load Channel Manager Constructor, creating new one")
                self.channelManagerConstructor = ChannelManagerConstructor(network: network, currentBlockchainTipHash: latestBlockHash!, currentBlockchainTipHeight: latestBlockHeight!, netGraph: netGraph, params: channelManagerConstructionParameters)
                print("New Channel Manager Constructor Created")
            }
        } else {
            self.channelManagerConstructor = ChannelManagerConstructor(network: network, currentBlockchainTipHash: latestBlockHash!, currentBlockchainTipHeight: latestBlockHeight!, netGraph: netGraph, params: channelManagerConstructionParameters)
            print("New Channel Manager Constructor Created")
        }
        self.channelManager = channelManagerConstructor?.channelManager
        self.peerManager = channelManagerConstructor?.peerManager
        self.peerHandler = channelManagerConstructor?.getTCPPeerHandler()
        self.netGraph = channelManagerConstructor?.netGraph
        self.channelManagerPersister = MyChannelManagerPersister()
        self.channelManagerPersister?.ldkManager = self
        self.broadcaster?.ldkManager = self
        if FileHandler.fileExists(path: "Peers") {
            do {
                let urls = try FileHandler.contentsOfDirectory(atPath: "Peers")
                for url in urls {
                    let peerData = try FileHandler.readData(url: url)
                    let peerPubkeyIp = String(data: peerData, encoding: .utf8)!
                    let res = connect(peerPubkeyIp: peerPubkeyIp)
                    if res {
                        print("Peer: \(peerPubkeyIp) connected")
                    }
                }
            } catch {
                print("Failed to connect Peers")
            }
        } else {
            print("No Peers Available")
        }
        try self.sync()
        LDKManager.activityLogger.info("LDK Setup Finished")
    }
    
    func sync() throws {
        self.bdkManager.sync()
        let relevantTxIds1 = channelManager?.asConfirm().getRelevantTxids() ?? []
        let relevantTxIds2 = chainMonitor?.asConfirm().getRelevantTxids() ?? []
        
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
            let txIdHex = Utils.bytesToHex32Reversed(bytes: Utils.arrayToTuple32(array: txId))
            let tx = BlockchainData.getTx(txid: txIdHex, network: network)
            if let tx = tx {
                if tx.status.confirmed {
                    let txHex = BlockchainData.getTxHex(txid: txIdHex, network: network)!
                    let blockHeader = BlockchainData.getBlockHeader(hash: tx.status.block_hash, network: network)
                    let merkleProof = BlockchainData.getMerkleProof(txid: txIdHex, network: network)!
                    if tx.status.block_height == merkleProof.block_height {
                        let newConfirmedTx = ConfirmedTx(txId: tx.txid, tx: Utils.hexStringToByteArray(txHex), block_height: tx.status.block_height, block_header: blockHeader!, merkle_proof_pos: merkleProof.pos)
                        confirmedTxs.append(newConfirmedTx)
                    }
                } else {
                    self.channelManager?.asConfirm().transactionUnconfirmed(txid: Utils.hexStringToByteArray(txIdHex))
                    self.chainMonitor?.asConfirm().transactionUnconfirmed(txid: Utils.hexStringToByteArray(txIdHex))
                }
            }
        }
        
        // Add confirmed Tx from filter Transaction Id
        if let filteredTxIds = filter?.txIds {
            for txId in filteredTxIds {
                let txIdHex = Utils.bytesToHex32Reversed(bytes: Utils.arrayToTuple32(array: txId))
                let tx = BlockchainData.getTx(txid: txIdHex, network: network)
                if let tx = tx, tx.status.confirmed {
                    let txHex = BlockchainData.getTxHex(txid: txIdHex, network: network)!
                    let blockHeader = BlockchainData.getBlockHeader(hash: tx.status.block_hash, network: network)!
                    let merkleProof = BlockchainData.getMerkleProof(txid: txIdHex, network: network)!
                    if tx.status.block_height == merkleProof.block_height {
                        let newConfirmedTx = ConfirmedTx(txId: tx.txid, tx: Utils.hexStringToByteArray(txHex), block_height: tx.status.block_height, block_header: blockHeader, merkle_proof_pos: merkleProof.pos)
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
                let txIdHex = Utils.bytesToHex32Reversed(bytes: Utils.arrayToTuple32(array: txId!))
                let outputIdx = outpoint.getIndex()
                if let res = BlockchainData.outSpend(txid: txIdHex, index: outputIdx, network: network) {
                    if res.spent {
                        let tx = BlockchainData.getTx(txid: res.txid!, network: network)
                        if let tx = tx, tx.status.confirmed {
                            let txHex = BlockchainData.getTxHex(txid: tx.txid, network: network)!
                            let blockHeader = BlockchainData.getBlockHeader(hash: tx.status.block_hash, network: network)!
                            let merkleProof = BlockchainData.getMerkleProof(txid: tx.txid, network: network)!
                            if tx.status.block_height == merkleProof.block_height {
                                let newConfirmedTx = ConfirmedTx(txId: tx.txid, tx: Utils.hexStringToByteArray(txHex), block_height: tx.status.block_height, block_header: blockHeader, merkle_proof_pos: merkleProof.pos)
                                confirmedTxs.append(newConfirmedTx)
                            }
                        }
                    }
                }
            }
        }
        
        confirmedTxs.sort { (tx1, tx2) -> Bool in
            if tx1.block_height != tx2.block_height {
                return tx1.block_height < tx2.block_height
            } else {
                return tx1.merkle_proof_pos < tx2.merkle_proof_pos
            }
        }
        
        // Sync Confirmed Transactions
        for cTx in confirmedTxs {
            var twoTuple: [(UInt, [UInt8])] = []
            let x: (UInt, [UInt8]) = (UInt, [UInt8])(cTx.merkle_proof_pos, cTx.tx)
            twoTuple.append(x)
            
            self.channelManager?.asConfirm().transactionsConfirmed(header: Utils.hexStringToByteArray(cTx.block_header), txdata: twoTuple, height: UInt32(cTx.block_height))
            self.chainMonitor?.asConfirm().transactionsConfirmed(header: Utils.hexStringToByteArray(cTx.block_header), txdata: twoTuple, height: UInt32(cTx.block_height))
        }
        
        // Sync Best Blocks
        let blockHeight = BlockchainData.getTipHeight(network: network)
        var blockHash: String? = nil
        guard let hash = BlockchainData.getTipHash(network: network) else {
            throw LDKError.failedToGetBlockData
        }
        blockHash = hash
        let header = BlockchainData.getBlockHeader(hash: blockHash!, network: network)
        
        self.channelManager?.asConfirm().bestBlockUpdated(header: Utils.hexStringToByteArray(header!), height: blockHeight!)
        self.chainMonitor?.asConfirm().bestBlockUpdated(header: Utils.hexStringToByteArray(header!), height: blockHeight!)
        
        self.channelManagerConstructor!.chainSyncCompleted(persister: channelManagerPersister!)
    }
    
    func getSnapshot(lastSyncTimeStamp: UInt32) -> [UInt8]? {
        let url: URL
        if network == .Testnet {
            url = URL(string: "https://rapidsync.lightningdevkit.org/testnet/snapshot/\(lastSyncTimeStamp)")!
        } else {
            url = URL(string: "https://rapidsync.lightningdevkit.org/snapshot/\(lastSyncTimeStamp)")!
        }
        let data = DataGetPost.get(url: url)
        if let data = data {
            return [UInt8](data)
        }
        return nil
    }

    func getNodeId() -> String {
        guard let channelManager = self.channelManager else {
            return "failed to get nodeID"
        }
        let nodeId = channelManager.getOurNodeId()
        let res = Utils.bytesToHex(bytes: nodeId)
        return res
    }
    
    func connect(peerPubkeyIp: String) -> Bool {
        guard let peerHandler = self.peerHandler else {
            print("PeerHandler not working")
            return false
        }
        
        let pubkeyIp = peerPubkeyIp.components(separatedBy: "@")
        let ipPort = pubkeyIp[1].components(separatedBy: ":")
        
        guard let port = UInt16(ipPort[1]) else {
            print("Could not convert port to UInt16")
            return false
        }
        
        let res = peerHandler.connect(address: ipPort[0], port: port, theirNodeId: Utils.hexStringToByteArray(pubkeyIp[0]))
        if (!res) {
            print("Failed to connect to peer")
            return false
        }
        return res
    }
    
    func listPeers() -> [String] {
        guard let peerManager = self.peerManager else {
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
    
    func openChannel(peerPubkeyIp: String, amount: UInt64, pushMsat: UInt64) -> Bool {
        let pubkeyIp = peerPubkeyIp.components(separatedBy: "@")
        
        let uid = UUID().uuid
        let channelId = Utils.bytesToHex16(bytes: uid)
        
        let userConfig = UserConfig.initWithDefault()
        let channelConfig = ChannelHandshakeConfig.initWithDefault()
        channelConfig.setAnnouncedChannel(val: false)
        userConfig.setChannelHandshakeConfig(val: channelConfig)
        let createChannelResults = self.channelManager?.createChannel(theirNetworkKey: Utils.hexStringToByteArray(pubkeyIp[0]), channelValueSatoshis: amount, pushMsat: pushMsat, userChannelId: channelId, overrideConfig: userConfig)
        if createChannelResults == nil {
            return false
        }
        //        print(createChannelResults?.getError()?.getValueAsApiMisuseError()?.getErr())
        guard let createChannelResults = createChannelResults else {
            print("Couldn't Create Channel")
            return false
        }
        if createChannelResults.isOk() {
            let peerData = Data(peerPubkeyIp.utf8)
            FileHandler.createDirectory(path: "Peers")
            FileHandler.writeData(data: peerData, path: "Peers/\(peerPubkeyIp)")
            return true
        }
        return false
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
//        let invoice = Bindings.createInvoiceFromChannelmanager(channelmanager: self.channelManager!, nodeSigner: self.keysManager!.asNodeSigner(), logger: self.logger, network: currency, amtMsat: amount, description: "Test Invoice", invoiceExpiryDeltaSecs: expiry, minFinalCltvExpiryDelta: nil)
        let invoice = Bindings.createInvoiceFromChannelmanager(channelmanager: self.channelManager!, nodeSigner: myKeysManager.keysManager.asNodeSigner(), logger: self.logger, network: currency, amtMsat: amount, description: "Test Invoice", invoiceExpiryDeltaSecs: expiry, minFinalCltvExpiryDelta: nil)
        
        if invoice.isOk() {
            return invoice.getValue()!.toStr()
        }
        print("Could not create Invoice")
        return nil
    }
    
    func closeChannel(channelId: [UInt8], counterpartyNodeId: [UInt8]) -> Bool {
        let res = self.channelManager?.closeChannel(channelId: channelId, counterpartyNodeId: counterpartyNodeId)
        return res!.isOk()
    }
    
    func listChannels() -> (UInt64, [ChannelDetails]) {
        let channels = channelManager.listChannels()
        var totalBalance: UInt64 = 0
        for channel in channels {
            totalBalance += channel.getBalanceMsat()
        }
        return (totalBalance, channels)
    }
}

enum LDKError: Error {
    case failedToGetBlockData
}
