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
            Button(action: {
                btService.scanForPeripherals()
            }) {
                Text("Scan")
            }
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
