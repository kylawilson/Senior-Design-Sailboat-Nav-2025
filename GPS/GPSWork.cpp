#include <iostream>
#include <wiringPi.h>
#include <wiringSerial.h>
#include <unistd.h>
#include <fstream>
#include <string>
#include <sstream>
#include <iomanip>
#include <vector>

#define GPS_SERIAL_PORT "/dev/serial0" // UART port for Raspberry Pi

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
	if (fields[2] != "" && fields[3] != "" && fields[4] != "" && fields[5] != "" && fields[9] != ""){
	        std::string Latitude = fields[2];
	std::string latIndicator = fields[3];
        std::string Longitude = fields[4];
        std::string longIndicator = fields[5];
        std::string Altitude = fields[9]; // Value before the first 'M'
	}
    }	

        // Print or use the extracted values
        std::cout << "GGA Data:" << std::endl;
        std::cout << "  UTCtime: " << UTCtime << std::endl;
       if (Latitude != "" && latIndicator != "" && Longitude != "" &&  longIndicator != ""){
	std::cout << "  Latitude: " << Latitude << std::endl;
        std::cout << "  latIndicator: " << latIndicator << std::endl;
        std::cout << "  Longitude: " << Longitude << std::endl;
        std::cout << "  longIndicator: " << longIndicator << std::endl;
        std::cout << "  Altitude: " << Altitude << std::endl;
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
	if ((fields[7] != "" || fields[7] != "0.00") && (fields[8] != "" || fields[8])){
        std::string Speed = fields[7];
        std::string COG = fields[8];
	}
	if (fields[9] != "")
        std::string Date = fields[9];
    }	
	if (Speed != "0.00" && (COG != "" || COG != "0.00")){
        // Print or use the extracted values
        std::cout << "RMC Data:" << std::endl;
        std::cout << "  Speed: " << Speed << std::endl;
        std::cout << "  COG: " << COG << std::endl;
        std::cout << "  Date: " << Date << std::endl;
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

    // Open a file to save GPS data
    std::ofstream gps_file("gps_data1.txt", std::ios::app); // Append mode
    if (!gps_file.is_open()) {
        std::cerr << "Failed to open gps_data.txt for writing." << std::endl;
        return 1;
    }

    std::string gps_data;
    while (true) {
        // Read data from GPS
        while (serialDataAvail(serial_fd)) {
            char c = serialGetchar(serial_fd);
            gps_data += c;
	    //std::cout << c;
	    //gps_file << c << std::endl;
            // Check for end of a line (NMEA sentence)
            if (c == '\n') {
		gps_file << gps_data; //Saves Each line to the file?? (Hopefully)
       		if (gps_data.find("GGA") != std::string::npos) {
            		processGGA(gps_data);
       		} 
		if (gps_data.find("RMC") != std::string::npos) {
          		processRMC(gps_data);
		}
		// Clear buffer after processing 
		gps_data.clear();
    	    }
	}
	
	// Delay to prevent overwhelming the Pi with constant reads
	usleep(100000); //100ms
    }

    //Close the file and serial port
    gps_file.close();
    serialClose(serial_fd);
    return 0;

}
