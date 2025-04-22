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
    static let tritonAdvertisingServiceUUID = CBUUID(string: "A3A3") //advertisement UUID
    static let stereoPi1AdvertisingServiceUUID = CBUUID(string: "A2A2")
    static let stereoPi2AdvertisingServiceUUID = CBUUID(string: "A4A4")
}

struct GPSTransferService {
    //may need to add more service IDs - one for each device we connect to
    static let tritonGPSServiceUUID = CBUUID(string: "ec2ce16f-f774-4c1f-b3dd-a56b64bc9037") //custom service UUID for GPS
    static let tritonLongitudeCharacteristicUUID = CBUUID(string: "842c3d51-9599-4c9c-aa41-15a28cb48bce")
    static let tritonLongitudeIndicatorCharacteristicUUID = CBUUID(string: "156a777b-a6b7-4a8c-b9a5-8e674db49320")
    static let tritonLatitudeCharacteristicUUID = CBUUID(string: "cc29cd0d-5a2a-43c6-bd68-3aea185c8605")
    static let tritonLatitudeIndicatorCharacteristicUUID = CBUUID(string: "67fd8c36-b6f0-48e6-a672-03f0986fbca7")
    static let tritonTimeCharacteristicUUID = CBUUID(string: "70685f3a-dc84-4654-a31a-a3b87fb3817d")
    static let tritonAltitudeCharacteristicUUID = CBUUID(string: "b189e5f8-0217-47ad-b29e-35dc95386c87")
    static let tritonSpeedCharacteristicUUID = CBUUID(string: "d8d76975-9d5d-41d2-b9d2-c9b861bbd80b")
    static let tritonCOGCharacteristicUUID = CBUUID(string: "e20c75dc-8dc5-4ecf-83bb-b87bc26963b4")
    static let tritonDateCharacteristicUUID = CBUUID(string: "0892b3f5-60d6-4d52-97f2-e7fb187d7253")
}

//used to receive Photos from the oak-d
struct PhotoTransferService {
    static let tritonPhotoServiceUUID = CBUUID(string: "064540d8-df60-4b60-a50f-780b7bd7f080")
    static let tritonPhotoCharacteristicUUID = CBUUID(string: "064540d8-df60-4b60-a50f-780b7bd7f081")
}

//used to receive wind speed and direction from RPi
struct AnemometerTransferService {
    static let tritonAnemometerServiceUUID = CBUUID(string: "45653417-53c1-4e4c-9745-f2a0b5d0be80")
    static let tritonWindSpeedCharacteristicUUID = CBUUID(string: "45653417-53c1-4e4c-9745-f2a0b5d0be81")
    static let tritonWindDirectionCharacteristicUUID = CBUUID(string: "45653417-53c1-4e4c-9745-f2a0b5d0be82")
}

//used to receive coordinates
//might have to switch this up for new rendering idea
struct RenderingTransferService {
    static let tritonRenderingServiceUUID = CBUUID(string: "8c94727b-79cc-45d6-a31f-9a49391bb590")
    static let tritonRenderingDepthCharacteristicUUID = CBUUID(string: "8c94727b-79cc-45d6-a31f-9a49391bb591") //Depth
    static let tritonRenderingObjectCharacteristicUUID = CBUUID(string: "8c94727b-79cc-45d6-a31f-9a49391bb592") //Objects
}

//used to receive depth from serialpis
//array of depths?
struct StereoPiTransferService {
    static let tritonStereoPiServiceUUID = CBUUID(string: "36523c64-9a13-4742-89d8-91c9db2374c0")
    static let tritonStereoPiDepthCharacteristicUUID = CBUUID(string: "36523c64-9a13-4742-89d8-91c9db2374c1")
}



