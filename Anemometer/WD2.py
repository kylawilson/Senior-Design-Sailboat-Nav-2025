import board
import busio
import adafruit_ads1x15.ads1115 as ADS
from adafruit_ads1x15.analog_in import AnalogIn
import time

# I2C setup
i2c = busio.I2C(board.SCL, board.SDA)
ads = ADS.ADS1115(i2c)
ads.gain = 1  # ±4.096V range (good for 0-3.3V)

def voltage_to_wind_direction(voltage):
    # Lookup table based on resistance/voltage conversion
    direction_table = {
        0.4: "N", 0.9: "NE", 1.4: "E", 1.8: "SE",
        2.3: "S", 2.7: "SW", 3.2: "W", 3.6: "NW"
    }
    closest_voltage = min(direction_table.keys(), key=lambda v: abs(v - voltage))
    return direction_table[closest_voltage]

while True:
    wind_direction = AnalogIn(ads, ADS.P1)  # Read from A1
    voltage = wind_direction.voltage  
    wind_dir = voltage_to_wind_direction(voltage)

    print(f"Wind Direction: {wind_dir} (Voltage: {voltage:.2f}V)")
    time.sleep(0.5)  # Delay for stability
