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

let tritonServiceUUID : String = "de7f5b6d-79b3-4afa-82ed-ecf20c4d5" //custom service UUID
let tritonService : CBUUID = CBUUID(string: tritonServiceUUID)       //CBUUID for our custom service UUID
