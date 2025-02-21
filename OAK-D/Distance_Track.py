#!/usr/bin/env python3

from pathlib import Path
import cv2
import depthai as dai
import numpy as np
import time
import math
import argparse

labelMap = ["background", "aeroplane", "bicycle", "bird", "boat", "bottle", "bus", "car", "cat", "chair", "cow",
            "diningtable", "dog", "horse", "motorbike", "person", "pottedplant", "sheep", "sofa", "train", "tvmonitor"]

nnPathDefault = str((Path(__file__).parent / Path('../models/mobilenet-ssd_openvino_2021.4_6shave.blob')).resolve().absolute())

parser = argparse.ArgumentParser()
parser.add_argument('nnPath', nargs='?', help="Path to mobilenet detection network blob", default=nnPathDefault)
parser.add_argument('-ff', '--full_frame', action="store_true", help="Perform tracking on full RGB frame", default=False)

args = parser.parse_args()
fullFrameTracking = args.full_frame

# Create pipeline
pipeline = dai.Pipeline()

# Define sources and outputs
camRgb = pipeline.create(dai.node.ColorCamera)
imageManip = pipeline.create(dai.node.ImageManip)
detectionNetwork = pipeline.create(dai.node.MobileNetDetectionNetwork)
objectTracker = pipeline.create(dai.node.ObjectTracker)

xlinkOut = pipeline.create(dai.node.XLinkOut)
trackerOut = pipeline.create(dai.node.XLinkOut)

xlinkOut.setStreamName("preview")
trackerOut.setStreamName("tracklets")

videoOut = pipeline.create(dai.node.XLinkOut)
videoOut.setStreamName("video")
camRgb.video.link(videoOut.input)

# Properties
camRgb.setPreviewSize(1280, 720)
camRgb.setResolution(dai.ColorCameraProperties.SensorResolution.THE_1080_P)
camRgb.setInterleaved(False)
camRgb.setColorOrder(dai.ColorCameraProperties.ColorOrder.BGR)
camRgb.setFps(20)

imageManip.initialConfig.setResize(300, 300)
imageManip.setKeepAspectRatio(False)

# MobileNet Detection Network
detectionNetwork.setBlobPath(args.nnPath)
detectionNetwork.setConfidenceThreshold(0.5)
detectionNetwork.input.setBlocking(False)

objectTracker.setDetectionLabelsToTrack([15])  # track only person
objectTracker.setTrackerType(dai.TrackerType.ZERO_TERM_COLOR_HISTOGRAM)
objectTracker.setTrackerIdAssignmentPolicy(dai.TrackerIdAssignmentPolicy.SMALLEST_ID)

# Linking
camRgb.preview.link(imageManip.inputImage)
imageManip.out.link(detectionNetwork.input)
objectTracker.passthroughTrackerFrame.link(xlinkOut.input)

# ----- DEPTH SETUP ----- #
monoLeft = pipeline.create(dai.node.MonoCamera)
monoRight = pipeline.create(dai.node.MonoCamera)
stereo = pipeline.create(dai.node.StereoDepth)
depthAligned = pipeline.create(dai.node.XLinkOut)

depthAligned.setStreamName("depth_aligned")

monoLeft.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)
monoLeft.setCamera("left")
monoRight.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)
monoRight.setCamera("right")

# Align depth to RGB
stereo.setDepthAlign(dai.CameraBoardSocket.RGB)
stereo.setLeftRightCheck(True)  # Improves depth quality
stereo.setSubpixel(True)  # Improves accuracy
stereo.setOutputSize(1280, 720)  # Match RGB size

stereo.depth.link(depthAligned.input)

monoLeft.out.link(stereo.left)
monoRight.out.link(stereo.right)

if fullFrameTracking:
    camRgb.video.link(objectTracker.inputTrackerFrame)
else:
    detectionNetwork.passthrough.link(objectTracker.inputTrackerFrame)

detectionNetwork.passthrough.link(objectTracker.inputDetectionFrame)
detectionNetwork.out.link(objectTracker.inputDetections)
objectTracker.out.link(trackerOut.input)

# Connect to device and start pipeline
with dai.Device(pipeline) as device:

    preview = device.getOutputQueue("preview", 4, False)
    tracklets = device.getOutputQueue("tracklets", 4, False)
    video = device.getOutputQueue(name="video", maxSize=1, blocking=False)
    q_depth_aligned = device.getOutputQueue(name="depth_aligned", maxSize=4, blocking=False)

    startTime = time.monotonic()
    counter = 0
    fps = 0

    while True:
        imgFrame = preview.get()
        track = tracklets.get()
        vframe = video.get()
        in_depth = q_depth_aligned.get()
        depth_frame = in_depth.getFrame()  # Now depth is aligned with RGB

        if vframe is not None:
            vframe_resized = cv2.resize(vframe.getCvFrame(), (300, 300))

        counter += 1
        current_time = time.monotonic()
        if (current_time - startTime) > 1:
            fps = counter / (current_time - startTime)
            counter = 0
            startTime = current_time

        frame = imgFrame.getCvFrame()
        frame_resized = cv2.resize(frame, (1280, 720))

        trackletsData = track.tracklets
        for t in trackletsData:
            roi = t.roi.denormalize(frame.shape[1], frame.shape[0])
            x1, y1, x2, y2 = int(roi.topLeft().x), int(roi.topLeft().y), int(roi.bottomRight().x), int(roi.bottomRight().y)
            
            scale_x, scale_y = 1280 / frame.shape[1], 720 / frame.shape[0]
            x1_resized, y1_resized = int(x1 * scale_x), int(y1 * scale_y)
            x2_resized, y2_resized = int(x2 * scale_x), int(y2 * scale_y)

            try:
                label = labelMap[t.label]
            except:
                label = t.label
            color = (255, 0, 0)
            text_color = (0, 0, 255)

            cv2.putText(frame_resized, str(label), (x1_resized + 10, y1_resized + 20), cv2.FONT_HERSHEY_TRIPLEX, 0.5, 255)
            cv2.putText(frame_resized, f"ID: {[t.id]}", (x1_resized + 10, y1_resized + 35), cv2.FONT_HERSHEY_TRIPLEX, 0.5, 255)
            cv2.putText(frame_resized, t.status.name, (x1_resized + 10, y1_resized + 50), cv2.FONT_HERSHEY_TRIPLEX, 0.5, 255)
            cv2.rectangle(frame_resized, (x1_resized, y1_resized), (x2_resized, y2_resized), color, cv2.FONT_HERSHEY_SIMPLEX)
            cv2.rectangle(vframe_resized, (x1, y1), (x2, y2), color, cv2.FONT_HERSHEY_SIMPLEX)

            # Extract depth for object
            roi_depth = depth_frame[y1_resized:y2_resized, x1_resized:x2_resized]
            distance = np.mean(roi_depth) / 1000  # Convert to meters

            center_x = (x1_resized+x2_resized)//2

            focal_length = 2.35
            sensor_width = 3.6

            flp = (focal_length * 1280) / sensor_width

            angle_rad = math.atan((center_x - (1280//2))/flp)
            angle_deg = math.degrees(angle_rad)

            cv2.putText(frame_resized, f"Dist: {distance:.1f} m", (x1_resized + 10, y1_resized + 65), cv2.FONT_HERSHEY_TRIPLEX, 0.5, (0, 0, 255))
            cv2.putText(frame_resized, f"Angle: {angle_deg:.1f}°", (x1_resized+ 10, y1_resized + 80), cv2.FONT_HERSHEY_TRIPLEX, 0.5, (0, 0, 255))

        # Overlay depth on RGB for debugging
        depth_color = cv2.applyColorMap(cv2.convertScaleAbs(depth_frame, alpha=0.03), cv2.COLORMAP_JET)
        blend = cv2.addWeighted(frame_resized, 0.6, depth_color, 0.4, 0)
        cv2.imshow("Aligned Depth Overlay", blend)

        cv2.putText(frame_resized, f"NN fps: {fps:.2f}", (10, 30), cv2.FONT_HERSHEY_TRIPLEX, 0.6, (255, 255, 255))
        cv2.imshow("tracker", frame_resized)

        if cv2.waitKey(1) == ord('q'):
            break
