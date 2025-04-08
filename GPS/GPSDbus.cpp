#include <iostream>
#include <wiringPi.h>
#include <wiringSerial.h>
#include <unistd.h>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <sys/time.h>
#include <dbus/dbus.h>

#define GPS_SERIAL_PORT "/dev/serial0" // UART port for Raspberry Pi

std::ofstream gps_file; // Output file stream for GPS data

// Global storage for latest GPS data
std::vector<std::string> latestGGAData;
std::vector<std::string> latestRMCData;

// DBus connection
DBusConnection* dbus_conn = nullptr;

long getCurrentTimeInMilliseconds() {
    struct timeval tv;
    gettimeofday(&tv, nullptr);
    return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

void sendGpsDataOverDBus(DBusConnection* conn, const std::vector<std::string>& gpsData) {
    DBusMessage* msg;
    DBusMessageIter args, arrayIter;

    msg = dbus_message_new_signal("/com/example/GPSService",  // object path
                                  "com.example.GPSService",   // interface
                                  "NewGPSData");              // signal name

    if (!msg) {
        std::cerr << "Message Null\n";
        return;
    }

    dbus_message_iter_init_append(msg, &args);
    if (!dbus_message_iter_open_container(&args, DBUS_TYPE_ARRAY, "s", &arrayIter)) {
        std::cerr << "Out of memory (container)\n";
        return;
    }

    for (const std::string& item : gpsData) {
        const char* cstr = item.c_str();
        if (!dbus_message_iter_append_basic(&arrayIter, DBUS_TYPE_STRING, &cstr)) {
            std::cerr << "Out of memory (append)\n";
            return;
        }
    }

    dbus_message_iter_close_container(&args, &arrayIter);
    dbus_connection_send(conn, msg, nullptr);
    dbus_connection_flush(conn);
    dbus_message_unref(msg);
}

void processGGA(const std::string& line) {
    std::stringstream ss(line);
    std::string token;
    std::vector<std::string> fields;

    while (std::getline(ss, token, ',')) {
        fields.push_back(token);
    }

    if (fields.size() >= 10) {
        latestGGAData = {
            "UTCtime: " + fields[1],
            "Latitude: " + fields[2],
            "latIndicator: " + fields[3],
            "Longitude: " + (fields[5] == "W" ? "-" : "") + fields[4],
            "longIndicator: " + fields[5],
            "Altitude: " + fields[9]
        };

        // Also write to file
        for (const auto& field : latestGGAData) {
            gps_file << field << std::endl;
        }
    } else {
        std::cerr << "Invalid GGA line: " << line << std::endl;
    }
}

void processRMC(const std::string& line) {
    std::stringstream ss(line);
    std::string token;
    std::vector<std::string> fields;

    while (std::getline(ss, token, ',')) {
        fields.push_back(token);
    }

    if (fields.size() >= 10) {
        std::string formatted_date = fields[9].substr(0, 2) + fields[9].substr(2, 2) + fields[9].substr(4, 2);
        latestRMCData = {
            "Speed: " + fields[7],
            "COG: " + fields[8],
            "Date: " + formatted_date
        };

        for (const auto& field : latestRMCData) {
            gps_file << field << std::endl;
        }
    } else {
        std::cerr << "Invalid RMC line: " << line << std::endl;
    }
}

int main() {
    // Init WiringPi
    if (wiringPiSetup() == -1) {
        std::cerr << "WiringPi setup failed." << std::endl;
        return 1;
    }

    // Open serial port
    int serial_fd = serialOpen(GPS_SERIAL_PORT, 9600);
    if (serial_fd < 0) {
        std::cerr << "Unable to open GPS serial port." << std::endl;
        return 1;
    }

    // Open file
    gps_file.open("gps_data1.txt", std::ios::app);
    if (!gps_file.is_open()) {
        std::cerr << "Failed to open gps_data1.txt." << std::endl;
        return 1;
    }

    // Init D-Bus
    DBusError dbus_error;
    dbus_error_init(&dbus_error);
    dbus_conn = dbus_bus_get(DBUS_BUS_SESSION, &dbus_error);
    if (dbus_error_is_set(&dbus_error)) {
        std::cerr << "D-Bus Error: " << dbus_error.message << std::endl;
        dbus_error_free(&dbus_error);
        return 1;
    }

    std::string gps_data;

    while (true) {
        gps_file.close();
        gps_file.open("gps_data1.txt", std::ios::trunc); // Clear file

        gps_data.clear();
        long start_time = getCurrentTimeInMilliseconds();
        while (getCurrentTimeInMilliseconds() - start_time < 100) {
            if (serialDataAvail(serial_fd)) {
                char c = serialGetchar(serial_fd);
                gps_data += c;

                if (c == '\n') {
                    if (gps_data.find("GGA") != std::string::npos) {
                        processGGA(gps_data);
                    } else if (gps_data.find("RMC") != std::string::npos) {
                        processRMC(gps_data);
                    }

                    // Emit D-Bus signal if both GGA and RMC are available
                    if (!latestGGAData.empty() && !latestRMCData.empty()) {
                        std::vector<std::string> combined = latestGGAData;
                        combined.insert(combined.end(), latestRMCData.begin(), latestRMCData.end());
                        sendGpsDataOverDBus(dbus_conn, combined);
                    }

                    gps_data.clear();
                }
            }
        }

        usleep(1000000); // 1000ms
    }

    gps_file.close();
    serialClose(serial_fd);

    return 0;
}

