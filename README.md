# Senior-Design-Sailboat-Nav-2025

"The Engineering Addendum is quick-start documentation written to any future team that may continue
to work on your project. This is where you outline the gotchas of your project, types of things to look out
for, the current state of the project, etc. The purpose of README.md is to save any future team weeks
of detective work just to get to where you are today. Think back to what types of things you had wished
you knew earlier, doing future teams a favor by passing that knowledge along. "

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

**STEREOPIS (PERIPHERAL MODULES)**\
OS: Raspberry Pi Debain Bullseye 32-Bit Full Legacy (Released 10/22/2024)\
StereoPi Version: StereoPi V2 Slim\
Raspberry Pi Device: Compute Module 4, 1GB, Wireless (SC0691)

**RASPBERRY PI (CENTRAL MODULES)**\
OS: Raspberry Pi Debian Bookworm 64-Bit (Released 11/19/2024)\
Raspberry Pi Device: Raspberry Pi 3B

To activate virtual environment:\
source ./bin/activate

To get bluetooth working on Raspberry Pis:\
sudo systemctl start bluetooth
