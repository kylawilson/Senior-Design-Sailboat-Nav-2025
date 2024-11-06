//
//  ContentView.swift
//  Triton
//
//  Created by Kyla Wilson on 10/30/24.
//

import SwiftUI

struct ContentView: View {
    
    var btService: BluetoothService = BluetoothService()
    
    var body: some View {
        VStack {
            Button(action: {
                btService.scanForPeripherals()
            }) {
                Text("Scan")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
