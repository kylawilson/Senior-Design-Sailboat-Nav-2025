#!/usr/bin/env python3

import cv2
import depthai as dai
import math
import numpy as np
import os
import base64
from datetime import datetime, timedelta
#NN imports
from pathlib import Path
import argparse
import time


#testing DBUS
# import dbus
# import dbus.service
# import dbus.mainloop.glib
# from gi.repository import GLib
# import threading


# # Create a D-Bus service class


# class ImageService(dbus.service.Object):
#     """D-Bus service that provides the latest image in base64 format."""

#     def __init__(self, bus_name):
#         dbus.service.Object.__init__(self, bus_name, '/ImageService')
#         self.latest_image_path = None  # Stores the most recent image path

#     @dbus.service.method("com.example.ImageService",
#                          in_signature='', out_signature='s')
#     def GetEncodedImage(self):
#         """Returns the base64-encoded image if available."""
#         if self.latest_image_path and os.path.exists(self.latest_image_path):
#             with open(self.latest_image_path, "rb") as img_file:
#                 encoded = base64.b64encode(img_file.read()).decode('utf-8')
#                 print(encoded)
#             print(f"Sent encoded image: {self.latest_image_path}")
#             return encoded  # Returns the base64 string
#         else:
#             return "No image available"

#     def update_latest_image(self, image_path):
#         """Updates the path to the latest image."""
#         self.latest_image_path = image_path
        
        
# class DepthService(dbus.service.Object):
#     """D-Bus service that provides the depths of objects in view in base64 format."""

#     def __init__(self, bus_name):
#         dbus.service.Object.__init__(self, bus_name, '/DepthService')
#         self.depth_array = None  # prob can get rid of this

#     @dbus.service.method("com.example.DepthService",
#                          in_signature='', out_signature='ad')    # returns an array
#     def GetDepth(self):
#         """Returns the base64-encoded depth if available."""
#         print(self.depth_array)
#         if self.depth_array is not None:         # need to set to None if we're not getting a reading when we set depth_array
#             #encoded = base64.b64encode(self.depth_array).decode('utf-8')
#             print(f"Sent depth: {self.depth_array}")
#             return self.depth_array  # Returns the base64 string
#         else:
#             return [1.0, 2.0, 3.0, 4.0]

#     def update_depth_array(self, depth_array):
#         """Updates to the latest depth array."""
#         self.depth_array = depth_array

# def run_dbus_service():
#     """Runs the D-Bus main loop in a separate thread."""
#     dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
#     session_bus = dbus.SessionBus()
#     bus_name_image = dbus.service.BusName("com.example.ImageService", session_bus)
#     bus_name_depth = dbus.service.BusName("com.example.DepthService", session_bus)
#     global image_service, depth_service
#     image_service = ImageService(bus_name_image)
#     depth_service = DepthService(bus_name_depth)
    
#     print("D-Bus service running...")
#     mainloop = GLib.MainLoop()
#     mainloop.run()


# dbus_thread = threading.Thread(target=run_dbus_service)
# dbus_thread.daemon = True
# dbus_thread.start()

#---Boat DBus---

#--- Depth Smoothing Config ---
extended_disparity = False  # Closer-in minimum depth, disparity range is doubled
subpixel = False  # Better accuracy for longer distance
lr_check = True  # Better handling for occlusions

labelMap = ["background", "aeroplane", "bicycle", "bird", "boat", "bottle", "bus", "car", "cat", "chair", "cow",
            "diningtable", "dog", "horse", "motorbike", "person", "pottedplant", "sheep", "sofa", "train", "tvmonitor"]

size = 10
scale = 1 / size

# Argument parsing
nnPathDefault = str((Path(__file__).parent / Path('../models/mobilenet-ssd_openvino_2021.4_6shave.blob')).resolve().absolute())
parser = argparse.ArgumentParser()
parser.add_argument('nnPath', nargs='?', help="Path to mobilenet detection network blob", default=nnPathDefault)
parser.add_argument('-ff', '--full_frame', action="store_true", help="Perform tracking on full RGB frame", default=False)
args = parser.parse_args()

# Create pipeline
pipeline = dai.Pipeline()

# --- RGB Camera Setup ---
camRgb = pipeline.create(dai.node.ColorCamera)
camRgb.setPreviewSize(640, 480)
camRgb.setResolution(dai.ColorCameraProperties.SensorResolution.THE_720_P)
camRgb.setInterleaved(False)
camRgb.setColorOrder(dai.ColorCameraProperties.ColorOrder.BGR)

# --- Object Detection Setup ---
imageManip = pipeline.create(dai.node.ImageManip)
imageManip.initialConfig.setResize(300, 300)
imageManip.setKeepAspectRatio(False)

detectionNetwork = pipeline.create(dai.node.MobileNetDetectionNetwork)
detectionNetwork.setBlobPath(args.nnPath)
detectionNetwork.setConfidenceThreshold(0.5)
detectionNetwork.input.setBlocking(False)

objectTracker = pipeline.create(dai.node.ObjectTracker)
objectTracker.setDetectionLabelsToTrack([4,15])  # track only person and boat
objectTracker.setTrackerType(dai.TrackerType.ZERO_TERM_COLOR_HISTOGRAM)
objectTracker.setTrackerIdAssignmentPolicy(dai.TrackerIdAssignmentPolicy.SMALLEST_ID)

# --- Depth Setup with Smoothing ---
monoLeft = pipeline.create(dai.node.MonoCamera)
monoRight = pipeline.create(dai.node.MonoCamera)
stereo = pipeline.create(dai.node.StereoDepth)
spatialLocationCalculator = pipeline.create(dai.node.SpatialLocationCalculator)

monoLeft.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)
monoLeft.setCamera("left")
monoRight.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)
monoRight.setCamera("right")

# Apply depth smoothing configuration
stereo.setDefaultProfilePreset(dai.node.StereoDepth.PresetMode.HIGH_DENSITY)
stereo.setDepthAlign(dai.CameraBoardSocket.RGB)
stereo.setLeftRightCheck(lr_check)
stereo.setExtendedDisparity(extended_disparity)
stereo.setSubpixel(subpixel)
stereo.setMedianFilter(dai.MedianFilter.KERNEL_7x7)
stereo.setOutputSize(640, 480)

# Configure post-processing filters
config = stereo.initialConfig.get()
config.postProcessing.speckleFilter.enable = False
config.postProcessing.speckleFilter.speckleRange = 50
config.postProcessing.temporalFilter.enable = True
config.postProcessing.spatialFilter.enable = True
config.postProcessing.spatialFilter.holeFillingRadius = 2
config.postProcessing.spatialFilter.numIterations = 1
config.postProcessing.thresholdFilter.minRange = 400
config.postProcessing.thresholdFilter.maxRange = 15000
config.postProcessing.decimationFilter.decimationFactor = 1
stereo.initialConfig.set(config)

# Create sizexsize ROIs
for i in range(size):
    for j in range(7):
        config = dai.SpatialLocationCalculatorConfigData()
        config.depthThresholds.lowerThreshold = 100
        config.depthThresholds.upperThreshold = 12000
        config.roi = dai.Rect(dai.Point2f(i * scale, j * scale), dai.Point2f((i + 1) * scale, (j + 1) * scale))
        spatialLocationCalculator.initialConfig.addROI(config)

tracked_objects = []
max_frames_missing = 5 #window before dropping a track object
last_print_time = time.time()

# --- Outputs ---
xoutRgb = pipeline.create(dai.node.XLinkOut)
xoutTracker = pipeline.create(dai.node.XLinkOut)
xoutDepth = pipeline.create(dai.node.XLinkOut)
xoutSpatialData = pipeline.create(dai.node.XLinkOut)
xinSpatialCalcConfig = pipeline.create(dai.node.XLinkIn)
videoOut = pipeline.create(dai.node.XLinkOut)

xoutRgb.setStreamName("preview")
xoutTracker.setStreamName("tracklets")
xoutDepth.setStreamName("depth")
xoutSpatialData.setStreamName("spatialData")
xinSpatialCalcConfig.setStreamName("spatialCalcConfig")
videoOut.setStreamName("video")

# --- Linking ---
# RGB and object tracking
camRgb.preview.link(imageManip.inputImage)
imageManip.out.link(detectionNetwork.input)
detectionNetwork.passthrough.link(objectTracker.inputDetectionFrame)
detectionNetwork.out.link(objectTracker.inputDetections)
objectTracker.out.link(xoutTracker.input)
objectTracker.passthroughTrackerFrame.link(xoutRgb.input)
camRgb.video.link(videoOut.input)

if args.full_frame:
    camRgb.video.link(objectTracker.inputTrackerFrame)
else:
    detectionNetwork.passthrough.link(objectTracker.inputTrackerFrame)

# Depth
monoLeft.out.link(stereo.left)
monoRight.out.link(stereo.right)
spatialLocationCalculator.passthroughDepth.link(xoutDepth.input)
stereo.depth.link(spatialLocationCalculator.inputDepth)
spatialLocationCalculator.out.link(xoutSpatialData.input)
xinSpatialCalcConfig.out.link(spatialLocationCalculator.inputConfig)

print("Starting MRS_Picutre.py as a D-Bus service...")

last_capture_time = datetime.now()
capture_interval = timedelta(seconds = 1)
vfps = 30
'''
video_filename = "test_video.avi"
depth_video_filename = "depth_test.avi"
combined_video_filename = "combined_video.avi"
fourcc = cv2.VideoWriter_fourcc(*'XVID')
video_writer = cv2.VideoWriter(video_filename, fourcc, vfps, (640, 480))
depth_video_writer = cv2.VideoWriter(depth_video_filename, fourcc, vfps, (640, 480))
combined_writer = cv2.VideoWriter(combined_video_filename, fourcc, vfps, (1280, 480))
'''

# Connect to device and start pipeline
with dai.Device(pipeline) as device:
    preview = device.getOutputQueue("preview", 4, False)
    tracklets = device.getOutputQueue("tracklets", 4, False)
    video = device.getOutputQueue("video", 4, False)
    depthQueue = device.getOutputQueue("depth", 4, False)
    spatialCalcQueue = device.getOutputQueue("spatialData", 4, False)

    color = (0, 40, 200)  # RGB color of ROI area
    fontType = cv2.FONT_HERSHEY_TRIPLEX
    target_distance = 5000

    yellow = (0, 255, 255)
    red = (0, 0, 255)
    default_color = (0, 200, 40)
    blue = (255, 0, 0)

    depth_array = [float('inf')] * size
    last_capture_time = datetime.now()
    capture_interval = timedelta(seconds=1)
    startTime = time.monotonic()
    counter = 0
    fps = 0

    safedist = {}
    distance_history = {}  # Store distance of previous frames
    window = 3  # How many frames to average

    with open("roi_distances.txt", "a") as file:
        while True:
            current_time = time.monotonic()
            counter += 1
            if (current_time - startTime) > 1:
                fps = counter / (current_time - startTime)
                counter = 0
                startTime = current_time

            previewFrame = preview.get()
            track = tracklets.get()
            #vframe = video.get()
            inDepth = depthQueue.get()

            frame = previewFrame.getCvFrame()
            frame_resized = cv2.resize(frame, (640, 480))
            depthFrame = inDepth.getFrame()
            depth_downscaled = depthFrame[::4]
            current_datetime = datetime.now()

            for obj in tracked_objects:
                obj['detected_this_frame'] = False

            # Process tracklets
            trackletsData = track.tracklets
            for t in trackletsData:
                roi = t.roi.denormalize(frame.shape[1], frame.shape[0])
                x1, y1, x2, y2 = int(roi.topLeft().x), int(roi.topLeft().y), int(roi.bottomRight().x), int(roi.bottomRight().y)
                
                scale_x, scale_y = 640 / frame.shape[1], 480 / frame.shape[0]
                x1_resized, y1_resized = int(x1 * scale_x), int(y1 * scale_y)
                x2_resized, y2_resized = int(x2 * scale_x), int(y2 * scale_y)

                centerer_x = (x1_resized + x2_resized) // 2
                centerer_y = (y1_resized + y2_resized) // 2
                new_width = (x2_resized - x1_resized) // 4
                new_height = (y2_resized - y1_resized) // 4

                square_x1 = centerer_x - new_width // 2
                square_y1 = centerer_y - new_height // 2
                square_x2 = centerer_x + new_width // 2
                square_y2 = centerer_y + new_height // 2

                try:
                    label = labelMap[t.label]
                except:
                    label = t.label
                Bcolor = (255, 0, 0)

                # Extract depth for object
                roi_depth = depthFrame[y1_resized:y2_resized, x1_resized:x2_resized]
                half_roi = depthFrame[square_y1:square_y2, square_x1:square_x2]

                distance = np.mean(roi_depth) if roi_depth.size > 0 else 0
                square_distance = np.mean(half_roi) if half_roi.size > 0 else 0

                center_x = (x1_resized + x2_resized) // 2
                focal_length = 2.35
                sensor_width = 3.6
                flp = (focal_length * 640) / sensor_width
                angle_rad = math.atan((center_x - (640//2))/flp)
                angle_deg = math.degrees(angle_rad)
                x_comp = square_distance * math.cos(angle_rad) / 1000
                y_comp = square_distance * math.sin(angle_rad) / 1000

                found = False
                for i, obj in enumerate(tracked_objects):
                    if obj['id'] == t.id:
                        tracked_objects[i] = {
                            'id': t.id,
                            'distance': square_distance,
                            'angle_deg': angle_deg,
                            'detected_this_frame': True,
                            'frames_missing': 0  # Reset missing counter
                        }
                        found = True
                        break
    
                if not found:
                    tracked_objects.append({
                        'id': t.id,
                        'distance': square_distance,
                        'angle_deg': angle_deg,
                        'detected_this_frame': True,
                        'frames_missing': 0
                    })

                if distance <= 10000 and distance > 5000: 
                    Bcolor = yellow
                    #print(f"ROI: ({t.id}): {square_distance / 1000:.1f}m - Angle: {angle_deg:.2f}\n\t\tX: {x_comp:.2f} Y: {y_comp:.2f}")
                elif distance <= 5000:
                    Bcolor = red
                else:
                    Bcolor = default_color
                    #print(f"ROI: ({t.id}): {square_distance / 1000:.1f}m - Angle: {angle_deg:.2f}\n\t\tX: {x_comp:.2f} Y: {y_comp:.2f}")
                    

                distance = distance / 1000
                square_distance = square_distance / 1000

                cv2.putText(frame_resized, str(label), (x1_resized + 10, y1_resized + 20), cv2.FONT_HERSHEY_TRIPLEX, 0.5, 255)
                cv2.putText(frame_resized, f"ID: {[t.id]}", (x1_resized + 10, y1_resized + 35), cv2.FONT_HERSHEY_TRIPLEX, 0.5, 255)
                cv2.putText(frame_resized, t.status.name, (x1_resized + 10, y1_resized + 50), cv2.FONT_HERSHEY_TRIPLEX, 0.5, 255)
                cv2.rectangle(frame_resized, (x1_resized, y1_resized), (x2_resized, y2_resized), color, cv2.FONT_HERSHEY_SIMPLEX)
                cv2.rectangle(frame_resized, (square_x1, square_y1), (square_x2, square_y2), red, cv2.FONT_HERSHEY_SIMPLEX)
                cv2.putText(frame_resized, f"Dist: {distance:.1f} m", (x1_resized + 10, y1_resized + 65), cv2.FONT_HERSHEY_TRIPLEX, 0.5, (0, 0, 255))
                cv2.putText(frame_resized, f"Angle: {angle_deg:.1f}", (x1_resized+ 10, y1_resized + 80), cv2.FONT_HERSHEY_TRIPLEX, 0.5, (0, 0, 255))
                cv2.putText(frame_resized, f"Small_Dist: {square_distance:.1f} m", (x1_resized + 10, y1_resized + 95), cv2.FONT_HERSHEY_TRIPLEX, 0.5, (0, 0, 255))

            # Process grid ROIs
            
            updated_tracked_objects = []
            for obj in tracked_objects:
                if not obj.get('detected_this_frame', False):
                    obj['frames_missing'] = obj.get('frames_missing', 0) + 1
                    #print(f"Object {obj['id']} not detected this frame (missing {obj['frames_missing']}/{max_frames_missing})")
                
                if obj.get('frames_missing', 0) < max_frames_missing:
                    updated_tracked_objects.append(obj)


            tracked_objects = updated_tracked_objects
            spatialData = spatialCalcQueue.get().getSpatialLocations()
            temparr = [float('inf')] * size
            column_min_roi = {}

            for depthData in spatialData:
                roi = depthData.config.roi.denormalize(width=frame_resized.shape[1], height=frame_resized.shape[0])
                xmin = int(roi.topLeft().x)
                ymin = int(roi.topLeft().y)
                xmax = int(roi.bottomRight().x)
                ymax = int(roi.bottomRight().y)

                coords = depthData.spatialCoordinates

                roi_depth = depthFrame[ymin:ymax, xmin:xmax]
                tempdistance = np.mean(roi_depth) if roi_depth.size > 0 else 0

                ROI_ID = (xmin, ymin)

                if ROI_ID not in safedist:
                    safedist[ROI_ID] = True

                if ROI_ID not in distance_history:
                    distance_history[ROI_ID] = []

                distance_history[ROI_ID].append(tempdistance)
                if len(distance_history[ROI_ID]) > window:
                    distance_history[ROI_ID].pop(0)

                distance = sum(distance_history[ROI_ID]) / len(distance_history[ROI_ID])

                if distance <= 10000 and distance > 5000:
                    color = yellow
                elif distance <= 5000 and distance > 500:
                    color = red
                elif distance <= 500: #idea being that .5m is our min distance so readings less than 100 giving some padding are actually far away
                    color = default_color
                    distance = 100000000000 #arbitray large number 
                else:
                    color = default_color
                
                column_index = int(xmin / (frame_resized.shape[1] / size))
                if distance < temparr[column_index]:
                    temparr[column_index] = distance
                    column_min_roi[column_index] = (xmin, ymin, xmax, ymax)

                cv2.rectangle(frame_resized, (xmin, ymin), (xmax, ymax), color, thickness=2)
                cv2.putText(frame_resized, "{:.1f}m".format(distance / 1000), (xmin + 10, ymin + 20), fontType, 0.3, color)
            
            for i in range(size):
                if temparr[i] != float('inf'):
                    depth_array[i] = temparr[i]
            #print("Dist: ", ["{:.2f}".format(d/1000) if d!= float('inf') else "inf" for d in depth_array])
            #depth_service.update_depth_array(depth_array)

            # Prepare depth heatmap
            if np.all(depth_downscaled == 0):
                min_depth = 0
            else:
                min_depth = np.percentile(depth_downscaled[depth_downscaled != 0], 1)
            max_depth = np.percentile(depth_downscaled, 99)
            depthFrameColor = np.interp(depthFrame, (min_depth, max_depth), (0, 255)).astype(np.uint8)
            depthFrameColor = cv2.applyColorMap(depthFrameColor, cv2.COLORMAP_HOT)
            depthFrameColor_resized = cv2.resize(depthFrameColor, (640, 480))

            # Display info
            timestamp_text = current_datetime.strftime("%Y-%m-%d %H:%M:%S")
            cv2.putText(frame_resized, timestamp_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)
            cv2.putText(depthFrameColor_resized, timestamp_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)
            cv2.putText(frame_resized, f"NN fps: {fps:.2f}", (10, 25), cv2.FONT_HERSHEY_TRIPLEX, 0.5, (255, 255, 255))
            
            #cv2.imshow("video", frame_resized)
            #cv2.imshow("tracker", frame_resized)
            #cv2.imshow("depth", depthFrameColor_resized)

            # Capture frame if interval elapsed

            current_time = time.time()
            stamptime = datetime.now()
            if current_time - last_print_time >= .1:
                last_print_time = current_time
                for obj in tracked_objects:
                    print(f"ID: {obj['id']}, Distance: {obj['distance']/1000:.2f}m, Angle: {obj['angle_deg']:.1f}°")
                    #dbus call for tracked objects/boats here

            if current_datetime - last_capture_time >= capture_interval:
                timestamp = stamptime.strftime("%Y%m%d_%H%M%S")
                image_filename = f"outputframe.jpg"
                #depth_filename = f"Depth_Images/depth_{timestamp}.jpg"
                cv2.imwrite(image_filename, frame_resized)
                #cv2.imwrite(depth_filename, depthFrameColor)
                last_capture_time = current_datetime
                # Update the latest image path for D-Bus
                #image_service.update_latest_image(image_filename)
                print(f"Captured and updated image: {image_filename}")

            #video_writer.write(frame_resized)
            #depth_video_writer.write(depthFrameColor_resized)
            combined_frame = np.hstack((frame_resized, depthFrameColor_resized))
            #combined_writer.write(combined_frame)
            if cv2.waitKey(1) == ord('q'):
                break

cv2.destroyAllWindows()
video_writer.release()
