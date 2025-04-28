• An overview of each software module
• A flow chart indicating the dependencies between these functions. For instance, if you have a
main.py and LCD.py, you need to show that LCD.py is a module used by main.py.
• Dev/build tool information: Package name and version info. For example, OpenCV 4.0.3 with
Python 3.8.1, using CUDA Toolbox 10.0 and GCC 9.1 and CMake 3.14.2

**DEPENDENCIES**
- CoreBluetooth
- SwiftUI
- XCode 16.3 or Higher

**DEVICE REQUIREMENTS**
- For Development: A Mac with XCode 16.3 or Higher
- For Running the App: An iPhone with iOS 18 or Higher

**DEVICES USED**
- For Development: MacBook Pro, 16-inch, 2019, macOS Sequoia 15.3.2
- For Testing: 
    - iPhone 11 Pro, iOS 18.1.1
    - iPhone 16 Pro, iOS 18.3.2
    
**OVERVIEW OF EACH SOFTWARE MODULE**
All_camera_10_points.swift - **DIEGO FILL IN**
BluetoothService.swift - This is the code that controls and manages the bluetooth connection between the iOS device and the Triton (main module) and StereoPis (peripheral modules). This includes connecting, disconnecting, discovering services, receiving and parsing data, and more.
ContentView.swift - This is the top-level file that defines the application's UI and layout
DataStructs.swift - This file contains two of the data structs that we created to organize our data better: one for GPS data and one for Anemometer data. This allows us to have simpler data extraction for the UI once the data is parsed in BluetoothService.
ImageConversion.swift - This file contains all of our functions related to converting the serial data of the OAK-D's live view to a viewable image within the application.
info_tabs.swift - **DIEGO FILL IN**
Info.plist - This is the information property list file, a file used by Apple that contains configuration information for the application. The most important use of this in our app is for Bluetooth permissions.
ServiceDefinitions.swift - This file contains all of the Service Definitions for our app. It contains all of the UUIDs for the characteristics, services, and connection statuses .
TritonApp.swift - This is the top level module that is our app. It instantiates ContentView to display our UI within Swift's app structure.
