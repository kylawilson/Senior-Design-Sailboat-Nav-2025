#include <iostream>
#include <wiringSerial.h>
#include <unistd.h>
#include <string>
#include <sstream>
#include <vector>
#include <sys/time.h>
#include <dbus/dbus.h>

#define GPS_SERIAL_PORT "/dev/serial0"

std::vector<std::string> latestGGAData;
std::vector<std::string> latestRMCData;

long getCurrentTimeInMilliseconds() {
    struct timeval tv;
    gettimeofday(&tv, nullptr);
    return tv.tv_sec * 1000 + tv.tv_usec / 1000;
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
            std::string("Longitude: ") + (fields[5] == "W" ? "-" : "") + fields[4],
            "longIndicator: " + fields[5],
            "Altitude: " + fields[9]
        };
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
    }
}

DBusHandlerResult handle_get_gps_data(DBusConnection* conn, DBusMessage* msg, void* user_data) {
    if (dbus_message_is_method_call(msg, "com.example.GPSService", "GetGPSData")) {
        DBusMessage* reply = dbus_message_new_method_return(msg);
        if (!reply) {
            std::cerr << "Out of memory!\n";
            return DBUS_HANDLER_RESULT_NEED_MEMORY;
        }

        std::ostringstream dataStream;
        dataStream << "[GGA] ";
        for (const auto& entry : latestGGAData) {
            dataStream << entry << ", ";
        }

        dataStream << " [RMC] ";
        for (const auto& entry : latestRMCData) {
            dataStream << entry << ", ";
        }

        std::string gpsDataStr = dataStream.str();
        const char* gps_data = gpsDataStr.c_str();

        dbus_message_append_args(reply, DBUS_TYPE_STRING, &gps_data, DBUS_TYPE_INVALID);
        dbus_connection_send(conn, reply, nullptr);
        dbus_connection_flush(conn);
        dbus_message_unref(reply);

        return DBUS_HANDLER_RESULT_HANDLED;
    }
    return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}

int main() {
    DBusConnection* conn;
    DBusError err;

    dbus_error_init(&err);
    conn = dbus_bus_get(DBUS_BUS_SESSION, &err);
    if (dbus_error_is_set(&err)) {
        std::cerr << "Failed to connect to D-Bus: " << err.message << std::endl;
        dbus_error_free(&err);
        return 1;
    }

    int ret = dbus_bus_request_name(conn, "com.example.GPSService", DBUS_NAME_FLAG_REPLACE_EXISTING, &err);
    if (dbus_error_is_set(&err)) {
        std::cerr << "Failed to request name: " << err.message << std::endl;
        dbus_error_free(&err);
        return 1;
    }

    dbus_connection_add_filter(conn, handle_get_gps_data, nullptr, nullptr);

    int fd = serialOpen(GPS_SERIAL_PORT, 9600);
    if (fd < 0) {
        std::cerr << "Unable to open serial device." << std::endl;
        return 1;
    }

    // Main loop
    while (true) {
        while (serialDataAvail(fd)) {
            char c = serialGetchar(fd);
            static std::string line;
            if (c == '\n') {
                if (line.find("$GPGGA") == 0) {
                    processGGA(line);
                } else if (line.find("$GPRMC") == 0) {
                    processRMC(line);
                }
                line.clear();
            } else if (c != '\r') {
                line += c;
            }
        }

        dbus_connection_read_write(conn, 0);
        dbus_connection_dispatch(conn);

        usleep(10000); // 10ms sleep to prevent 100% CPU
    }

    serialClose(fd);
    dbus_connection_unref(conn);
    return 0;
}