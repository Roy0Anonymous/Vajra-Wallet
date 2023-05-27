//
//  MyPersister.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit

class MyPersister: Persist {
    override func persistNewChannel(channelId: Bindings.OutPoint, data: Bindings.ChannelMonitor, updateId: Bindings.MonitorUpdateId) -> Bindings.ChannelMonitorUpdateStatus {
        let idBytes: [UInt8] = channelId.write()
        let monitorBytes: [UInt8] = data.write()
        do {
            let data = Data(monitorBytes)
            try FileHandler.createDirectory(path: "channels")
            try FileHandler.writeData(data: data, path: "channels/\(Utils.bytesToHex(bytes: idBytes))")
            print("persistNewChannel: successfully backup channel to channels/\(Utils.bytesToHex(bytes: idBytes))\n")
        }
        catch {
            NSLog("persistNewChannel: problem saving channels/\(Utils.bytesToHex(bytes: idBytes))")
            return .PermanentFailure
        }
        return .Completed
    }
    
    override func updatePersistedChannel(channelId: OutPoint, update: ChannelMonitorUpdate, data: ChannelMonitor, updateId: MonitorUpdateId) -> ChannelMonitorUpdateStatus {
        let idBytes: [UInt8] = channelId.write()
        let monitorBytes: [UInt8] = data.write()
        do {
            let data = Data(monitorBytes)
            try FileHandler.createDirectory(path: "channels")
            try FileHandler.writeData(data: data, path: "channels/\(Utils.bytesToHex(bytes: idBytes))")
            print("updatePersistedChannel: update channel at channels/\(Utils.bytesToHex(bytes: idBytes))\n")
        }
        catch {
            NSLog("updatePersistedChannel: problem updating channels/\(Utils.bytesToHex(bytes: idBytes))")
            return .PermanentFailure
        }
        return .Completed
    }
}
