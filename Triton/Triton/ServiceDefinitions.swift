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

let tritonServiceUUID : String = "ec2ce16f-f774-4c1f-b3dd-a56b64bc9037" //custom service UUID
let tritonService : CBUUID = CBUUID(string: tritonServiceUUID)       //CBUUID for our custom service UUID
