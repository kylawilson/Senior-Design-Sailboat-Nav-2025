//
//  GPSBluetooth.swift
//  Triton
//
//  Created by Kyla Wilson on 11/18/24.
//

import Foundation

struct GPSData {
    var date: String = "Date"
    var time: String = "Time"
    var longitude: String = "Longitude"
    var longitudeInd: String = ""
    var latitude: String = "Latitude"
    var latitudeInd: String = ""
    var altitude: String = "Altitude"
    var COG: String = "COG"
    var speed: String = "Speed"
    var fix: String = "Fix"
}

struct AnemometerData {
    var windSpeed: String = "Wind Speed"
    var windDirection: String = "Wind Direction"
}


