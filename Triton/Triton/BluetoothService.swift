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
    //@Published var dicoveredPeripheral: CBPeripheral
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
        centralManager.scanForPeripherals(withServices: [ tritonService ])
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("scanning for peripherals")
            scanForPeripherals()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredPeripherals.append(peripheral)
        print("Discovered \(peripheral.name ?? "DEFAULT: noname")")
        
    }
}
