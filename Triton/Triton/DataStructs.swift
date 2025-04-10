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

func convertUTCtoEST(utcTime: String) -> String? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HHmmss.SSS"
    guard let utcDate = dateFormatter.date(from: utcTime) else {
        print("Invalid UTC time format")
        return nil
    }
    
    let estTimeZone = TimeZone(identifier: "America/New_York")!
    let estDate = utcDate.addingTimeInterval(TimeInterval(-5 * 60 * 60)) // Subtract 5 hours
    
    dateFormatter.timeZone = estTimeZone
    let estTime = dateFormatter.string(from: estDate)
    
    return estTime
}
