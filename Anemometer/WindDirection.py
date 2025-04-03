import board
import busio
import adafruit_ads1x15.ads1115 as ADS
from adafruit_ads1x15.analog_in import AnalogIn
import time

# I2C setup
i2c = busio.I2C(board.SCL, board.SDA)
ads = ADS.ADS1115(i2c)
ads.gain = 1  # ±4.096V range (good for 0-3.3V)

# Constants for voltage divider calculation
V_IN = 3.3  # Input voltage (from 3.3V pin of Raspberry Pi)
R_FIXED = 10000  # Fixed resistor (10kΩ)

# Last known direction
last_direction = "Unknown"

# Resistance ranges for each direction
resistance_to_direction = [
    ("N", 601, 609.4),   # N range: 601-607 ohms
    ("NE", 560, 578),  # NE range: 560-575 ohms
    ("E", 355, 390),   # E range: 355-390 ohms
    ("SE", 475, 490),  # SE range: 475-490 ohms
    ("S", 510, 540),   # S range: 510-540 ohms
    ("SW", 580, 600),  # SW range: 580-600 ohms
    ("W", 614.5, 620),   # W range: 613-620 ohms
    ("NW", 609.5, 614.4),  # NW range: 608-613 ohms
]

def voltage_to_resistance(voltage):
    """ Converts ADC voltage to sensor resistance. """
    if voltage <= 0 or voltage >= V_IN:  # Avoid divide by zero
        return None
    resistance = (R_FIXED * voltage) / (V_IN - voltage)
    return resistance

def resistance_to_wind_direction(resistance):
    """ Maps resistance to wind direction based on defined ranges. """
    global last_direction  # Use global to track last known value

    if resistance is None:
        #  print("Error: Invalid resistance value")
        return last_direction  # If resistance is invalid, return last known direction
    
    for direction, min_res, max_res in resistance_to_direction:
        if min_res <= resistance <= max_res:
            if direction != last_direction:
               print(f"Direction changed: {last_direction} → {direction}")
            last_direction = direction  # Update last known direction
            return direction

    #print("Warning: Resistance out of range, keeping last known direction")
    return last_direction  # If no match, return last known direction

while True:
    # Read ADC input from A1
    wind_direction = AnalogIn(ads, ADS.P0)
    voltage = wind_direction.voltage
    
    # Convert voltage to resistance
    resistance = voltage_to_resistance(voltage)
    
    # Determine wind direction
    direction = resistance_to_wind_direction(resistance)
    
    # Print debugging info
   # print(f"Voltage: {voltage:.3f}V | Resistance: {resistance:.1f}Ω | Direction: {direction}")
    print(f"Voltage: {voltage:.3f}V | Resistance: {resistance:.1f}Ω | Direction: {direction}" if resistance is not None else f"Voltage: {voltage:.3f}V | Resistance: N/A | Direction: {direction}")

    time.sleep(1)  # Delay for stability
