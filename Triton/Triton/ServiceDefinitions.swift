//
//  ServiceDefinitions.swift
//  Triton
//
//  Created by Kyla Wilson on 10/30/24.
//

import Foundation
import CoreBluetooth

enum ConnectionStatus {
    case connected
    case disconnected
    case connecting
    case disconnecting
    case scanning
    case error
}

struct TransferService {
    //may need to add more service IDs - one for each device we connect to
    
    static let tritonAdvertisingServiceUUID = CBUUID(string: "A3A3") //advertisement UUID
    static let tritonGPSServiceUUID = CBUUID(string: "ec2ce16f-f774-4c1f-b3dd-a56b64bc9037") //custom service UUID for GPS
    static let tritonLongitudeCharacteristicUUID = CBUUID(string: "842c3d51-9599-4c9c-aa41-15a28cb48bce") //I think we need one for each function the device performs
    static let tritonLongitudeIndicatorCharacteristicUUID = CBUUID(string: "156a777b-a6b7-4a8c-b9a5-8e674db49320") //I think we need one for each function the device performs
    static let tritonLatitudeCharacteristicUUID = CBUUID(string: "cc29cd0d-5a2a-43c6-bd68-3aea185c8605") //I think we need one for each function the device performs
    static let tritonLatitudeIndicatorCharacteristicUUID = CBUUID(string: "67fd8c36-b6f0-48e6-a672-03f0986fbca7") //I think we need one for each function the device performs
    static let tritonTimeCharacteristicUUID = CBUUID(string: "70685f3a-dc84-4654-a31a-a3b87fb3817d") //I think we need one for each function the device performs
    static let tritonAltitudeCharacteristicUUID = CBUUID(string: "b189e5f8-0217-47ad-b29e-35dc95386c87") //I think we need one for each function the device performs
    static let tritonSpeedCharacteristicUUID = CBUUID(string: "d8d76975-9d5d-41d2-b9d2-c9b861bbd80b") //I think we need one for each function the device performs
    static let tritonCOGCharacteristicUUID = CBUUID(string: "e20c75dc-8dc5-4ecf-83bb-b87bc26963b4") //I think we need one for each function the device performs
    static let tritonDateCharacteristicUUID = CBUUID(string: "0892b3f5-60d6-4d52-97f2-e7fb187d7253") //I think we need one for each function the device performs
}

