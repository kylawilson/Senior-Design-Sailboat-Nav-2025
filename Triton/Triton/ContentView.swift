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
            List(btService.discoveredPeripherals, id: \.identifier) { peripheral in
                Text(peripheral.name ?? "Unnamed Peripheral")
            }
            .toolbar{ EditButton() }
            .padding()
        }
    }
}


#Preview {
    var btService = BluetoothService()
    ContentView(btService: btService)
}
