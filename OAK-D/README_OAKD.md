• An overview of each software module
• A flow chart indicating the dependencies between these functions. For instance, if you have a
main.py and LCD.py, you need to show that LCD.py is a module used by main.py.
• Dev/build tool information: Package name and version info. For example, OpenCV 4.0.3 with
Python 3.8.1, using CUDA Toolbox 10.0 and GCC 9.1 and CMake 3.14.2

Software Overview:
Triton.py: The OAK-D and Trition's object detection script that utilizes both the neural net object tracking as well as the grid system
to record and determine the relevant data of detected objects and prepare the data to be sent to the app. The detection system consists
of two parts, a 10x10 grid of region of interests which records the depth of each region through openCV. The minimum distance for each
ROI column is then recorded and stored in an array. The second system is a neural net that identifies and tracks boats and draws a dynamic
ROI around each object and records the distance of the object (if within range) and its position relative to the camera. The data from the
two systems in then stored and sent over DBUS and then sent via BLE to the app.

MRS_Video.py: Testing script for recording video of the multi ROI grid object dection system

OTV.py: Testing script for recording video of the neural network and object tracking system

Waterline.py: Testing script for unfinished feature to dynamically track the horizon so that the system can actively ignore depth readings
from the surface of the water. Based of the work done by Tim Huff to dynamically track the horizon for autonomous drones. Uses open CV to
track features on the horizon and draw an estimated horizon line.


**DEPENDENCIES**
- blobconverter             1.4.3
- depthai                   2.28.0.0
- opencv-python             4.10.0.84
- nbclient                  0.10.2
- nbconvert                 7.16.6
- nbformat                  5.10.4
- Python                    3.11
- dbus-python 1.3.2

**DEVICE REQUIREMENTS**
- OAK-D Stereo Camera
- Raspberry Pi 3B


