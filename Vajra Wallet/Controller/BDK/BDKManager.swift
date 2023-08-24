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
    var mnemonic: Mnemonic?
    var descriptorSecretKey: DescriptorSecretKey?
    var descriptor: Descriptor?
    
    private let databaseConfig: DatabaseConfig
    private let blockchainConfig: BlockchainConfig
    private var blockchain: Blockchain?
    
    init(network: Network) {
        LDKManager.activityLogger.info("BDK Setup Started")
        self.network = network
        self.databaseConfig = DatabaseConfig.memory
        let testnetURL = "https://mempool.space/testnet/api"//"https://blockstream.info/testnet/api"
        let regtestURL = "http://127.0.0.1:3002"
        let esploraConfig = EsploraConfig(baseUrl: network == .regtest ? regtestURL : testnetURL, proxy: nil, concurrency: 5, stopGap: 20, timeout: nil)
        self.blockchainConfig = BlockchainConfig.esplora(config: esploraConfig)
        
        if FileHandler.fileExists(path: "Mnemonic") {
            print("Mnemonic Exists")
            let mnemonicData = FileHandler.readData(path: "Mnemonic")
            let mnemonicStr = String(data: mnemonicData!, encoding: .utf8)!
            do {
                self.mnemonic = try Mnemonic.fromString(mnemonic: mnemonicStr)
                self.descriptorSecretKey = DescriptorSecretKey(
                    network: network,
                    mnemonic: self.mnemonic!,
                    password: nil)
                self.descriptor = Descriptor.newBip84(secretKey: descriptorSecretKey!, keychain: .external, network: network)
                loadWallet(descriptor: descriptor!, changeDescriptor: nil)
                print("Wallet Loaded")
            } catch {
                print("Error Loading Wallet")
            }
        }
        do {
            self.blockchain = try Blockchain(config: blockchainConfig)
        } catch {
            print("Error Starting BDK")
        }
        LDKManager.activityLogger.info("BDK Setup Finished")
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
            DispatchQueue.main.async {
                self.syncState = SyncState.syncing
            }
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
            LDKManager.activityLogger.log("New Address: \(addressInfo.address.asString())")
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
        print("Creating Wallet")
        self.mnemonic = Mnemonic(wordCount: .words12)
        self.descriptorSecretKey = DescriptorSecretKey(
            network: network,
            mnemonic: self.mnemonic!,
            password: nil)
        self.descriptor = Descriptor.newBip84(
            secretKey: descriptorSecretKey!,
            keychain: .external,
            network: network)
        let mnemonicData = Data(self.mnemonic!.asString().utf8)
        FileHandler.writeData(data: mnemonicData, path: "Mnemonic")
        self.loadWallet(descriptor: descriptor!, changeDescriptor: nil)
        print("Wallet Created")
    }
    
    public func broadcast(transaction: Transaction) -> Bool {
        do {
            try blockchain!.broadcast(transaction: transaction)
            return true
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        return false
    }
    
    func getPrivKey() throws -> [UInt8] {
        let ldkDerivationPath = try DerivationPath(path: "m/535h")
        let ldkChild = try descriptorSecretKey!.derive(path: ldkDerivationPath)
        let entropy = ldkChild.secretBytes()
        return entropy
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
        return mnemonic!.asString()
    }
    
    public func recoverWallet(mnemonicStr: String) -> Bool {
        do {
            self.mnemonic = try Mnemonic.fromString(mnemonic: mnemonicStr)
            self.descriptorSecretKey = DescriptorSecretKey(
                network: network,
                mnemonic: self.mnemonic!,
                password: nil)
            self.descriptor = Descriptor.newBip84(secretKey: descriptorSecretKey!, keychain: .external, network: network)
            let mnemonicData = Data(self.mnemonic!.asString().utf8)
            FileHandler.writeData(data: mnemonicData, path: "Mnemonic")
            loadWallet(descriptor: descriptor!, changeDescriptor: nil)
            print("Wallet Loaded")
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

public enum SyncState: String {
    case notsynced
    case syncing
    case synced
    case failed
}
