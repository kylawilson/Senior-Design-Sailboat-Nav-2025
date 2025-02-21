
import cv2
import depthai as dai
import math
import numpy as np
import os
import base64
from datetime import datetime, timedelta
#testing DBUS
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import threading


# Create a D-Bus service class


class ImageService(dbus.service.Object):
    """D-Bus service that provides the latest image in base64 format."""

    def __init__(self, bus_name):
        dbus.service.Object.__init__(self, bus_name, '/ImageService')
        self.latest_image_path = None  # Stores the most recent image path

    @dbus.service.method("com.example.ImageService",
                         in_signature='', out_signature='s')
    def GetEncodedImage(self):
        """Returns the base64-encoded image if available."""
        if self.latest_image_path and os.path.exists(self.latest_image_path):
            with open(self.latest_image_path, "rb") as img_file:
                encoded = base64.b64encode(img_file.read()).decode('utf-8')
            print(f"Sent encoded image: {self.latest_image_path}")
            return encoded  # Returns the base64 string
        else:
            return "No image available"

    def update_latest_image(self, image_path):
        """Updates the path to the latest image."""
        self.latest_image_path = image_path

def run_dbus_service():
    """Runs the D-Bus main loop in a separate thread."""
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    session_bus = dbus.SessionBus()
    bus_name = dbus.service.BusName("com.example.ImageService", session_bus)
    global image_service
    image_service = ImageService(bus_name)
    
    print("D-Bus service running...")
    mainloop = GLib.MainLoop()
    mainloop.run()

# class ImageService(dbus.service.Object):
#     def __init__(self, bus_name):
#         dbus.service.Object.__init__(self, bus_name, '/ImageService')
#         self.latest_image_path = None  # Store the last captured image path

#     @dbus.service.method("com.example.ImageService",
#                          in_signature='', out_signature='s')
#     def GetEncodedImage(self):
#         """Returns the base64-encoded image if available."""
#         if self.latest_image_path and os.path.exists(self.latest_image_path):
#             with open(self.latest_image_path, "rb") as img_file:
#                 encoded = base64.b64encode(img_file.read()).decode('utf-8')
#             print(f"Sent encoded image: {self.latest_image_path}")
#             return encoded
#         else:
#             return "No image available"

#     def update_latest_image(self, image_path):
#         """Update the latest captured image path."""
#         self.latest_image_path = image_path
        
# Initialize D-Bus
# dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
# session_bus = dbus.SessionBus()
# bus_name = dbus.service.BusName("com.example.ImageService", session_bus)
# image_service = ImageService(bus_name)

dbus_thread = threading.Thread(target=run_dbus_service)
dbus_thread.daemon = True
dbus_thread.start()

# Create pipeline
pipeline = dai.Pipeline()

# Define sources and outputs
monoLeft = pipeline.create(dai.node.MonoCamera)
monoRight = pipeline.create(dai.node.MonoCamera)
stereo = pipeline.create(dai.node.StereoDepth)
spatialLocationCalculator = pipeline.create(dai.node.SpatialLocationCalculator)

camRgb: dai.node.Camera = pipeline.create(dai.node.Camera)
camRgb.setBoardSocket(dai.CameraBoardSocket.CAM_A)
camRgb.setSize((1280, 720))

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

size = 10  # size by size grid
scale = 1 / size

print("saving images to: ", os.getcwd())

# Create 10x10 ROIs
for i in range(size):
    for j in range(size):
        config = dai.SpatialLocationCalculatorConfigData()
        config.depthThresholds.lowerThreshold = 100
        config.depthThresholds.upperThreshold = 12000
        config.roi = dai.Rect(dai.Point2f(i * scale, j * scale), dai.Point2f((i + 1) * scale, (j + 1) * scale))
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

print("Starting MRS_Picutre.py as a D-Bus service...")

# Set up video writer
# video_filename = "output_video.avi"  # Output video file name
# heatmap_filename = "heatmap_video.avi"
# fourcc = cv2.VideoWriter_fourcc(*'XVID')  # Codec for AVI format
# frame_width, frame_height = 1280, 720  # Must match the size of your frames
# fps = 5  # Adjust the frame rate as needed
# video_writer = cv2.VideoWriter(video_filename, fourcc, fps, (frame_width, frame_height))
# video_writer_heatmap = cv2.VideoWriter(heatmap_filename, fourcc, fps, (frame_width, frame_height))

# Connect to device and start pipeline
with dai.Device(pipeline) as device:
    device.setIrLaserDotProjectorBrightness(1000)
    video = device.getOutputQueue(name="video", maxSize=1, blocking=False)
    depthQueue = device.getOutputQueue(name="depth", maxSize=4, blocking=False)
    spatialCalcQueue = device.getOutputQueue(name="spatialData", maxSize=4, blocking=False)

    color = (0, 40, 200)  # RGB color of ROI area
    fontType = cv2.FONT_HERSHEY_TRIPLEX

    target_distance = 5000
    yellow = (0, 255, 255)
    red = (0, 0, 255)
    default_color = (0, 200, 40)
    safedist = {}
    distance_history = {}  # Store distance of previous frames
    window = 3  # How many frames to average

    #picture timer
    # last_capture_time = datetime.now()
    # capture_interval = timedelta(seconds = 1)
    
    
    # mainloop = GLib.MainLoop()

    # while True:
    #     current_time = datetime.now()

    #     if video.has():
    #         frame = video.get().getCvFrame()
    #         frame_resized = cv2.resize(frame, (1280, 720))

    #         if current_time - last_capture_time >= capture_interval:
    #             last_capture_time = current_time
    #             timestamp = current_time.strftime("%Y%m%d_%H%M%S")
    #             image_filename = f"frame_{timestamp}.jpg"
    #             cv2.imwrite(image_filename, frame_resized)
    #             image_service.update_latest_image(image_filename)  # Update service with latest image
    #             print(f"Captured: {image_filename}")

    #     if cv2.waitKey(1) == ord('q'):
    #         break

    # mainloop.run()

    last_capture_time = datetime.now()

    while True:
        current_time = datetime.now()
        capture_interval = timedelta(seconds = 1)

        if video.has():
            frame = video.get().getCvFrame()
            frame_resized = cv2.resize(frame, (1280, 720))

            if current_time - last_capture_time >= capture_interval:
                last_capture_time = current_time
                timestamp = current_time.strftime("%Y%m%d_%H%M%S")
                image_filename = f"frame_{timestamp}.jpg"
                cv2.imwrite(image_filename, frame_resized)
                
                # Update the latest image path for D-Bus
                image_service.update_latest_image(image_filename)
                
                print(f"Captured and updated image: {image_filename}")

        if cv2.waitKey(1) == ord('q'):
            break

video_writer.release()
cv2.destroyAllWindows()

#    with open("roi_distances.txt", "a") as file:  # Open the file in append mode
#        while True:
#            inDepth = depthQueue.get()  # Blocking call, will wait until new data has arrived
#            depthFrame = inDepth.getFrame()  # Depth frame values are in millimeters
#            depthFrame = cv2.medianBlur(depthFrame, 5)
#            depth_downscaled = depthFrame[::4]
#
#            if video.has():
#                frame = video.get().getCvFrame()
#                frame_resized = cv2.resize(frame, (1280, 720))
#
#
#                # Prepare a copy of the depth frame for the heatmap
#                depthFrameColor = np.copy(depthFrame)
#
#                if np.all(depth_downscaled == 0):
#                    min_depth = 0
#                else:
#                    min_depth = np.percentile(depth_downscaled[depth_downscaled != 0], 1)
#                max_depth = np.percentile(depth_downscaled, 99)
#                depthFrameColor = np.interp(depthFrameColor, (min_depth, max_depth), (0, 255)).astype(np.uint8)
#                depthFrameColor = cv2.applyColorMap(depthFrameColor, cv2.COLORMAP_HOT)
#                depthFrameColor_resized = cv2.resize(depthFrameColor, (1280, 720))
#
#                spatialData = spatialCalcQueue.get().getSpatialLocations()
#
#                for depthData in spatialData:
#                    roi = depthData.config.roi
#                    roi = roi.denormalize(width=frame_resized.shape[1], height=frame_resized.shape[0])
#
#                    xmin = int(roi.topLeft().x)
#                    ymin = int(roi.topLeft().y)
#                    xmax = int(roi.bottomRight().x)
#                    ymax = int(roi.bottomRight().y)
#
#                    coords = depthData.spatialCoordinates
#                    tempdistance = math.sqrt(coords.x ** 2 + coords.y ** 2 + coords.z ** 2)
#
#                    ROI_ID = (xmin, ymin)
#
#                    if ROI_ID not in safedist:
#                        safedist[ROI_ID] = True
#
#                    if ROI_ID not in distance_history:
#                        distance_history[ROI_ID] = []
#
#                    distance_history[ROI_ID].append(tempdistance)
#                    if len(distance_history[ROI_ID]) > window:
#                        distance_history[ROI_ID].pop(0)
#
#                    distance = sum(distance_history[ROI_ID]) / len(distance_history[ROI_ID])
#
#                    if distance <= 2500 and distance > 1500:
#                        color = yellow
#                    elif distance <= 1500:
#                        color = red
#                        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
#                        if safedist[ROI_ID]:
#                            safedist[ROI_ID] = False
#                            print(f"ROI at grid position ({int(xmin) / 64}, {int(ymin) / 40}) is too close!: {distance / 1000:.1f}m")
#                    else:
#                        color = default_color
#                        safedist[ROI_ID] = True
#
#                    text = "({},{},{:.1f}m)".format(int(xmin / 64), int(ymin / 40), distance / 1000)
#
#                    cv2.rectangle(frame_resized, (xmin, ymin), (xmax, ymax), color, thickness=2)
#                    cv2.putText(frame_resized, "{:.1f}m".format(distance / 1000), (xmin + 10, ymin + 20), fontType, 0.3, color)
#
#                    cv2.rectangle(depthFrameColor_resized, (xmin, ymin), (xmax, ymax), color, thickness=2)
#                    cv2.putText(depthFrameColor_resized, "{:.1f}m".format(distance / 1000), (xmin + 10, ymin + 20), fontType, 0.3, color)
#                current_time = datetime.now()
#                timestamp_text = current_time.strftime("%Y-%m-%d %H:%M:%S")
#                cv2.putText(frame_resized, timestamp_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)
#                cv2.putText(depthFrameColor_resized, timestamp_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)
#                cv2.imshow("video", frame_resized)
#                cv2.imshow("depth", depthFrameColor_resized)
#
#                # Save the video frame
#                # video_writer.write(frame_resized)
#                # video_writer_heatmap.write(depthFrameColor_resized)                
#
#                if current_time - last_capture_time >= capture_interval:
#                    last_capture_time = current_time
#                    timestamp = current_time.strftime("%Y%m%d_%H%M%S")
#                    image_filename = f"frame_{timestamp}.jpg"
#                    depth_filename = f"depth_{timestamp}.jpg"
#                    cv2.imwrite(image_filename, frame_resized)
#                    #cv2.imwrite(depth_filename, depthFrameColor)
#                    print(f"Captured: {image_filename}")
#                    separator = "\n|||IMAGE_END|||\n"
#                    with open(image_filename, "rb") as img_file:
#                        serialized = base64.b64encode(img_file.read()).decode('utf-8')
#                    with open("img_serialized.txt","a") as txt_file:
#                        txt_file.write(serialized + separator)
#                    #print(serialized)
#
#            if cv2.waitKey(1) == ord('q'):
#                break

# Release the video writer and destroy windows
# video_writer.release()
# cv2.destroyAllWindows()
