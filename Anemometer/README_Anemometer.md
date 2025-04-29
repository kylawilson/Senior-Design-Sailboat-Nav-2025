**DEPENDENCIES**
- dbus-python 1.3.2
- gobject 0.1.0
- adafruit_ads1x15
- adafruit_blinka 8.56.0
- RPi.GPIO 0.7.1

**DEVICE REQUIREMENTS**
- Raspberry Pi 3B with Raspberry Pi OS Debian Bookworm 64-Bit
    
**OVERVIEW OF EACH SOFTWARE MODULE**\
*AneTest.py* - This file reads wind speed data from a GPIO pin connected to the anemometer. It counts pulses from the anemometer to calculate the wind speed in meters per second, then converts it to knots. The result is written to a text file (WindSpeed.txt) once per second.\ 
*WindDirection1.py* - This file reads wind direction data using an ADC connected over I2C. It calculates resistance values from voltage readings to determine wind direction based on predefined resistance ranges. The result is made available over a DBus service, allowing other applications to query the current wind direction. The file initializes the ADC, sets up and runs a D-Bus service, and continuously samples and averages multiple readings from the anemometer to improve accuracy.
