import time
import board
import busio
import adafruit_ads1x15.ads1115 as ADS
from adafruit_ads1x15.analog_in import AnalogIn

# I2C setup for ADS1115
i2c = busio.I2C(board.SCL, board.SDA)
ads = ADS.ADS1115(i2c)
ads.gain = 1  # ±4.096V range (Good for 0-3.3V)

# Known offset in voltage readings
VOLTAGE_OFFSET = 0.4  # Adjust for the measured offset

# Wind vane resistance lookup table (from datasheet)
resistance_to_angle = [
    (0, 682, 693),   # N
    (45, 635, 655),  # NE
    (90, 390, 420),  # E
    (135, 535, 580), # SE
    (180, 590, 610), # S
    (225, 670, 680), # SW
    (270, 700, 707), # W
    (315, 694, 698), # NW
]

# Direction labels
angle_to_direction = {
    0: "N", 45: "NE", 90: "E", 135: "SE",
    180: "S", 225: "SW", 270: "W", 315: "NW"
}

def read_wind_direction():
    """ Reads voltage from ADS1115 and calculates wind direction based on resistance. """
    chan = AnalogIn(ads, ADS.P0)  # Reading from A1
    v_measured = chan.voltage  # Voltage from ADC

    # Adjust voltage based on known offset
    adjusted_voltage = v_measured + VOLTAGE_OFFSET

    # Convert voltage to resistance using the voltage divider formula
    R_FIXED = 10000  # 10kΩ pull-up resistor
    if adjusted_voltage > 0 and adjusted_voltage < 3.3:  # Prevent divide-by-zero error
        r_vane = (adjusted_voltage / (3.3 - adjusted_voltage)) * R_FIXED
    else:
        r_vane = None

    # Initialize default values
    angle = None
    direction = None

    # Find the closest matching direction
    if r_vane is not None:
        for i in range(len(resistance_to_angle)):
            angle_candidate, min_resistance, max_resistance = resistance_to_angle[i]
            if min_resistance <= r_vane <= max_resistance:
                angle = angle_candidate
                direction = angle_to_direction[angle]
                break  # Stop after first match

    return adjusted_voltage, r_vane, angle, direction

# Continuous reading loop
while True:
    voltage, resistance, angle, direction = read_wind_direction()

    if angle is None:
        print(f"Voltage: {voltage:.2f}V | Resistance: {resistance:.0f}Ω | Direction: UNKNOWN")
    else:
        print(f"Voltage: {voltage:.2f}V | Resistance: {resistance:.0f}Ω | Angle: {angle}° | Direction: {direction}")

    time.sleep(0.5)  # Faster updates
