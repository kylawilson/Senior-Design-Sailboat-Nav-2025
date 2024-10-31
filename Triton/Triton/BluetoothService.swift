//
//  BluetoothService.swift
//  Triton
//
//  Created by Kyla Wilson on 10/30/24.
//

import Foundation
import CoreBluetooth

class BluetoothService: NSObject, ObservableObject {
    
    private var centralManager: CBCentralManager
    
    override init() {
        //initialize to empty
        centralManager = CBCentralManager()
        super.init()
        //after super.init() , initialize to true value
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scanForPeripherals() {
        centralManager.scanForPeripherals(withServices: [ tritonService ])
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            scanForPeripherals()
        }
    }
}
