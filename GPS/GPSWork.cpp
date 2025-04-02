#include <iostream>
#include <wiringPi.h>
#include <wiringSerial.h>
#include <unistd.h>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <sys/time.h>
//#include <chrono>

#define GPS_SERIAL_PORT "/dev/serial0" // UART port for Raspberry Pi

std::ofstream gps_file; // Output file stream for GPS data

//test dbus
//DBusConnection * dbus_conn = nullptr;
//DBusError dbus_error;
//
//// Initialize D-Bus error
//::dbus_error_init(&dbus_error);
//
//// Connect to D-Bus
//dbus_conn = ::dbus_bus_get(DBUS_BUS_SYSTEM, &dbus_error);
//std::cout << "Connected to D-Bus as \"" << ::dbus_bus_get_unique_name(dbus_conn) << "\"." << std::endl;

//end dbus test

long getCurrentTimeInMilliseconds() {
    struct timeval tv;
    gettimeofday(&tv, nullptr);
    return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

void processGGA(const std::string& line) {
    std::stringstream ss(line);
    std::string token;
    std::vector<std::string> fields;

    // Split the line into fields based on commas
    while (std::getline(ss, token, ',')) {
        fields.push_back(token);
    }

    // Ensure the line contains at least the required number of fields
    if (fields.size() >= 10) {
        std::string UTCtime = fields[1];
        std::string Latitude = fields[2];
        std::string latIndicator = fields[3];
        std::string Longitude = fields[4];
        std::string longIndicator = fields[5];
        std::string Altitude = fields[9]; // Value before the first 'M'

        // Print or use the extracted values
        std::cout << "GGA Data:" << std::endl;
        std::cout << "  UTCtime: " << UTCtime << std::endl;
        gps_file << "UTCtime: " << UTCtime << std::endl;

        if (!Latitude.empty() && !latIndicator.empty() && !Longitude.empty() && !longIndicator.empty()) {
            std::cout << "  Latitude: " << Latitude << std::endl;
            gps_file << "Latitude: " << Latitude << std::endl;
            std::cout << "  latIndicator: " << latIndicator << std::endl;
            gps_file << "latIndicator: " << latIndicator << std::endl;
            if (longIndicator == "W"){
                std::cout << "  Longitude: " << "-" << Longitude << std::endl;
                gps_file << "Longitude: " << "-" << Longitude << std::endl;
            } else{
                std::cout << "  Longitude: " << Longitude << std::endl;
                gps_file << "Longitude: " << Longitude << std::endl;
            }
            std::cout << "  longIndicator: " << longIndicator << std::endl;
            gps_file << "longIndicator: " << longIndicator << std::endl;
            std::cout << "  Altitude: " << Altitude << std::endl;
            gps_file << "Altitude: " << Altitude << std::endl;
        } else {
            std::cout << "  Latitude: " << "" << std::endl;
            gps_file << "Latitude: " << "" << std::endl;
            std::cout << "  latIndicator: " << "" << std::endl;
            gps_file << "latIndicator: " << "" << std::endl;
            std::cout << "  Longitude: " << "" << std::endl;
            gps_file << "Longitude: " << "" << std::endl;
            std::cout << "  longIndicator: " << "" << std::endl;
            gps_file << "longIndicator: " << "" << std::endl;
            std::cout << "  Altitude: " << "" << std::endl;
            gps_file << "Altitude: " << "" << std::endl;
        }
    } else {
        std::cerr << "Invalid GGA line: " << line << std::endl;
    }
}

void processRMC(const std::string& line) {
    std::stringstream ss(line);
    std::string token;
    std::vector<std::string> fields;

    // Split the line into fields based on commas
    while (std::getline(ss, token, ',')) {
        fields.push_back(token);
    }

    // Ensure the line contains at least the required number of fields
    if (fields.size() >= 9) {
        std::string Speed = fields[7];
        std::string COG = fields[8];
        std::string Date = fields[9];
        std::string formatted_date = Date.substr(0, 2) + Date.substr(2, 2) + Date.substr(4, 2);


        if (Speed != "0.00" && (!COG.empty() && COG != "0.00")) {
            // Print or use the extracted values
            std::cout << "RMC Data:" << std::endl;
            std::cout << "  Speed: " << Speed << std::endl;
            std::cout << "  COG: " << COG << std::endl;
            gps_file << "Speed: "  << Speed << std::endl;
            gps_file << "COG: " << COG << std::endl;
        } else {
            std::cout << "  Speed: " << "" << std::endl;
            std::cout << "  COG: " << "" << std::endl;
            gps_file << "Speed: "  << "" << std::endl;
            gps_file << "COG: " << "" << std::endl;
        }

        if (!Date.empty()) {
            std::cout << "  Date: " << formatted_date << std::endl;
            gps_file << "Date: " << formatted_date << std::endl;
        }
    } else {
        std::cerr << "Invalid RMC line: " << line << std::endl;
    }
}


int main() {
    // Initialize WiringPi
    if (wiringPiSetup() == -1) {
        std::cerr << "WiringPi setup failed." << std::endl;
        return 1;
    }

    // Open the GPS serial port
    int serial_fd = serialOpen(GPS_SERIAL_PORT, 9600);
    if (serial_fd < 0) {
        std::cerr << "Unable to open GPS serial port." << std::endl;
        return 1;
    }

    // Open the gps_data.txt file for appending data
    gps_file.open("gps_data1.txt", std::ios::app);
    if (!gps_file.is_open()) {
        std::cerr << "Failed to open gps_data.txt for writing." << std::endl;
        return 1;
    }

    std::string gps_data;

    while (true) {
        // Truncate the file and reopen it for appending every 100ms
        gps_file.close();
        gps_file.open("gps_data1.txt", std::ios::trunc);  // Clear the file
        if (!gps_file.is_open()) {
            std::cerr << "Failed to open gps_data.txt for writing." << std::endl;
            return 1;
        }

        // Collect GPS data for 100 milliseconds
        gps_data.clear();
        long start_time = getCurrentTimeInMilliseconds();
        while (getCurrentTimeInMilliseconds() - start_time < 100) {
            if (serialDataAvail(serial_fd)) {
                char c = serialGetchar(serial_fd);
                gps_data += c;

                // Check for end of a line (NMEA sentence)
                if (c == '\n') {
                    //std::cout << gps_data << std::endl;
                    if (gps_data.find("GGA") != std::string::npos) {
                        processGGA(gps_data);
                    } 
                    // if (gps_data.find("RMC") != std::string::npos) {
                    //     processRMC(gps_data);
                    // }
                    gps_data.clear();  // Clear after processing the data
                }
            }
        }

        // Sleep to prevent overwhelming the system with continuous file writes
        usleep(1000000);  // 1000ms
    }

    // Close the file and serial port when the program ends
    gps_file.close();
    serialClose(serial_fd);

    return 0;
}