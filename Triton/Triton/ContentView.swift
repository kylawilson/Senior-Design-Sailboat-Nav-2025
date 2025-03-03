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
            GeometryReader { geometry in
                VStack(spacing: 10) {
                    Text("Connect to Your Triton!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Bluetooth Status
                    Text("\(btService.connectionState)")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: geometry.size.width * 0.9)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    
                    // Bluetooth Control Buttons
                    HStack(spacing: 10) {
                        Button(action: { btService.disconnect() }) {
                            Text("Disconnect")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(btService.connectionState != .connected ? Color.gray : Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(btService.connectionState != .connected)
                        .opacity(btService.connectionState != .connected ? 0.6 : 1.0)
                        
                        Button(action: { btService.reconnect() }) {
                            Text("Connect")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(btService.connectionState != .disconnected ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(btService.connectionState != .disconnected)
                        .opacity(btService.connectionState != .disconnected ? 0.6 : 1.0)
                    }
                    .frame(maxWidth: geometry.size.width * 0.9)
                    VStack(spacing: 10) {
                        NavigationLink(destination: MovingCirclesPage()) {
                            PreviewButton(label: "Rendering", preview: MovingCirclesPreview())
                        }
                        NavigationLink(destination: ImageViewPage(btService: btService)) {
                            PreviewButton(label: "Live View", preview: ImagePreview(btService: btService))
                        }
                        NavigationLink(destination: RawDataViewPage(btService: btService)) {
                            PreviewButton(label: "Raw Data", preview: ImagePreview(btService: btService))
                        }
                    }
                    .frame(maxWidth: geometry.size.width * 0.9)
                    //ble data
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        TileView(label: "UTC Time", value: btService.gpsData.time)
                        TileView(label: "Longitude", value: btService.gpsData.longitude+btService.gpsData.longitudeInd)
                        TileView(label: "Latitude", value: btService.gpsData.latitude+btService.gpsData.latitudeInd)
                        TileView(label: "Altitude", value: btService.gpsData.altitude)
                        TileView(label: "Wind Speed", value: btService.anemometerData.windSpeed)
                        TileView(label: "Wind Direction", value: btService.anemometerData.windDirection)
                        TileView(label: "COG", value: btService.gpsData.COG)
                        TileView(label: "Speed", value: btService.gpsData.speed)
                        
                        
                    }
                    .frame(maxWidth: geometry.size.width * 0.9)
                    TileView(label: "Date", value: btService.gpsData.date)
                    .frame(maxWidth: geometry.size.width * 0.9)
                    
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .navigationTitle("Triton Control")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// TileView with reduced padding
struct TileView: View {
    var label: String
    var value: String
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
}

// Moving Circles Page
struct MovingCirclesPage: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GridView(rows: 10, columns: 10)
                MovingCirclesView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .edgesIgnoringSafeArea(.all)
            Spacer()
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ImagePreview: View {
    @ObservedObject var btService: BluetoothService
    
    var body: some View {
        if let uiImage = readImage(finalPhotoData: btService.finalPhotoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
        } else {
            Color.blue.opacity(0.3)
                .frame(width: 50, height: 50)
        }
    }
}

// Image View Page
struct ImageViewPage: View {
    @ObservedObject var btService: BluetoothService
    
    var body: some View {
        VStack {
            if let uiImage = readImage(finalPhotoData: btService.finalPhotoData) {
                ImageView(image: uiImage)
            } else {
                Text("Image not found")
            }
            Spacer()
        }
        .navigationTitle("Live View")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MovingCirclesPreview: View {
    var body: some View {
            MovingCirclesPage()
                .scaleEffect(0.1)  // Shrink the entire page
                .frame(width: 80, height: 50)  // Limit its visible size
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1))
    }
}


struct PreviewButton<Content: View>: View {
    let label: String
    let preview: Content?
    
    var body: some View {
        HStack {
            preview
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            Text(label)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(10)
    }
}

struct RawDataViewPage: View {
    @ObservedObject var btService: BluetoothService
    
    var body: some View {
        VStack {
            Text("Raw Data")
            Spacer()
        }
        .navigationTitle("Raw Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
