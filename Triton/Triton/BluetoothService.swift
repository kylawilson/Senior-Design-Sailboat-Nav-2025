//
//  BluetoothService.swift
//  Triton
//
//  Created by Kyla Wilson on 10/30/24.
//

import Foundation
import CoreBluetooth
import os
import UIKit.UIImage
import SwiftUI

class BluetoothService: NSObject, ObservableObject {
    
    @Published var connectionState: ConnectionStatus = .disconnected
    @Published var discoveredPeripherals: [ CBPeripheral ]
    @Published var isScanning: Bool = false
    @Published var gpsData = GPSData()
    @Published var anemometerData = AnemometerData()
    @Published var finalPhotoData = ""
    private var tempPhotoData = Data()                                       //raw jpeg data
    
    //private var centralManager: CBCentralManager = CBCentralManager()
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    
    //test
    var onServicesDiscovered: ((CBPeripheral) -> Void)?
    var onCharacteristicsDiscovered: ((CBPeripheral, CBService) -> Void)?
    var onNotificationStateUpdated: ((CBPeripheral, CBCharacteristic) -> Void)?
    
     var transferServices = [ GPSTransferService.tritonGPSServiceUUID, PhotoTransferService.tritonPhotoServiceUUID ]
    private var gpsTransferCharacteristics = [ GPSTransferService.tritonLongitudeCharacteristicUUID, GPSTransferService.tritonCOGCharacteristicUUID, GPSTransferService.tritonLatitudeCharacteristicUUID, GPSTransferService.tritonDateCharacteristicUUID, GPSTransferService.tritonAltitudeCharacteristicUUID, GPSTransferService.tritonLatitudeIndicatorCharacteristicUUID, GPSTransferService.tritonLongitudeIndicatorCharacteristicUUID, GPSTransferService.tritonTimeCharacteristicUUID, GPSTransferService.tritonSpeedCharacteristicUUID]
    private var photoTransferCharacteristics = [ PhotoTransferService.tritonPhotoCharacteristicUUID ]
    private var subscribedCharacteristics : [ CBCharacteristic ]
    private var photoCharacteristic : CBCharacteristic?
    
    //test
    
    override init() {
        discoveredPeripherals = []
        connectedPeripheral = nil
        subscribedCharacteristics = []
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    
    func scanForPeripherals() {
        connectionState = .scanning
        centralManager.scanForPeripherals(withServices: [ TransferService.tritonAdvertisingServiceUUID ])    //scan for triton's service
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
        if connectedPeripheral != nil {
            connectToPeripheral(peripheral: connectedPeripheral!)
        } else {
            self.scanForPeripherals()
        }
        
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
                connectionState = .disconnected
                subscribedCharacteristics = []
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
        print("making call to discover services\n")
        peripheral.discoverServices(transferServices)

        //test
        onServicesDiscovered = { discoveredPeripheral in
                    guard let services = discoveredPeripheral.services else { return }
                    for service in services {
                        os_log("Discovering characteristics for service %@", service.uuid.uuidString)
                        discoveredPeripheral.discoverCharacteristics(nil, for: service)
                    }
                }
                
        // Set closure to handle characteristic discovery completion
        onCharacteristicsDiscovered = { discoveredPeripheral, service in
            guard let characteristics = service.characteristics else { return }
            for characteristic in characteristics {
                if self.gpsTransferCharacteristics.contains(characteristic.uuid) || self.photoTransferCharacteristics.contains(characteristic.uuid) {
                    if self.photoTransferCharacteristics.contains(characteristic.uuid) {
                        self.photoCharacteristic = characteristic
                    }
                    os_log("Subscribing to characteristic %@", characteristic.uuid.uuidString)
                    self.subscribedCharacteristics.append(characteristic)
                    discoveredPeripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
        
        // Set closure to handle notification state updates
        onNotificationStateUpdated = { discoveredPeripheral, characteristic in
            if characteristic.isNotifying {
                os_log("Notification started for %@", characteristic.uuid.uuidString)
                self.writeData()
            } else {
                os_log("Notification stopped for %@", characteristic.uuid.uuidString)
            }
        }
    }
}

extension BluetoothService: CBPeripheralDelegate {
    
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: (any Error)? ) {
            if let error = error {
                    os_log("Error discovering services: %@", error.localizedDescription)
                    return
            } else {
//                print("discovered ", peripheral)
//                guard let peripheralServices = peripheral.services else { os_log("Error in didDiscoverServices"); return }
//                for service in peripheralServices {
//                    print(service.uuid)
//                    peripheral.discoverCharacteristics(nil, for: service)
//                }
                onServicesDiscovered?(peripheral)
            }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)? ) {
            if let error = error {
                    os_log("Error discovering characteristics: %@", error.localizedDescription)
                    return
            } else {
//                guard let serviceCharacteristics = service.characteristics else { return }
//                print("discovered characteristics")
//                for characteristic in serviceCharacteristics  {
//                    //subscribe only to the characteristics we want (in this case, GPS characteristics and photo characteristics)
//                    if gpsTransferCharacteristics.contains(characteristic.uuid) || photoTransferCharacteristics.contains(characteristic.uuid) {
//                        print(characteristic.uuid)
//                        subscribedCharacteristics.append(characteristic)
//                        peripheral.setNotifyValue(true, for: characteristic)
//                    }
//                }
                onCharacteristicsDiscovered?(peripheral, service)
            }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error changing notification state: %s", error.localizedDescription)
            return
        }
//        if characteristic.isNotifying {
//            // Notification has started
//            os_log("Notification began on %@", characteristic)
//        } else {
//            // Notification has stopped, so disconnect from the peripheral
//            os_log("Notification stopped on %@. Disconnecting", characteristic)
//        }
        onNotificationStateUpdated?(peripheral, characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            //photo data
            if photoTransferCharacteristics.contains(characteristic.uuid) {
                let str = String(data: value, encoding: .utf8)
                if str == "IMAGE_END" {
                    updatePhotoCharacteristicUI()
                } else {
                    let newval = value.map { String(format: "%02x", $0) }.joined()
                    tempPhotoData.append(value)
                    print("Photo data received: \(newval), size: \(tempPhotoData)")
//                    if str != nil {
//                        tempPhotoData+=str!
//                    }
                }
            } else {
            //GPS data
                // Process the received value
                //let receivedString = String(data: value, encoding: .utf8)
                //print("Notification received: \(receivedString ?? "N/A")")
                let newval = value.map { String(format: "%02x", $0) }.joined()
                print("Notification received: \(newval)")
                updateGPSCharacteristicUI(characteristic.uuid, value)
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("Peripheral modified services")
        peripheral.discoverServices(transferServices)
    }
    
    
    func createImage(_ value: Data) -> Image {
        let songArtwork: UIImage = UIImage(data: value) ?? UIImage()
        return Image(uiImage: songArtwork)
    }
    
    func updatePhotoCharacteristicUI() {
        //take photoData and turn it into an image
        print("updating photo\n")
        //let finalPhotoData = String(data: tempPhotoData, encoding: .utf8)
        //finalPhotoData = tempPhotoData
        //let finalPhotoData = tempPhotoData.base64EncodedString()
        finalPhotoData = String(data: tempPhotoData, encoding: .utf8)!
        tempPhotoData = Data()
        writeData()
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        //test
        os_log("Peripheral is ready, send data")
        let packetData = "ready!".data(using: .utf8)
        if photoCharacteristic != nil {
            peripheral.writeValue(packetData!, for: photoCharacteristic!, type: .withResponse )
        }
    
    }
    
    func writeData() {
        os_log("Peripheral is ready, send data")
        let packetData = "ready!".data(using: .utf8)
        if photoCharacteristic != nil {
            connectedPeripheral?.writeValue(packetData!, for: photoCharacteristic!, type: .withoutResponse)
        }
    }
    
    func updateGPSCharacteristicUI(_ uuid: CBUUID, _ value: Data ) {
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
        case AnemometerTransferService.tritonWindDirectionCharacteristicUUID :
            anemometerData.windDirection = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case AnemometerTransferService.tritonWindSpeedCharacteristicUUID :
            anemometerData.windSpeed = String(data: value, encoding: .utf8) ?? "N/A"
            break
        default:
            print("NO MATCH FOR UUID, CANNOT UPDATE UI")
            
        }
        
    }
}
