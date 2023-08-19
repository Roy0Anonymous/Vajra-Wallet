# Vajra-Wallet

This is a native iOS Bitcoin wallet app demonstrating the use of Bitcoin Dev Kit and Lightning Dev 
Kit in Swift.

## Features
* [x] On-chain BDK Wallet
* [x] Connect to a Peer
* [x] List Peers
* [x] Get Node ID
* [x] Open Channel
* [x] List Channels
* [x] Display Channel Balances
* [x] Send Payment
* [x] Receive Payment 
* [x] Close Channel

## To use in Regtest.
Download and install [Docker](https://www.docker.com), [Polar](https://lightningpolar.com) and [Electrs](https://github.com/Blockstream/electrs)

Make sure in,
```
Vajra Wallet/Controller/LDK/LDKManager.swift
```
Inside the private constructor,
```
// Set the Bitcoin Network
self.network = .Regtest
```

Start the Docker and then run Polar and create a new Lightning Network.
Go to the directory for Electrs and start Electrs using,
```
cargo run --release --bin electrs -- -vvvv --daemon-dir ~/.polar/networks/1/volumes/bitcoind/backend1/ --network=regtest
```
Now you can run the project.

## To use in Testnet.
Make sure in,
```
Vajra Wallet/Controller/LDK/LDKManager.swift
```
Inside the private constructor,
```
// Set the Bitcoin Network
self.network = .Testnet
```
Now you can run the project.
