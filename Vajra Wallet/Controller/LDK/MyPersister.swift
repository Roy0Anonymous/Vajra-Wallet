//
//  MyPersister.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit

class MyPersister: Persist {
    override func persistNewChannel(channelId: Bindings.OutPoint, data: Bindings.ChannelMonitor, updateId: Bindings.MonitorUpdateId) -> Bindings.ChannelMonitorUpdateStatus {
        print("Persisting New Channel")
        let idBytes: [UInt8] = channelId.write()
        let monitorBytes: [UInt8] = data.write()
        let data = Data(monitorBytes)
        FileHandler.createDirectory(path: "Channels")
        FileHandler.writeData(data: data, path: "Channels/\(Utils.bytesToHex(bytes: idBytes))")
        print("persistNewChannel: successfully backup Channel to Channels/\(Utils.bytesToHex(bytes: idBytes))\n")
        return .Completed
    }
    
    override func updatePersistedChannel(channelId: OutPoint, update: ChannelMonitorUpdate, data: ChannelMonitor, updateId: MonitorUpdateId) -> ChannelMonitorUpdateStatus {
        print("Updating Persisted Channel")
        let idBytes: [UInt8] = channelId.write()
        let monitorBytes: [UInt8] = data.write()
        let data = Data(monitorBytes)
        FileHandler.createDirectory(path: "Channels")
        FileHandler.writeData(data: data, path: "Channels/\(Utils.bytesToHex(bytes: idBytes))")
        print("updatePersistedChannel: update Channel at Channels/\(Utils.bytesToHex(bytes: idBytes))\n")
        return .Completed
    }
}
