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
All_camera_10_points.swift - DIEGO FILL IN
BluetoothService.swift - This is the code that controls and manages the bluetooth connection between the iOS device and the Triton (main module) and StereoPis (peripheral modules). This includes connecting, disconnecting, discovering services, receiving and parsing data, and more.
ContentView.swift - This is the top-level file that defines the application's UI
DataStructs.swift - 
ImageConversion.swift - 
img_serialized.txt -
info_tabs.swift -
Info.plist - 
ServiceDefinitions.swift -
TritonApp.swift - 
