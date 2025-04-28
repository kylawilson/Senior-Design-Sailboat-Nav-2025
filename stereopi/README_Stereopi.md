**StereoPi Code**

Utilizied for StereoPi Sensors.


**Dependencies:**

Raspberry Pi Debain Bullseye 32-Bit Full Legacy

Python3.11

OpenCV 3.4.3

Picamera 1.13


These files enable functionality of the Stereopi cameras and allow them to track depth and to map distance.


**Overview of Modules:**

1_test_py - shows camera preview, ensures that cameras are functioning

2_chess_cycle.py - Takes a series of 50 pictures for stereo calibration. Pictures need to have a chessboard design.

3_pairs_cut.py -Takes the samples from 2_chess_cycle.py and arranges the left and right phots into pairs.

4_calibartion_fisheye.py - Takes the samples from 3_pair_cut.py to create the Calibration Data.

5_dm_tune.py - Adjuts the Disparity Map for precise needs.

6_dm_video.py - Builds the disparity map.

7_2d_map.py - Builds the depth map.
