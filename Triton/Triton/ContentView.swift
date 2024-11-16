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
        NavigationView {
            VStack(spacing: 20) {
                // Scan toggle
                Toggle("Scan for Devices", isOn: $btService.isScanning)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding()
                    .onChange(of: btService.isScanning) { newValue in
                        if newValue {
                            btService.scanForPeripherals()
                        } else {
                            btService.stopScanningForPeripherals()
                        }
                    }
                
                // List of discovered peripherals
                if btService.discoveredPeripherals.isEmpty {
                    Text("No Triton found")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                } else {
                    List {
                        ForEach(btService.discoveredPeripherals, id: \.identifier) { peripheral in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(peripheral.name ?? "Unknown Device")
                                        .font(.headline)
                                    Text(peripheral.identifier.uuidString)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    btService.connectToPeripheral(peripheral: peripheral)
                                }) {
                                    Text("Connect")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Connect to Your Triton!")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
        }
    }
}



#Preview {
    ContentView()
}
