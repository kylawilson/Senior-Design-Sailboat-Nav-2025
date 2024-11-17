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
    static let tritonServiceUUID1 = CBUUID(string: "ec2ce16f-f774-4c1f-b3dd-a56b64bc9037") //custom service UUID
    static let tritonCharacteristicUUID = CBUUID(string: "842c3d51-9599-4c9c-aa41-15a28cb48bce") //I think we need one for each function the device performs
}

