//
//  MyLogger.swift
//  Vajra Wallet
//
//  Created by Rahul Roy on 27/05/23.
//

import LightningDevKit

class MyLogger: Bindings.Logger {
    override func log(record: Bindings.Record) {
        let rawLog = record.getArgs()
        LDKManager.activityLogger.debug("\(rawLog)")
    }
}
