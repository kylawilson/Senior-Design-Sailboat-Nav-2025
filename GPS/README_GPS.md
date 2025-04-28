**DEPENDENCIES**
- WiringPi
- <dbus/dbus.h>

**DEVICE REQUIREMENTS**
- Raspberry Pi 3B with Raspberry Pi OS Debian Bookworm 64-Bit
    
**OVERVIEW OF EACH SOFTWARE MODULE**\
*GPSDbusTest.cpp* - This file interfaces with the Adafruit Flora GPS module over a serial connection. It processes NMEA sentences (GGA, RMC, PGTOP) to extract GPS data such as latitude, longitude, speed, and course over ground. The data is then made available via DBus. The service listens for requests for GPS data and responds with the latest parsed information. The code  continuously reads from the GPS and updates the D-Bus service.\ 
*gps_dbus_test* - This is the executable version of GPSDbusTest.cpp
