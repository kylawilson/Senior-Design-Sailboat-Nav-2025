• An overview of each software module
• A flow chart indicating the dependencies between these functions. For instance, if you have a
main.py and LCD.py, you need to show that LCD.py is a module used by main.py.
• Dev/build tool information: Package name and version info. For example, OpenCV 4.0.3 with
Python 3.8.1, using CUDA Toolbox 10.0 and GCC 9.1 and CMake 3.14.2

Triton.py: The OAK-D and Trition's object detection script that utilizes both the neural net object tracking as well as the grid system
to record and determine the relevant data of detected objects and prepare the data to be sent to the app.

MRS_Video.py: Testing script for recording video of the multi ROI grid object dection system

OTV.py: Testing script for recording video of the neural network and object tracking system

Waterline.py: Testing script for unfinished feature to dynamically track the horizon so that the system can actively ignore depth readings
from the surface of the water. Based of the work done by Tim Huff to dynamically track the horizon for autonomous drones.

