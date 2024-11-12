//
//  BluetoothService.swift
//  Triton
//
//  Created by Kyla Wilson on 10/30/24.
//

import Foundation
import CoreBluetooth

class BluetoothService: NSObject, ObservableObject {
    
    @Published var connectionState: ConnectionStatus = .disconnected
    @Published var discoveredPeripherals: [ CBPeripheral ]
    @Published var isScanning: Bool = false;
    private var centralManager: CBCentralManager
    
    override init() {
        //initialize to empty
        centralManager = CBCentralManager()
        discoveredPeripherals = []
        super.init()
        //after super.init() , initialize to true value
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    func scanForPeripherals() {
        connectionState = .scanning
        centralManager.scanForPeripherals(withServices: nil)
        print("Scanning for peripherals")
    }
    
    func stopScanningForPeripherals() {
        connectionState = .disconnected
        centralManager.stopScan()
        print("Stopped scanning for peripherals")
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        connectionState = .connecting
        centralManager.connect(peripheral)
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Central Powered On")
            //print("scanning for peripherals")
            //scanForPeripherals()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            print("Discovered \(peripheral.name ?? peripheral.identifier.uuidString)")
        }
    }
}
