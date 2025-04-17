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
    @Published var tritonConnectionState: ConnectionStatus = .disconnected
    @Published var stereoPi1ConnectionState: ConnectionStatus = .disconnected
    @Published var stereoPi2ConnectionState: ConnectionStatus = .disconnected
    @Published var discoveredPeripherals: [ CBPeripheral ]
    @Published var isScanning: Bool = false
    @Published var gpsData = GPSData()
    @Published var anemometerData = AnemometerData()
    @Published var finalPhotoData = ""
    @Published var depthArray: [CGFloat] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    @Published var objectArray: [CGFloat] = []
    @Published var coordinateArray: [(CGFloat, CGFloat)] = []
    @Published var stereoPiArray1: [CGFloat] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    @Published var stereoPiArray2: [CGFloat] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    @Published var liveView: Bool = false
    private var tempPhotoData = Data()                                       //raw jpeg data
    
    //private var centralManager: CBCentralManager = CBCentralManager()
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    var connectedTriton: CBPeripheral?
    var connectedStereoPi1: CBPeripheral?
    var connectedStereoPi2: CBPeripheral?
    
    
    //test
    var onServicesDiscovered: ((CBPeripheral) -> Void)?
    var onCharacteristicsDiscovered: ((CBPeripheral, CBService) -> Void)?
    var onNotificationStateUpdated: ((CBPeripheral, CBCharacteristic) -> Void)?
    
    var transferServices = [ GPSTransferService.tritonGPSServiceUUID, PhotoTransferService.tritonPhotoServiceUUID, AnemometerTransferService.tritonAnemometerServiceUUID,  RenderingTransferService.tritonRenderingServiceUUID]
    var stereoPiTransferServices = [ StereoPiTransferService.tritonStereoPiServiceUUID ]
    private var gpsTransferCharacteristics = [ GPSTransferService.tritonLongitudeCharacteristicUUID, GPSTransferService.tritonCOGCharacteristicUUID, GPSTransferService.tritonLatitudeCharacteristicUUID, GPSTransferService.tritonDateCharacteristicUUID, GPSTransferService.tritonAltitudeCharacteristicUUID, GPSTransferService.tritonLatitudeIndicatorCharacteristicUUID, GPSTransferService.tritonLongitudeIndicatorCharacteristicUUID, GPSTransferService.tritonTimeCharacteristicUUID, GPSTransferService.tritonSpeedCharacteristicUUID]
    private var photoTransferCharacteristics = [ PhotoTransferService.tritonPhotoCharacteristicUUID ]
    private var renderingTransferCharacteristics = [ RenderingTransferService.tritonRenderingDepthCharacteristicUUID,
        RenderingTransferService.tritonRenderingObjectCharacteristicUUID]
    private var stereoPiTransferCharacteristics = [ StereoPiTransferService.tritonStereoPiDepthCharacteristicUUID ]
    private var anemometerTransferCharacteristics = [ AnemometerTransferService.tritonWindSpeedCharacteristicUUID, AnemometerTransferService.tritonWindDirectionCharacteristicUUID ]
    private var subscribedCharacteristics : [ CBCharacteristic ]
    private var photoCharacteristic : CBCharacteristic?
    
    private var updatingTime = false
    private var timer: Timer?
    
    //test
    
    override init() {
        discoveredPeripherals = []
        connectedPeripheral = nil
        connectedTriton = nil
        connectedStereoPi1 = nil
        connectedStereoPi2 = nil
        subscribedCharacteristics = []
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    
    func scanForPeripherals() {
        tritonConnectionState = .scanning
        stereoPi1ConnectionState = .scanning
        stereoPi2ConnectionState = .scanning
        centralManager.scanForPeripherals(withServices: [ TransferService.tritonAdvertisingServiceUUID, TransferService.stereoPiAdvertisingServiceUUID])    //scan for triton's service
        os_log("Scanning for peripherals")
    }
    
    func stopScanningForPeripherals() {
        centralManager.stopScan()
        os_log("Stopped scanning for peripherals")
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        print("connecting to \(String(describing: peripheral.name))")
        if (peripheral.identifier.uuidString == "209865E4-7152-710C-C3BB-45A25B2EBCDF") {
            tritonConnectionState = .connecting
        } else if (peripheral.identifier.uuidString == "D0EDD06D-F7D7-5D24-0C24-A245604D81C6") {
            stereoPi1ConnectionState = .connecting
        } else if (peripheral.identifier.uuidString == "D0EDD06D-F7D7-5D24-0C24-A245604D81C0") {
            stereoPi2ConnectionState = .connecting
        }
        centralManager.connect(peripheral, options: nil)
    }
    
    //revisit this logic for multiple bluetooth devices
    func reconnect( _ peripheral: CBPeripheral) {
        connectToPeripheral(peripheral: peripheral)
    }
    
    func disconnect() {
        tritonConnectionState = .disconnecting
        stereoPi1ConnectionState = .disconnecting
        stereoPi2ConnectionState = .disconnecting
        if connectedTriton != nil {
            centralManager.cancelPeripheralConnection(connectedTriton!)
        }
        if connectedStereoPi1 != nil {
            centralManager.cancelPeripheralConnection(connectedStereoPi1!)
        }
        if connectedStereoPi2 != nil {
            centralManager.cancelPeripheralConnection(connectedStereoPi2!)
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
        print(peripheral.name)
        print(peripheral.identifier.uuidString)
        
        //if not already in list, add peripheral to discoveredPeripherals
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            print("Discovered \(peripheral.name ?? peripheral.identifier.uuidString)")
        }
        
        //if we're not connected to peripheral and the UUID matches, then stop scanning and connect to peripheral
        //connectedPeripheral == nil &&
        if (peripheral.identifier.uuidString == "209865E4-7152-710C-C3BB-45A25B2EBCDF" || peripheral.identifier.uuidString == "D0EDD06D-F7D7-5D24-0C24-A245604D81C6") {
            print("Discovered target peripheral, auto-connecting...")
            //stopScanningForPeripherals()
            connectToPeripheral(peripheral: peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            os_log("Failed to connect to %@. %s", peripheral, String(describing: error))
            switch (peripheral.identifier.uuidString) {
                case "209865E4-7152-710C-C3BB-45A25B2EBCDF":
                    tritonConnectionState = .disconnected
                case "D0EDD06D-F7D7-5D24-0C24-A245604D81C6":
                    stereoPi1ConnectionState = .disconnected
                case "D0EDD06D-F7D7-5D24-0C24-A245604D81C0":
                    stereoPi2ConnectionState = .disconnected
                default:
                    stereoPi2ConnectionState = .disconnected
            }
        }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)? ) {
            print(tritonConnectionState)
            if (tritonConnectionState != .disconnecting) {
                os_log("Disconnected from %@, reconnecting...", peripheral)
                switch (peripheral.identifier.uuidString) {
                    case "209865E4-7152-710C-C3BB-45A25B2EBCDF":
                        tritonConnectionState = .disconnected
                    case "D0EDD06D-F7D7-5D24-0C24-A245604D81C6":
                        stereoPi1ConnectionState = .disconnected
                    default:
                        stereoPi2ConnectionState = .disconnected
                }
                subscribedCharacteristics = []
                print("reconnecting peripheral")
                reconnect(peripheral)
            } else {
                os_log("Disconnected from %@", peripheral)
                if (peripheral.identifier.uuidString == "209865E4-7152-710C-C3BB-45A25B2EBCDF") {
                    tritonConnectionState = .disconnected
//                    connectedTriton = nil
                } else if (peripheral.identifier.uuidString == "D0EDD06D-F7D7-5D24-0C24-A245604D81C6") {
                    stereoPi1ConnectionState = .disconnected
//                    connectedStereoPi1 = nil
                } else {
                    stereoPi2ConnectionState = .disconnected
//                    connectedStereoPi2 = nil
                }
                discoveredPeripherals = []
                subscribedCharacteristics = []
                liveView = false
            }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        
        if (peripheral.identifier.uuidString == "209865E4-7152-710C-C3BB-45A25B2EBCDF") {
            tritonConnectionState = .connected
            connectedTriton = peripheral
        } else if (peripheral.identifier.uuidString == "D0EDD06D-F7D7-5D24-0C24-A245604D81C6") {
            stereoPi1ConnectionState = .connected
            connectedStereoPi1 = peripheral
        } else if (peripheral.identifier.uuidString == "D0EDD06D-F7D7-5D24-0C24-A245604D81C0"){     //this is a random uuid that I am using until we have the next pi up and running
            stereoPi2ConnectionState = .connected
            connectedStereoPi2 = peripheral
        }
        
        if connectedTriton != nil && connectedStereoPi1 != nil && connectedStereoPi2 != nil {
            stopScanningForPeripherals()
        }
        
        //connected to the peripheral
        os_log("Connected to %@", peripheral)
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        //discover services on connected peripheral
        print("making call to discover services\n")
        if peripheral.identifier.uuidString == "209865E4-7152-710C-C3BB-45A25B2EBCDF" {
            peripheral.discoverServices(transferServices)
        } else if peripheral.identifier.uuidString == "D0EDD06D-F7D7-5D24-0C24-A245604D81C6" {
            peripheral.discoverServices(stereoPiTransferServices)
        }

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
                if self.gpsTransferCharacteristics.contains(characteristic.uuid) ||
                    self.renderingTransferCharacteristics.contains(characteristic.uuid) || self.stereoPiTransferCharacteristics.contains(characteristic.uuid) || self.anemometerTransferCharacteristics.contains(characteristic.uuid) {
                    os_log("Subscribing to characteristic %@", characteristic.uuid.uuidString)
                    self.subscribedCharacteristics.append(characteristic)
                    discoveredPeripheral.setNotifyValue(true, for: characteristic)
                }
                if self.photoTransferCharacteristics.contains(characteristic.uuid) {
                    self.liveView ? discoveredPeripheral.setNotifyValue(true, for: characteristic): discoveredPeripheral.setNotifyValue(false, for: characteristic)
                }
            }
        }
        
        // Set closure to handle notification state updates
        onNotificationStateUpdated = { discoveredPeripheral, characteristic in
            if characteristic.isNotifying {
                os_log("Notification started for %@", characteristic.uuid.uuidString)
                //self.writeData()
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
                onCharacteristicsDiscovered?(peripheral, service)
            }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("Error changing notification state: %s", error.localizedDescription)
            return
        } else {
            onNotificationStateUpdated?(peripheral, characteristic)
        }
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
                }
                if !updatingTime {
                    updatingTime = true
                    startUpdatingTime()
                }
            } else if gpsTransferCharacteristics.contains(characteristic.uuid) {
            //GPS data
                let newval = value.map { String(format: "%02x", $0) }.joined()
                //print("GPS data received: \(newval)")
                let dataString = String(data: value, encoding: .utf8) ?? "N/A"
                //print("GPS Data: \(dataString)")
                parseGPSString(dataString)
                //updateGPSCharacteristicUI(characteristic.uuid, value)
            } else if renderingTransferCharacteristics.contains(characteristic.uuid) {
                updateRendering(characteristic.uuid, value)
            } else if stereoPiTransferCharacteristics.contains(characteristic.uuid){
                let newval = value.map { String(format: "%02x", $0) }.joined()
                let floatArray = value.withUnsafeBytes { rawBufferPointer -> [Float] in
                    let floatPointer = rawBufferPointer.bindMemory(to: Float.self)
                    return Array(floatPointer)
                }
                let cgFloatArray = floatArray.map { CGFloat($0) }
                let dividedCGFloatArray = cgFloatArray.map { $0 / 100 }
                print("StereoPiArray Received in Meters: \(dividedCGFloatArray)")
                stereoPiArray1 = dividedCGFloatArray
            } else if anemometerTransferCharacteristics.contains(characteristic.uuid){
                updateAnemometer(characteristic.uuid, value)
                let newval = value.map { String(format: "%02x", $0) }.joined()
                //print("Anemometer data received: \(newval)")
            }
        }
    }
    
    func startPhotoService() {
        if (tritonConnectionState == .connected) {
            connectedTriton!.discoverServices(transferServices)
        }
    }
    
    func stopPhotoService() {
        if (tritonConnectionState == .connected) {
            connectedTriton!.discoverServices(transferServices)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("Peripheral modified services")
        for service in invalidatedServices {
            print("Invalidated Service: ", service)
            if (peripheral.identifier.uuidString == "209865E4-7152-710C-C3BB-45A25B2EBCDF") {
                tritonConnectionState = .disconnected
            } else if (peripheral.identifier.uuidString == "D0EDD06D-F7D7-5D24-0C24-A245604D81C6") {
                stereoPi1ConnectionState = .disconnected
            } else if (peripheral.identifier.uuidString == "D0EDD06D-F7D7-5D24-0C24-A245604D81C0"){     //this is a random uuid that I am using until we have the next pi up and running
                stereoPi2ConnectionState = .disconnected
            }
        }
        
    }
    
    func updatePhotoCharacteristicUI() {
        //take photoData and turn it into an image
        print("updating photo\n")
        finalPhotoData = String(data: tempPhotoData, encoding: .utf8)!
        tempPhotoData = Data()
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
            connectedPeripheral?.writeValue(packetData!, for: photoCharacteristic!, type: .withResponse)
        }
    }
    
    func startUpdatingTime() {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.updateTime()
            }
        }
    
    func stopUpdatingTime() {
            timer?.invalidate()
            timer = nil
            print("Time updating stopped.")
        }
        
    func updateTime() {
        if let timeFloat = Float(gpsData.time) {
            gpsData.time = String(timeFloat + 1)
            print("Updated time:", gpsData.time)
        } else {
            print("Error: gpsData.time is not a valid number")
        }
    }
    
    func parseGPSString(_ input: String) {

        // Split by commas
        let parts = input.components(separatedBy: ",")
        
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[GGA] UTCtime:") {
                let temp_time = trimmed.replacingOccurrences(of: "[GGA] UTCtime:", with: "").trimmingCharacters(in: .whitespaces)
                gpsData.time = convertUTCtoEST(utcTime: temp_time) ?? "000000.000"
            } else if trimmed.hasPrefix("Latitude:") {
                gpsData.latitude = trimmed.replacingOccurrences(of: "Latitude:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("latIndicator:") {
                gpsData.latitudeInd = trimmed.replacingOccurrences(of: "latIndicator:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Longitude:") {
                gpsData.longitude = trimmed.replacingOccurrences(of: "Longitude:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("longIndicator:") {
                gpsData.longitudeInd = trimmed.replacingOccurrences(of: "longIndicator:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Fix?") {
                gpsData.fix = trimmed.replacingOccurrences(of: "Fix?:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Altitude:") {
                gpsData.altitude = trimmed.replacingOccurrences(of: "Altitude:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("[RMC] Speed:") {
                gpsData.speed = trimmed.replacingOccurrences(of: "[RMC] Speed:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("COG:") {
                gpsData.COG = trimmed.replacingOccurrences(of: "COG:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Date:") {
                gpsData.date = trimmed.replacingOccurrences(of: "Date:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
    }
    
    func updateRendering(_ uuid: CBUUID, _ value: Data ) {
        switch(uuid) {
        case (RenderingTransferService.tritonRenderingDepthCharacteristicUUID) :
            let newval = value.map { String(format: "%02x", $0) }.joined()
            //now want to convert bytes to array of floats, test in Lab on Mon/Tues
            let floatArray = value.withUnsafeBytes { rawBufferPointer -> [Float] in
                let floatPointer = rawBufferPointer.bindMemory(to: Float.self)
                return Array(floatPointer)
            }
            let cgFloatArray = floatArray.map { CGFloat($0) }
            let dividedCGFloatArray = cgFloatArray.map { $0 / 1000 }
            print("Oak-D Array Received in Meters: \(dividedCGFloatArray)")
            depthArray = dividedCGFloatArray
        case (RenderingTransferService.tritonRenderingObjectCharacteristicUUID) :
            let newval = value.map { String(format: "%02x", $0) }.joined()
            //now want to convert bytes to array of floats, test in Lab on Mon/Tues
            let floatArray = value.withUnsafeBytes { rawBufferPointer -> [Float] in
                let floatPointer = rawBufferPointer.bindMemory(to: Float.self)
                return Array(floatPointer)
            }
            let cgFloatArray = floatArray.map { CGFloat($0) }
            print("Object Array Received: \(cgFloatArray)")
            //let dividedCGFloatArray = cgFloatArray.map { $0 / 1000 }
            objectArray = cgFloatArray
            coordinateArray.removeAll()
            for i in stride(from: 0, to: objectArray.count, by: 3) {
                let x = objectArray[i + 1] / 1000
                let y = objectArray[i + 2]
                self.coordinateArray.append((x, y))
            }
            //print("COORDINATE ARRAY: \(coordinateArray)")
        default:
            print("Unhandled Rendering Characteristics")
        }
    }
    
    func updateAnemometer(_ uuid: CBUUID, _ value: Data) {
        switch(uuid) {
        case AnemometerTransferService.tritonWindSpeedCharacteristicUUID:
            if let newval = String(data: value, encoding: .ascii) {
                anemometerData.windSpeed = newval
            } else {
                print("Failed to decode wind speed as ASCII")
            }

        case AnemometerTransferService.tritonWindDirectionCharacteristicUUID:
            if let newval = String(data: value, encoding: .ascii) {
                anemometerData.windDirection = newval
            } else {
                print("Failed to decode wind direction as ASCII")
            }

        default:
            print("Unhandled Anemometer Characteristics")
        }
    }

    
    func updateGPSCharacteristicUI(_ uuid: CBUUID, _ value: Data ) {
        switch (uuid) {
        case GPSTransferService.tritonDateCharacteristicUUID :
            gpsData.date = String(data: value, encoding: .utf8) ?? "N/A"
            break
        case GPSTransferService.tritonTimeCharacteristicUUID :
            print("GPS DATA: \(value)\n" )
            gpsData.time = String(data: value, encoding: .utf8) ?? "N/A"
            gpsData.time = gpsData.time.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
            if updatingTime {
                updatingTime = false
                stopUpdatingTime()
            } 
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

