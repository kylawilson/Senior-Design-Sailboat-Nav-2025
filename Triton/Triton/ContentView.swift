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
                
//                Toggle("Scan for Devices", isOn: $btService.isScanning)
//                    .toggleStyle(SwitchToggleStyle(tint: .blue))
//                    .padding()
//                    .onChange(of: btService.isScanning) { newValue in
//                        if newValue {
//                            btService.scanForPeripherals()
//                        } else {
//                            btService.stopScanningForPeripherals()
//                        }
//                    }
                
                ScrollView {
                            VStack(spacing: 16) {
                                // Create a tile for each piece of data in the struct
                                TileView(label: "Date", value: btService.gpsData.date)
                                TileView(label: "Time Since Startup", value: btService.gpsData.time)
                                TileView(label: "Longitude", value: btService.gpsData.longitude)
                                TileView(label: "Longitude Indicator", value: btService.gpsData.longitudeInd)
                                TileView(label: "Latitude", value: btService.gpsData.latitude)
                                TileView(label: "Latitude Indicator", value: btService.gpsData.latitudeInd)
                                TileView(label: "Altitude", value: btService.gpsData.altitude)
                                TileView(label: "COG", value: btService.gpsData.COG)
                                TileView(label: "Speed", value: btService.gpsData.speed)
                            }
                            .padding()  // Add some padding around the entire VStack
                        }
                
                // List of discovered peripherals
//                if btService.discoveredPeripherals.isEmpty {
//                    Text("No Triton found")
//                        .foregroundColor(.gray)
//                        .italic()
//                        .padding()
//                } else {
//                    List {
//                        ForEach(btService.discoveredPeripherals, id: \.identifier) { peripheral in
//                            HStack {
//                                VStack(alignment: .leading) {
//                                    Text(peripheral.name ?? "Unknown Device")
//                                        .font(.headline)
//                                    Text(peripheral.identifier.uuidString)
//                                        .font(.subheadline)
//                                        .foregroundColor(.gray)
//                                }
//                                
//                                Spacer()
//                                
//                                Button(action: {
//                                    btService.connectToPeripheral(peripheral: peripheral)
//                                }) {
//                                    Text("Connect")
//                                        .padding(.horizontal, 12)
//                                        .padding(.vertical, 6)
//                                        .background(Color.blue)
//                                        .foregroundColor(.white)
//                                        .cornerRadius(8)
//                                }
//                            }
//                            .padding(.vertical, 8)
//                        }
//                    }
//                }
//                
//                Spacer()
            }
            .navigationTitle("Connect to Your Triton!")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
        }
    }
}

struct TileView: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .frame(width: 120, alignment: .leading) // Fixed width for the labels
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)  // Use secondary color for the value
        }
        .padding()
        .background(Color.blue.opacity(0.1)) // Light background for each tile
        .cornerRadius(8)  // Rounded corners
        .shadow(radius: 5) // Optional: Add a shadow effect for each tile
    }
}



#Preview {
    ContentView()
}
