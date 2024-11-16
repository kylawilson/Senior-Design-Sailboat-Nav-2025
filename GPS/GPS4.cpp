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

// Function to split a string by a delimiter
std::vector<std::string> split(const std::string &str, char delimiter) {
    std::vector<std::string> tokens;
    std::stringstream ss(str);
    std::string token;
    while (std::getline(ss, token, delimiter)) {
        tokens.push_back(token);
    }
    return tokens;
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
    std::ofstream gps_file("gps_data.txt", std::ios::app); // Append mode
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
	    std::cout << c;
	    gps_file << c << std::endl;
            // Check for end of a line (NMEA sentence)
            if (c == '\n') {
                if (gps_data.find("$GPRMC") != std::string::npos) {
                    // Process GPRMC sentence for time, latitude, longitude
                    auto tokens = split(gps_data, ',');
                    if (tokens.size() >= 10) {
                        std::string time = tokens[1];
                        std::string latitude = tokens[3];
                        std::string lat_direction = tokens[4];
                        std::string longitude = tokens[5];
                        std::string lon_direction = tokens[6];

                        // Parse time in HHMMSS format
                        std::string hour = time.substr(0, 2);
                        std::string minute = time.substr(2, 2);
                        std::string second = time.substr(4, 2);

                        std::cout << "Time (UTC): " << hour << ":" << minute << ":" << second << std::endl;
                        std::cout << "Latitude: " << latitude << " " << lat_direction << std::endl;
                        std::cout << "Longitude: " << longitude << " " << lon_direction << std::endl;

                        // Write to file
                        gps_file << "Time (UTC): " << hour << ":" << minute << ":" << second << "\n";
                        gps_file << "Latitude: " << latitude << " " << lat_direction << "\n";
                        gps_file << "Longitude: " << longitude << " " << lon_direction << "\n";
//			gps_file << "Tagline: " << c <<" ";
                    }
                } else if (gps_data.find("$GPGGA") != std::string::npos) {
                    // Process GPGGA sentence for altitude and satellite count
                    auto tokens = split(gps_data, ',');
                    if (tokens.size() >= 10) {
                        std::string altitude = tokens[9];
                        std::string satellites = tokens[7];

                        std::cout << "Altitude: " << altitude << " meters" << std::endl;
                        std::cout << "Satellites: " << satellites << std::endl;

                        // Write to file
                        gps_file << "Altitude: " << altitude << " meters\n";
                        gps_file << "Satellites: " << satellites << "\n";
                    }
                }

                // Clear buffer after processing
                gps_data.clear();
            }
        }
	//gps_file << "Hi I made it" << std::endl;

        // Delay to prevent overwhelming the Pi with constant reads
        usleep(100000); // 100ms
    }

    // Close the file and serial port
    gps_file.close();
    serialClose(serial_fd);
    return 0;
}
