//
//  ContentView.swift
//  Triton
//
//  Created by Kyla Wilson on 10/30/24.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    @ObservedObject var btService: BluetoothService = BluetoothService()
    
    var body: some View {
        VStack {
            Toggle("Scan", isOn: $btService.isScanning)
                .onChange(of: btService.isScanning) {
                    if btService.isScanning {
                        btService.scanForPeripherals()
                    } else {
                        // Stop scanning
                        btService.stopScanningForPeripherals()
                    }
                }

            .padding()
            HStack {
                //list the discovered peripherals
                List(btService.discoveredPeripherals, id: \.identifier) { peripheral in
                    Text(peripheral.name ?? peripheral.identifier.uuidString)
                    Button(action: {
                        btService.connectToPeripheral(peripheral: peripheral)
                    }) {
                        Text("Connect")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
        }
    }
}


#Preview {
    ContentView()
}
