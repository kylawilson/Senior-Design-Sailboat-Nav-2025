#!/usr/bin/env python3

import cv2
import depthai as dai
import math
import numpy as np
from datetime import datetime

# Create pipeline
pipeline = dai.Pipeline()

# Define sources and outputs
monoLeft = pipeline.create(dai.node.MonoCamera)
monoRight = pipeline.create(dai.node.MonoCamera)
stereo = pipeline.create(dai.node.StereoDepth)
spatialLocationCalculator = pipeline.create(dai.node.SpatialLocationCalculator)

camRgb: dai.node.Camera = pipeline.create(dai.node.Camera)
camRgb.setBoardSocket(dai.CameraBoardSocket.CAM_A)
camRgb.setSize((640,400))

xoutDepth = pipeline.create(dai.node.XLinkOut)
xoutSpatialData = pipeline.create(dai.node.XLinkOut)
xinSpatialCalcConfig = pipeline.create(dai.node.XLinkIn)

xoutDepth.setStreamName("depth")
xoutSpatialData.setStreamName("spatialData")
xinSpatialCalcConfig.setStreamName("spatialCalcConfig")

# Properties
monoLeft.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)
monoLeft.setCamera("left")
monoRight.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)
monoRight.setCamera("right")

stereo.setDefaultProfilePreset(dai.node.StereoDepth.PresetMode.HIGH_DENSITY)
stereo.setLeftRightCheck(True)
stereo.setSubpixel(True)
spatialLocationCalculator.inputConfig.setWaitForMessage(False)

size = 10  # size by size 
scale = 1 / size

# Create 10 ROIs
for i in range(size):
    for j in range(size):
        config = dai.SpatialLocationCalculatorConfigData()
        config.depthThresholds.lowerThreshold = 100
        config.depthThresholds.upperThreshold = 12000
        config.roi = dai.Rect(dai.Point2f((i) * scale, j * scale), dai.Point2f((i + 1) * scale, (j + 1) * scale))
        spatialLocationCalculator.initialConfig.addROI(config)


# Linking
monoLeft.out.link(stereo.left)
monoRight.out.link(stereo.right)

spatialLocationCalculator.passthroughDepth.link(xoutDepth.input)
stereo.depth.link(spatialLocationCalculator.inputDepth)

spatialLocationCalculator.out.link(xoutSpatialData.input)
xinSpatialCalcConfig.out.link(spatialLocationCalculator.inputConfig)

videoOut = pipeline.create(dai.node.XLinkOut)
videoOut.setStreamName("video")
camRgb.video.link(videoOut.input)

# Connect to device and start pipeline
with dai.Device(pipeline) as device:
    device.setIrLaserDotProjectorBrightness(1000)
    video = device.getOutputQueue(name="video", maxSize=1, blocking=False)

    # Output queue will be used to get the depth frames from the outputs defined above
    depthQueue = device.getOutputQueue(name="depth", maxSize=4, blocking=False)
    spatialCalcQueue = device.getOutputQueue(name="spatialData", maxSize=4, blocking=False)
    color = (0, 40, 200)  # RGB color of ROI area
    fontType = cv2.FONT_HERSHEY_TRIPLEX

    target_distance = 5000
    yellow = (0, 255, 255)
    red = (0, 0, 255)
    default_color = (0, 200, 40)
    safedist = {} 
    distance_history = {} #store distance of previous frames
    window = 10 #how many frames to average


    with open("roi_distances.txt", "a") as file:  # Open the file in append mode
        while True:
            inDepth = depthQueue.get()  # Blocking call, will wait until a new data has arrived

            depthFrame = inDepth.getFrame()  # depthFrame values are in millimeters
            depthFrame = cv2.medianBlur(depthFrame,5)

            depth_downscaled = depthFrame[::4]

            if video.has():
                frame = video.get().getCvFrame()
                frame_resized = cv2.resize(frame, (640, 400))
                
                # Prepare a copy of the depth frame for the heatmap
                depthFrameColor = np.copy(depthFrame)  # Copy depth data for heatmap processing

                if np.all(depth_downscaled == 0):
                    min_depth = 0  # Set a default minimum depth value when all elements are zero
                else:
                    min_depth = np.percentile(depth_downscaled[depth_downscaled != 0], 1)
                max_depth = np.percentile(depth_downscaled, 99)
                depthFrameColor = np.interp(depthFrameColor, (min_depth, max_depth), (0, 255)).astype(np.uint8)
                depthFrameColor = cv2.applyColorMap(depthFrameColor, cv2.COLORMAP_HOT)

                # Overlay ROIs on both the normal video feed and the depth heatmap
                spatialData = spatialCalcQueue.get().getSpatialLocations()
                
                for depthData in spatialData:
                    roi = depthData.config.roi
                    roi = roi.denormalize(width=frame_resized.shape[1], height=frame_resized.shape[0])

                    xmin = int(roi.topLeft().x)
                    ymin = int(roi.topLeft().y)
                    xmax = int(roi.bottomRight().x)
                    ymax = int(roi.bottomRight().y)
                    grid_x = int(roi.topLeft().x)
                    grid_y = int(roi.topLeft().y)

                    coords = depthData.spatialCoordinates
                    tempdistance = math.sqrt(coords.x ** 2 + coords.y ** 2 + coords.z ** 2)

                    ROI_ID = (xmin, ymin)


                    if ROI_ID not in safedist:
                        safedist[ROI_ID] = True

                    if ROI_ID not in distance_history:
                        distance_history[ROI_ID] = []
                    
                    distance_history[ROI_ID].append(tempdistance)
                    if len(distance_history[ROI_ID]) > window:
                        distance_history[ROI_ID].pop(0) #drop first value
                    
                    distance = sum(distance_history[ROI_ID]) / len(distance_history[ROI_ID])
                    


                    if distance <= 3000 and distance > 2000:
                        color = yellow
                        #safedist[ROI_ID] = True

                    elif distance <= 2000:
                        color = red
                        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        if safedist[ROI_ID]:
                            safedist[ROI_ID] = False
                            #file.write(f"{timestamp} - ROI {roi}: Distance {distance / 1000:.2f} meters\n")
                            print(f"ROI at grid position ({int(xmin) / 64}, {int(ymin) / 40}) is too close!: {distance / 1000:.1f}m")

                    else:
                        color = default_color
                        safedist[ROI_ID] = True

                    text = "({},{},{:.1f}m)".format(int(grid_x / 64), int(grid_y / 40), distance / 1000)

                    # Draw the ROI rectangle on the normal video feed
                    cv2.rectangle(frame_resized, (xmin, ymin), (xmax, ymax), color, thickness=2)
                    cv2.putText(frame_resized, "{:.1f}m".format(distance / 1000), (xmin + 10, ymin + 20), fontType, 0.3, color)

                    # Draw the ROI rectangle on the depth heatmap
                    cv2.rectangle(depthFrameColor, (xmin, ymin), (xmax, ymax), color, thickness=2)
                    cv2.putText(depthFrameColor, "{:.1f}m".format(distance / 1000), (xmin + 10, ymin + 20), fontType, 0.3, color)

                # Show both the normal video feed and the depth heatmap with the ROIs overlaid
                cv2.imshow("video", frame_resized)  # Normal video feed
                cv2.imshow("depth", depthFrameColor)  # Heatmap (depth) feed

            if cv2.waitKey(1) == ord('q'):
                break