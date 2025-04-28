**DEPENDENCIES**
- dbus-python 1.3.2
- gobject 0.1.0
- ../stereopi/7_2d_map_PROTO.py

**DEVICE REQUIREMENTS**
- StereoPi V2 Slim with a Raspberry Pi Compute Module 4 running Raspberry Pi Debian Bookworm 64-Bit
- Two Raspberry Pi Cameras
    
**OVERVIEW OF EACH SOFTWARE MODULE**\
bluetooth.py - This file enables Bluetooth Low Energy communication with the iOS device (see the ../Triton folder). It registers the GATT server, advertisements, services, and characteristics. This file also collects information from the stereo cameras, reading from tempmax_log.txt in the ../stereopi folder to collect these values once every second.

