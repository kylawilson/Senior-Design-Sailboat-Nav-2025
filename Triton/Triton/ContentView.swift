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
    let circleCount = 6
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                MovingCirclesView()
                    .padding()
                HStack(alignment: .top) {
                    VStack {
                        Button(action: {
                            btService.disconnect()
                        }) {
                            Text("Disconnect")
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background((btService.connectionState != .connected) ? Color.gray : Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .disabled(btService.connectionState != .connected)
                        .opacity((btService.connectionState != .connected) ? 0.6 : 1.0)
                        Button(action: {
                            btService.reconnect()
                        }) {
                            Text("Connect")
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background((btService.connectionState != .disconnected) ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .disabled(btService.connectionState != .disconnected)
                        .opacity((btService.connectionState != .disconnected) ? 0.6 : 1.0)
                    }
                    .frame(maxHeight: .infinity)
                    Text("\(btService.connectionState)")
                        .font(.body)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                .fixedSize(horizontal: false, vertical: true)
                
                createImage(btService.finalPhotoData)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Create a tile for each piece of data in the struct
                        //TileView(label: "Date", value: btService.gpsData.date)
                        TileView(label: "UTC Time", value: btService.gpsData.time)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                //.frame(maxWidth: .infinity)
                //.frame(width: 150, alignment: .leading) // Fixed width for the labels
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


//I think keep this in BluetoothService
func createImage(_ value: Data) -> Image {
    let liveFeed: UIImage = UIImage(data: value) ?? UIImage()
    return Image(uiImage: liveFeed)
}





#Preview {
    ContentView()
}
