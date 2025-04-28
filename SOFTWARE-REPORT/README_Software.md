insert readme contents here
"Source code and executables along with the
accompanying documentation on how to
setup/compile your project and transfer code to
a target platform.

An overview of each software module
• A flow chart indicating the dependencies between these functions. For instance, if you have a
main.py and LCD.py, you need to show that LCD.py is a module used by main.py.
• Dev/build tool information: Package name and version info. For example, OpenCV 4.0.3 with
Python 3.8.1, using CUDA Toolbox 10.0 and GCC 9.1 and CMake 3.14.2
• How to install the project software stack from scratch (a blank hard drive / cloud instance) Please
provide concise documentation on what installation software is needed, and how to build from
source to binary as applicable. 

"


```
Senior-Design-Sailboat-Nav-2025
│   README.md
│   file001.txt    
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
│
└───OAK-D
│   │   MRS_Video.py
│   │   Triton.py
│   │   Waterline.py
│   └───models
│       │   
│       │ 
│  
└───PREVIOUS-REPORTS
│   │   MRS_Video.py
│   │   Triton.py
│
└───RPI-BLUETOOTH
│   │   MRS_Video.py
│   │   Triton.py
│
└───SOFTWARE-REPORT
│   │   MRS_Video.py
│   │   Triton.py
│
└───STEREOPI-BLUETOOTH
│   │   MRS_Video.py
│   │   Triton.py
│
└───Triton
│   │   MRS_Video.py
│   │   Triton.py
│
└───stereopi
│   │   MRS_Video.py
│   │   Triton.py
```

**HOW TO SET UP SOFTWARE ON A NEW RASPBERRY PI**
1. Clone this repo (Senior-Design-Sailboat-Nav-2025) in the top level of your Raspberry Pi
2. Ensure that the paths used in LAUNCHER-SCRIPTS/oakd_launcher.sh match the layout of your device (it should as long as you clone the repo in the right place)
3. Edit the crontab (sudo crontab -e)
4. Add this line to the crontab: @reboot ~/Senior-Design-Sailboat-Nav-2025/LAUNCHER-SCRIPTS/oakd_launcher.sh
5. Reboot the pi (sudo reboot) 


**HOW TO SET UP SOFTWARE ON A STEREOPI/CM4**
1. Clone this repo (Senior-Design-Sailboat-Nav-2025) in the top level of your StereoPi/CM4
2. Ensure that the paths used in LAUNCHER-SCRIPTS/stereopi_launcher.sh match the layout of your device (it should as long as you clone the repo in the right place)
3. Edit the crontab (sudo crontab -e)
4. Add this line to the crontab: @reboot ~/Senior-Design-Sailboat-Nav-2025/LAUNCHER-SCRIPTS/launcher.sh
5. Reboot the pi (sudo reboot) 

**List of Dependencies**
- Python Version 3.11.2
- dbus-python Version 1.0
- PyGObject Version 3.0


**WHAT DOES EACH MODULE DO?**
Read the READMEs in each folder to find out!

