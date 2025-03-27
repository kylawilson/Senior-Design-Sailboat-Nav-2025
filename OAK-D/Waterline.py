import cv2
import numpy as np
import depthai as dai
import skimage.measure
from math import atan2, cos, sin, pi, degrees, radians
from numpy.linalg import norm

# Constants
FULL_ROTATION = 360
POOLING_KERNEL_SIZE = 5

class HorizonDetector:
    def __init__(self, exclusion_thresh: float, fov: float, acceptable_variance: float, frame_shape: tuple):
        """
        exclusion_thresh: parameter that controls how close horizon points have to be
        to predicted horizon in order to be considered valid
        fov: field of view of the camera
        acceptable_variance: minimum acceptable variance for horizon contour points.
        frame_shape: together with fov used to convert exclusion_thresh 
        from a pitch angle to pixels
        """
        self.exclusion_thresh = exclusion_thresh  # in degrees of pitch
        self.exclusion_thresh_pixels = exclusion_thresh * frame_shape[0] // fov
        self.fov = fov
        self.acceptable_variance = acceptable_variance
        self.predicted_roll = None
        self.predicted_pitch = None
        self.recent_horizons = [None, None]

    def find_horizon(self, frame: np.ndarray, diagnostic_mode: bool = False):
        """
        frame: the image in which you want to find the horizon
        diagnostic_mode: if True, draws a diagnostic visualization. Should only be used for
        testing, as it slows down performance.
        """
        # Default values to return if no horizon can be found
        roll, pitch, variance, is_good_horizon = None, None, None, None

        # Get grayscale
        bgr2gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # Filter out blue from the sky
        lower = np.array([109, 0, 116])
        upper = np.array([153, 255, 255])
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        hsv_mask = cv2.inRange(hsv, lower, upper)
        blue_filtered_greyscale = cv2.add(bgr2gray, hsv_mask)

        # Generate mask
        blur = cv2.bilateralFilter(blue_filtered_greyscale, 9, 50, 50)
        _, mask = cv2.threshold(blur, 250, 255, cv2.THRESH_OTSU)
        edges = cv2.Canny(image=bgr2gray, threshold1=200, threshold2=250)
        edges = skimage.measure.block_reduce(edges, (POOLING_KERNEL_SIZE, POOLING_KERNEL_SIZE), np.max)

        # Find contours
        contours, _ = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)

        # If no contours found, return None values
        if len(contours) == 0:
            self._predict_next_horizon()
            if diagnostic_mode:
                mask = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)
            return roll, pitch, variance, is_good_horizon, mask

        # Find the largest contour
        largest_contour = sorted(contours, key=cv2.contourArea, reverse=True)[0]

        # Extract x and y values from contour
        x_original = np.array([i[0][0] for i in largest_contour])
        y_original = np.array([i[0][1] for i in largest_contour])

        # Separate edge points from other points
        x_abbr, y_abbr, x_edge_points, y_edge_points = [], [], [], []
        for n, x_point in enumerate(x_original):
            y_point = y_original[n]
            if x_point == 0 or x_point == frame.shape[1] - 1 or y_point == 0 or y_point == frame.shape[0] - 1:
                x_edge_points.append(x_point)
                y_edge_points.append(y_point)
            else:
                x_abbr.append(x_point)
                y_abbr.append(y_point)

        # Reduce the number of edge points for performance
        maximum_number_of_points = 20
        step_size = len(x_edge_points) // maximum_number_of_points
        if step_size > 1:
            x_edge_points = x_edge_points[::step_size]
            y_edge_points = y_edge_points[::step_size]

        # Calculate average position of edge points
        if x_edge_points:
            avg_x = np.average(x_edge_points)
            avg_y = np.average(y_edge_points)
        else:
            avg_x = np.average(x_abbr)
            avg_y = np.average(y_abbr)

        # Reduce the number of horizon points for performance
        maximum_number_of_points = 100
        step_size = len(x_original) // maximum_number_of_points
        if step_size > 1:
            x_abbr = x_abbr[::step_size]
            y_abbr = y_abbr[::step_size]

        # Filter points based on predicted horizon
        x_filtered, y_filtered = [], []
        for idx, x_point in enumerate(x_abbr):
            y_point = y_abbr[idx]
            if edges[y_point // POOLING_KERNEL_SIZE][x_point // POOLING_KERNEL_SIZE] == 0:
                continue
            if self.predicted_roll is None:
                x_filtered.append(x_point)
                y_filtered.append(y_point)
                continue
            p3 = np.array([x_point, y_point])
            distance = norm(np.cross(p2_minus_p1, p1 - p3)) / norm(p2_minus_p1)
            if distance < self.exclusion_thresh_pixels:
                x_filtered.append(x_point)
                y_filtered.append(y_point)

        # Convert to numpy array
        x_filtered = np.array(x_filtered)
        y_filtered = np.array(y_filtered)

        # If too few points, return None
        if x_filtered.shape[0] < 12:
            self._predict_next_horizon()
            return roll, pitch, variance, is_good_horizon, mask

        # Fit a line to the filtered points
        m, b = np.polyfit(x_filtered, y_filtered, 1)
        roll = atan2(m, 1)
        roll = degrees(roll)

        # Determine sky direction
        sky_is_up = 1 if m * avg_x + b > avg_y else 0

        # Calculate pitch
        p1 = np.array([0, b])
        p2 = np.array([frame.shape[1], m * frame.shape[1] + b])
        p3 = np.array([frame.shape[1] // 2, frame.shape[0] // 2])
        distance_to_horizon = norm(np.cross(p2 - p1, p1 - p3)) / norm(p2 - p1)
        plane_pointing_up = 1 if (p3[1] < m * frame.shape[1] // 2 + b and sky_is_up) or (
                p3[1] > m * frame.shape[1] // 2 + b and not sky_is_up) else 0
        pitch = distance_to_horizon / frame.shape[0] * self.fov
        if not plane_pointing_up:
            pitch *= -1

        # Calculate variance
        distance_list = [norm(np.cross(p2 - p1, p1 - np.array([x, y]))) / norm(p2 - p1) for x, y in
                         zip(x_filtered, y_filtered)]
        variance = np.average(distance_list) / frame.shape[0] * 100

        # Adjust roll
        roll = self._adjust_roll(roll, sky_is_up)

        # Determine if horizon is acceptable
        is_good_horizon = 1 if variance < self.acceptable_variance else 0

        # Predict next horizon
        self._predict_next_horizon(roll, pitch, is_good_horizon)

        return roll, pitch, variance, is_good_horizon, mask

    def _adjust_roll(self, roll: float, sky_is_up: bool) -> float:
        """
        Adjusts the roll to be within the range of 0-360 degrees.
        """
        roll = abs(roll % FULL_ROTATION)
        in_sky_is_up_sector = (roll >= FULL_ROTATION * .75 or (roll > 0 and roll <= FULL_ROTATION * .25))
        if sky_is_up == in_sky_is_up_sector:
            return roll
        if roll < FULL_ROTATION / 2:
            roll += FULL_ROTATION / 2
        else:
            roll -= FULL_ROTATION / 2
        return roll

    def _predict_next_horizon(self, current_roll=None, current_pitch=None, is_good_horizon=None):
        """
        Predicts the next horizon based on recent horizons.
        """
        if not is_good_horizon:
            current_horizon = None
        else:
            current_horizon = (current_roll, current_pitch)
        self.recent_horizons.append(current_horizon)
        del self.recent_horizons[0]
        if None in self.recent_horizons:
            self.predicted_roll = None
            self.predicted_pitch = None
        else:
            roll1, roll2 = self.recent_horizons[0][0], self.recent_horizons[1][0]
            pitch1, pitch2 = self.recent_horizons[0][1], self.recent_horizons[1][1]
            self.predicted_roll = roll2 + (roll2 - roll1)
            self.predicted_pitch = pitch2 + (pitch2 - pitch1)


def draw_horizon(frame, roll, pitch, fov, color, draw_text):
    """
    Draws the horizon line on the frame.
    """
    height, width = frame.shape[:2]
    center_x, center_y = width // 2, height // 2
    angle = radians(roll)
    distance = pitch / fov * height
    x1 = int(center_x - 1000 * cos(angle))
    y1 = int(center_y - 1000 * sin(angle) + distance)
    x2 = int(center_x + 1000 * cos(angle))
    y2 = int(center_y + 1000 * sin(angle) + distance)
    cv2.line(frame, (x1, y1), (x2, y2), color, 2)
    if draw_text:
        cv2.putText(frame, f"Roll: {roll:.2f}, Pitch: {pitch:.2f}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)


def main():
    # Initialize OAK-D pipeline
    pipeline = dai.Pipeline()

    # Set up RGB camera
    cam = pipeline.create(dai.node.ColorCamera)
    cam.setPreviewSize(1280, 720)
    cam.setBoardSocket(dai.CameraBoardSocket.RGB)
    cam.setFps(30)

    # Link camera output to XLink
    cam_xout = pipeline.create(dai.node.XLinkOut)
    cam_xout.setStreamName("video")
    cam.preview.link(cam_xout.input)

    # Start the pipeline
    with dai.Device(pipeline) as device:
        video_queue = device.getOutputQueue("video", maxSize=1, blocking=False)

        # Initialize HorizonDetector
        frame_shape = (720, 1280)  # Height, width
        horizon_detector = HorizonDetector(exclusion_thresh=5, fov=48.8, acceptable_variance=1.3, frame_shape=frame_shape)

        print("🎥 Live Horizon Detection Started (Press 'q' to exit)...")

        while True:
            # Get the latest frame from OAK-D
            frame = video_queue.get().getCvFrame()

            # Detect the horizon
            roll, pitch, variance, is_good_horizon, mask = horizon_detector.find_horizon(frame, diagnostic_mode=False)

            # Draw the horizon on the frame
            if roll is not None and pitch is not None:
                draw_horizon(frame, roll, pitch, horizon_detector.fov, (0, 255, 0), True)

            # Display the frame
            cv2.imshow("Live Horizon Detection", frame)

            # Press 'q' to exit
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()