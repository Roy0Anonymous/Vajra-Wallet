//
//  BDKManager.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import Foundation
import BitcoinDevKit

public class BDKManager: ObservableObject {
    public var network: Network
    @Published public var wallet: Wallet?
    @Published public var balance: Balance?
    @Published public var transactions: [TransactionDetails] = []
    @Published public var syncState = SyncState.notsynced
    let mnemonic: Mnemonic
    let descriptorSecretKey: DescriptorSecretKey
    let descriptor: Descriptor
    
    private let bdkQueue = DispatchQueue (label: "bdkQueue", qos: .userInitiated)
    private let databaseConfig: DatabaseConfig
    private let blockchainConfig: BlockchainConfig
    private var blockchain: Blockchain?
    
    init(net: Network) {
        print("BDK Setup Started")
        self.network = net
        self.databaseConfig = DatabaseConfig.memory
        let testnetURL = "https://blockstream.info/testnet/api"// "https://mutinynet.com/api"
        let regtestURL = "http://127.0.0.1:3002"
        let esploraConfig = EsploraConfig(baseUrl: network == .regtest ? regtestURL : testnetURL, proxy: nil, concurrency: 5, stopGap: 20, timeout: nil)
        self.blockchainConfig = BlockchainConfig.esplora(config: esploraConfig)
//        if net == .regtest {
//            let esploraConfig = EsploraConfig(baseUrl: "http://127.0.0.1:3002", proxy: nil, concurrency: 5, stopGap: 20, timeout: nil)
//            self.blockchainConfig = BlockchainConfig.esplora(config: esploraConfig)
//        } else {
//            let electrumConfig = ElectrumConfig(url: "ssl://mempool.space:60602", socks5: nil, retry: 5, timeout: nil, stopGap: 10, validateDomain: false)
//            self.blockchainConfig = BlockchainConfig.electrum(config: electrumConfig)
//        }
        self.mnemonic = Mnemonic(wordCount: WordCount.words12)
        self.descriptorSecretKey = DescriptorSecretKey(
            network: net,
            mnemonic: mnemonic,
            password: nil)
        self.descriptor = Descriptor.newBip84(
            secretKey: descriptorSecretKey,
            keychain: KeychainKind.external,
            network: net)
        do {
            self.blockchain = try Blockchain(config: blockchainConfig)
        } catch {
            print("Error Starting BDK")
        }
        print("BDK Setup Finished")
    }
    
    public func loadWallet(descriptor: Descriptor, changeDescriptor: Descriptor?) {
        do {
            let wallet = try Wallet.init(
                descriptor: descriptor,
                changeDescriptor: changeDescriptor,
                network: self.network,
                databaseConfig: self.databaseConfig)
            self.wallet = wallet
        } catch let error {
            debugPrint(error)
        }
    }
    
    public func sync() {
        if wallet != nil {
            self.syncState = SyncState.syncing
            bdkQueue.async {
                do {
                    let blockchain = try Blockchain(config: self.blockchainConfig)
                    try self.wallet!.sync(blockchain: blockchain, progress: nil)
                    DispatchQueue.main.async {
                        self.getBalance()
                        self.getTransactions()
                        self.syncState = SyncState.synced
                    }
                } catch let error {
                    debugPrint(error.localizedDescription)
                    DispatchQueue.main.async {
                        self.syncState = SyncState.failed
                    }
                }
            }
        }
    }
    
    private func getBalance() {
        do {
            self.balance = try self.wallet!.getBalance()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func getTransactions() {
        do {
            let transactions = try self.wallet!.listTransactions(includeRaw: true)
            self.transactions = transactions
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    public func getAddress(addressIndex: AddressIndex) -> String? {
        do {
            let addressInfo = try self.wallet!.getAddress(addressIndex: addressIndex)
            print(addressInfo.address.asString())
            return addressInfo.address.asString()
        } catch (let error){
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    public func fundChannel(script: Script, amount: UInt64) -> Transaction? {
        if wallet != nil {
            do {
                let transaction = try TxBuilder().addRecipient(
                    script: script,
                    amount: amount).feeRate(satPerVbyte: 4.0)
                    .finish(wallet: self.wallet!)
                let _ = try self.wallet!.sign(psbt: transaction.psbt, signOptions: nil)
                let blockchain = try Blockchain(config: self.blockchainConfig)
                try blockchain.broadcast(transaction: transaction.psbt.extractTx())
                return transaction.psbt.extractTx()
            } catch let error {
                debugPrint(error.localizedDescription)
                return nil
            }
        } else {
            debugPrint("Error Funding Channel, no Wallet Found")
            return nil
        }
    }
    
    func createWallet() {
        do {
            let keyData = KeyData(
                mnemonic: mnemonic.asString(),
                descriptor: descriptor.asStringPrivate())
            try saveKeyData(keyData: keyData)
            self.loadWallet(descriptor: descriptor, changeDescriptor: nil)
        } catch let error {
            debugPrint(error)
        }
    }
    
    public func broadcast(txHex: [UInt8]) {
        do {
            let newTransaction = try Transaction(transactionBytes: txHex)
            try blockchain!.broadcast(transaction: newTransaction)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    func getPrivKey() -> [UInt8]{
        return descriptorSecretKey.secretBytes()
    }
    
    public func getBlockHeight() -> UInt32? {
        do {
            return try blockchain!.getHeight()
        } catch {
            print("Failed to get Block Height \(error)")
            return nil
        }
    }
    
    public func getBlockHash() -> String? {
        guard let height = self.getBlockHeight() else {
            print("Failed to get Block Height")
            return nil
        }
        do {
            return try blockchain!.getBlockHash(height: height)
        } catch {
            print("Failed to get Block Hash \(error)")
            return nil
        }
    }
    
    public func getRecoveryPhrase() -> String? {
        return mnemonic.asString()
    }
}

public enum SyncState: String {
    case notsynced
    case syncing
    case synced
    case failed
}
