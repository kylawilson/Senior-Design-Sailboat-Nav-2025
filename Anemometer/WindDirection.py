import time
import board
import busio
import adafruit_ads1x15.ads1115 as ADS
from adafruit_ads1x15.analog_in import AnalogIn

# I2C setup for ADS1115
i2c = busio.I2C(board.SCL, board.SDA)
ads = ADS.ADS1115(i2c)
ads.gain = 1  # ±4.096V range (Good for 0-3.3V)

# Wind vane resistance lookup table (based on the datasheet and provided resistance values)
# Updated tolerances for resistance values with smaller tolerances
resistance_to_angle = [
    ("N", 682, 693),   # N range: 691 ohms, tolerance ±5 ohms
    ("NE", 635, 655),  # NE range: 650 ohms, tolerance ±5 ohms
    ("E", 390, 420),   # E range: 415 ohms, tolerance ±5 ohms
    ("SE", 535, 580),  # SE range: 536 ohms, tolerance ±5 ohms
    ("S", 590, 610),   # S range: 599 ohms, tolerance ±5 ohms
    ("SW", 670, 680),  # SW range: 676 ohms, tolerance ±5 ohms
    ("W", 700, 707),   # W range: 702 ohms, tolerance ±5 ohms
    ("NW", 694, 698),  # NW range: 698 ohms, tolerance ±5 ohms
]

def read_wind_direction():
    """ Reads voltage from ADS1115 and calculates wind direction based on resistance """
    chan = AnalogIn(ads, ADS.P0)  # Reading from A1
    v_measured = chan.voltage  # Voltage from ADC

    # Convert voltage to resistance using the voltage divider formula
    R_FIXED = 10000  # 10kΩ pull-up resistor
    if v_measured > 0:  # Prevent divide-by-zero error
        r_vane = (v_measured / (3.3 - v_measured)) * R_FIXED
    else:
        r_vane = None

    # Initialize default values for angle and direction
    angle = None
    direction = None

    # Find the closest direction based on resistance with tight tolerance ranges
    if r_vane is not None:
        for i in range(len(resistance_to_angle)):
            direction, min_resistance, max_resistance = resistance_to_angle[i]
            if min_resistance <= r_vane <= max_resistance:
                angle = direction
                break  # Once we find the first match, stop

    return v_measured, r_vane, angle

# Continuous reading loop
last_direction = None  # Initialize a variable to store the last valid direction
while True:
    v, r, angle = read_wind_direction()

    # If no direction found, keep the last direction output
    if angle is None:
        angle = last_direction

    # Update the last valid direction
    if angle is not None:
        last_direction = angle

    print(f"Voltage: {v:.2f}V | Resistance: {r:.0f}Ω | Direction: {angle}")
    time.sleep(1)  # Delay for readability
