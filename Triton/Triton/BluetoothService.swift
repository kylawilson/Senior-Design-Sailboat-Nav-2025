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
    @Published var gpsData = GPSData()
    private var centralManager: CBCentralManager
    private var connectedPeripheral: CBPeripheral?
    private var gpsTransferCharacteristics = [ GPSTransferService.tritonLongitudeCharacteristicUUID, GPSTransferService.tritonCOGCharacteristicUUID, GPSTransferService.tritonLatitudeCharacteristicUUID, GPSTransferService.tritonDateCharacteristicUUID, GPSTransferService.tritonAltitudeCharacteristicUUID, GPSTransferService.tritonLatitudeIndicatorCharacteristicUUID, GPSTransferService.tritonLongitudeIndicatorCharacteristicUUID, GPSTransferService.tritonTimeCharacteristicUUID, GPSTransferService.tritonSpeedCharacteristicUUID]
    private var subscribedCharacteristics : [ CBCharacteristic ]
    
    
    override init() {
        //initialize to empty
        centralManager = CBCentralManager()
        discoveredPeripherals = []
        connectedPeripheral = nil
        subscribedCharacteristics = []
        super.init()
        //after super.init() , initialize to true value
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    func scanForPeripherals() {
        connectionState = .scanning
        centralManager.scanForPeripherals(withServices: [ GPSTransferService.tritonAdvertisingServiceUUID ])    //scan for triton's service
        os_log("Scanning for peripherals")
    }
    
    func stopScanningForPeripherals() {
//        connectionState = .disconnected
        centralManager.stopScan()
        os_log("Stopped scanning for peripherals")
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        //if connected to another peripheral, drop connection and connect to new peripheral
        print("connecting")
        if (connectedPeripheral != nil) {
            centralManager.cancelPeripheralConnection(connectedPeripheral!)
            connectionState = .connecting
            centralManager.connect(peripheral, options: nil)
        } else {
            connectionState = .connecting
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func reconnect() {
        //if there is a connected peripheral, then drop the connection
//        if connectedPeripheral != nil {
//            centralManager.cancelPeripheralConnection(connectedPeripheral!)
//        }
        self.scanForPeripherals()
    }
    
    func disconnect() {
        connectionState = .disconnecting
        if connectedPeripheral != nil {
            centralManager.cancelPeripheralConnection(connectedPeripheral!)
        }
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOn:
            os_log("CBManager is powered on")
            scanForPeripherals()
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
        
        //if not already in list, add peripheral to discoveredPeripherals
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            print("Discovered \(peripheral.name ?? peripheral.identifier.uuidString)")
        }
        
        //if we're not connected to peripheral and the UUID matches, then stop scanning and connect to peripheral
        if connectedPeripheral == nil && peripheral.identifier.uuidString == "209865E4-7152-710C-C3BB-45A25B2EBCDF" {
            print("Discovered target peripheral, auto-connecting...")
            stopScanningForPeripherals()
            connectToPeripheral(peripheral: peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            os_log("Failed to connect to %@. %s", peripheral, String(describing: error))
        }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)? ) {
            if (connectionState != .disconnecting) {
                os_log("Disconnected from %@, reconnecting...", peripheral)
                reconnect()
            } else {
                os_log("Disconnected from %@", peripheral)
                connectionState = .disconnected
                connectedPeripheral = nil
                discoveredPeripherals = []
            }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        
        //connected to the peripheral
        os_log("Connected to %@", peripheral)
        
        connectionState = .connected
        connectedPeripheral = peripheral
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        //discover services on connected peripheral
        peripheral.discoverServices(nil)
    }
}

extension BluetoothService: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: (any Error)? ) {
            print("discovered %@", peripheral)
            guard let peripheralServices = peripheral.services else { os_log("Error in didDiscoverServices"); return }
            for service in peripheralServices {
                print(service.uuid)
                peripheral.discoverCharacteristics(nil, for: service)
            }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)? ) {
        print("discovered characteristics")
            guard let serviceCharacteristics = service.characteristics else { return }
            for characteristic in serviceCharacteristics  {
                //subscribe only to the characteristics we want (in this case, GPS characteristics)
                if gpsTransferCharacteristics.contains(characteristic.uuid) {
                    print(characteristic.uuid)
                    subscribedCharacteristics.append(characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error changing notification state: %s", error.localizedDescription)
            return
        }
        if characteristic.isNotifying {
            // Notification has started
            os_log("Notification began on %@", characteristic)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            os_log("Notification stopped on %@. Disconnecting", characteristic)
        }     
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            // Process the received value
            //let receivedString = String(data: value, encoding: .utf8)
            //print("Notification received: \(receivedString ?? "N/A")")
            let newval = value.map { String(format: "%02x", $0) }.joined()
            print("Notification received: \(newval)")
            updateCharacteristicUI(characteristic.uuid, value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("Peripheral modified services. Disconnect and attempt reconnect")
        //centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func updateCharacteristicUI(_ uuid: CBUUID, _ value: Data ) {
        switch (uuid) {
        case GPSTransferService.tritonDateCharacteristicUUID :
            gpsData.date = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case GPSTransferService.tritonTimeCharacteristicUUID :
            gpsData.time = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case GPSTransferService.tritonAltitudeCharacteristicUUID :
            gpsData.altitude = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case GPSTransferService.tritonCOGCharacteristicUUID :
            gpsData.COG = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case GPSTransferService.tritonSpeedCharacteristicUUID :
            gpsData.speed = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case GPSTransferService.tritonLatitudeCharacteristicUUID :
            gpsData.latitude = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case GPSTransferService.tritonLatitudeIndicatorCharacteristicUUID :
            gpsData.latitudeInd = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case GPSTransferService.tritonLongitudeCharacteristicUUID :
            gpsData.longitude = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case GPSTransferService.tritonLongitudeIndicatorCharacteristicUUID :
            gpsData.longitudeInd = String(data: value, encoding: .utf8) ?? "N/A"
            break
        default:
            print("NO MATCH FOR UUID, CANNOT UPDATE UI")
            
        }
        
    }
}
