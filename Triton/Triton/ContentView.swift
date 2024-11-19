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
                HStack {
                    Text("Connection State: \(btService.connectionState)")
                        .font(.body)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.top, 20)
                    Button(action: {
                        btService.scanForPeripherals() // Call the reconnection function
                    }) {
                        Text("Reconnect")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                                
                ScrollView {
                    VStack(spacing: 16) {
                        // Create a tile for each piece of data in the struct
                        //TileView(label: "Date", value: btService.gpsData.date)
                        TileView(label: "Time Since Startup", value: btService.gpsData.time)
                        TileView(label: "Longitude", value: btService.gpsData.longitude)
                        TileView(label: "Longitude Indicator", value: btService.gpsData.longitudeInd)
                        TileView(label: "Latitude", value: btService.gpsData.latitude)
                        TileView(label: "Latitude Indicator", value: btService.gpsData.latitudeInd)
                        TileView(label: "Altitude", value: btService.gpsData.altitude)
                        //TileView(label: "COG", value: btService.gpsData.COG)
                        //TileView(label: "Speed", value: btService.gpsData.speed)
                    }
                    .padding()  // Add some padding around the entire VStack
                }
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
