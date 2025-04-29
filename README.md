# Senior-Design-Sailboat-Nav-2025

```
Senior-Design-Sailboat-Nav-2025
│   README.md  
│
└───Anemometer
│   │   AneTest.py
│   │   WindDirection1.py
│   │   WindSpeed.txt
│   
└───GPS
│   │   GPSDbusTest.py
│   │   gps_dbus_test
│
└───HARDWARE-REPORT
│   │   README_Hardware.md
│   └───DATASHEETS
│       │   Aluminum_pole.pdf
│       │   DS-15901-Weather_Meter.pdf
│       │   FlangeSpecs.pdf
│       │   GPS-Module-Datasheet.pdf
│       │   OAK-D-S2_Datasheet.pdf
│       │   PowerBank_Main.pdf
│       │   PowerBank_Secondary.pdf
│       │   RJ11_schematic.pdf
│       │   Rubber_ring_specs.pdf
│       │   StereoPiV2Schematic.jpg
│       │   StereoPi_07292021_STPI2_SLM_01-2499177.pdf
│       │   SwivelSafetyHaspSpecs.pdf
│       │   Tectite Electrical Plastic Adapter Connector Conduit Fittings.pdf
│       │   adafruit-4-channel-adc-breakouts.pdf
│       │   cm4-datasheet.pdf
│       │   coupler_datasheet.pdf
│
└───LAUNCHER-SCRIPTS
│   │   oakd_launcher.sh
│   │   ...
│
└───OAK-D
│   │   MRS_Video.py
│   │   Triton.py
│   │   Waterline.py
│   └───models
│       │  ... 
│  
└───PREVIOUS-REPORTS
│   │   Customer Installation Report.pdf
│   │   Final Testing Report.docx
│   │   Final Testing Slides.pptx
│   │   ...
│
└───RPI-BLUETOOTH
│   │   bluetooth.py
│   │   README_Bluetooth.md
│   │   BluetoothInterfaceChart.jpeg
│
└───SOFTWARE-REPORT
│   │   README_Software.md
│
└───STEREOPI-BLUETOOTH
│   │   bluetooth.py
│   │   README_StereopiBluetooth.md
│
└───Triton
│   │   README_Triton.md
│   └───Triton
│       │  All_camera_10_points.swift
│       │  BluetoothService.swift
│       │  ContentView.swift
│       │  DataStructs.swift
│       │  ImageConversion.swift
│       │  info_tabs.swift
│       │  Info.plist
│       │  ServiceDefinitions.swift
│       │  TritonApp.swift
│
└───stereopi
│   │   7_2d_mapPROTO.py
│   │   Triton.py
│   └───calibration_data
│   │   │  ...
│   └───pairs
│       │  ...
```


This repo contains all of the relevant information for the Triton: a portable, multi-sensor system that provides useful information to the sailor via a mobile iOS application, including object sensing and visualization, GPS data, wind speed and direction, and speed over ground. The Triton's primary function being to assist sailors when docking or maneuvering through crowded areas, such as a busy port. The Triton consists of three separate sensing modules attached to the bow, starboard, and port areas of the boat. Each of these modules communicates via Bluetooth Low Energy. The data from each of these modules is continuously offloaded to the connected iOS device in real time, giving the operator the most up-to-date information about the current conditions.

**STEREOPIS (PERIPHERAL MODULES)**\
OS: Raspberry Pi Debain Bullseye 32-Bit Full Legacy (Released 10/22/2024)\
StereoPi Version: StereoPi V2 Slim\
Raspberry Pi Device: Compute Module 4, 1GB, Wireless (SC0691)

**RASPBERRY PI (CENTRAL MODULES)**\
OS: Raspberry Pi Debian Bookworm 64-Bit (Released 11/19/2024)\
Raspberry Pi Device: Raspberry Pi 3B



**COMMANDS, TIPS & TRICKS THAT CAME IN HANDY**
To activate virtual environment:\
source ./bin/activate

To get bluetooth working on Raspberry Pis:\
sudo systemctl start bluetooth
