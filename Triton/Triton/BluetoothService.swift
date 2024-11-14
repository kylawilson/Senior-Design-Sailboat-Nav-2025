//
//  BluetoothService.swift
//  Triton
//
//  Created by Kyla Wilson on 10/30/24.
//

import Foundation
import CoreBluetooth
import os

class BluetoothService: NSObject, ObservableObject {
    
    @Published var connectionState: ConnectionStatus = .disconnected
    @Published var discoveredPeripherals: [ CBPeripheral ]
    @Published var isScanning: Bool = false
    private var centralManager: CBCentralManager
    private var connectedPeripheral: CBPeripheral?
    
    override init() {
        //initialize to empty
        centralManager = CBCentralManager()
        discoveredPeripherals = []
        connectedPeripheral = nil
        super.init()
        //after super.init() , initialize to true value
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    func scanForPeripherals() {
        connectionState = .scanning
        centralManager.scanForPeripherals(withServices: nil)    //scan for peripherals w all services
        //centralManager.scanForPeripherals(withServices: [ tritonService ])    //scan fpr triton's service
        print("Scanning for peripherals")
    }
    
    func stopScanningForPeripherals() {
        connectionState = .disconnected
        centralManager.stopScan()
        print("Stopped scanning for peripherals")
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        //if connected to another peripheral, drop connection and connect to new peripheral
        if (connectedPeripheral != nil) {
            centralManager.cancelPeripheralConnection(connectedPeripheral!)
            connectionState = .connecting
            centralManager.connect(peripheral, options: nil)
        }
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOn:
            os_log("CBManager is powered on")
        case .poweredOff:
            os_log("CBManager is not powered on")
            return
        case .resetting:
            os_log("CBManager is resetting")
            return
        case .unauthorized:
            switch central.authorization {
            case .denied:
                os_log("You are not authorized to use Bluetooth")
            case .restricted:
                os_log("Bluetooth is restricted")
            default:
                os_log("Unexpected authorization")
            }
        case .unknown:
            os_log("CBManager state is unknown")
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            return
        @unknown default:
            os_log("A previously unknown central manager state occurred")
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            print("Discovered \(peripheral.name ?? peripheral.identifier.uuidString)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            os_log("Failed to connect to %@. %s", peripheral, String(describing: error))
        }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)? ) {
        os_log("Disconnected from %@", peripheral)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        //connected to the peripheral
        os_log("Connected to %@", peripheral)
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        //discover services on connected peripheral
        peripheral.discoverServices([TransferService.tritonServiceUUID])
    }
}

extension BluetoothService: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: (any Error)? ) {
            guard let peripheralServices = peripheral.services else { return }
            for service in peripheralServices {
                peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
            }
    }
}
