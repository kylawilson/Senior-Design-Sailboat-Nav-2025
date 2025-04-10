import board
import busio
import adafruit_ads1x15.ads1115 as ADS
from adafruit_ads1x15.analog_in import AnalogIn
import time
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import threading

# === D-Bus Service ===
class WindDirectionService(dbus.service.Object):
    def __init__(self, bus_name):
        dbus.service.Object.__init__(self, bus_name, '/WindDirectionService')
        self.wind_direction = None

    @dbus.service.method("com.example.WindDirectionService",
                         in_signature='', out_signature='s')
    def GetWindDirection(self):
        print(self.wind_direction)
        if self.wind_direction is not None:
            print(f"Sent wind direction: {self.wind_direction}")
            return self.wind_direction
        else:
            return "Unknown"

    def update_wind_direction(self, wind_direction):
        self.wind_direction = wind_direction

def run_dbus_service():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    session_bus = dbus.SessionBus()
    bus_name = dbus.service.BusName("com.example.WindDirectionService", session_bus)
    global wind_direction_service
    wind_direction_service = WindDirectionService(bus_name)
    # print("D-Bus service running...")
    mainloop = GLib.MainLoop()
    mainloop.run()

# === Start D-Bus thread ===
dbus_thread = threading.Thread(target=run_dbus_service)
dbus_thread.daemon = True
dbus_thread.start()

# === I2C and ADC Setup ===
i2c = busio.I2C(board.SCL, board.SDA)
ads = ADS.ADS1115(i2c)
ads.gain = 1  # ±4.096V range

# === Constants ===
V_IN = 3.3  # Input voltage
R_FIXED = 10000  # 10k ohm fixed resistor

# Resistance ranges for each direction (hardcoded)
resistance_to_direction = [
    ("N", 644, 646),
    ("NE", 608, 611),
    ("E", 394, 396),
    ("SE", 505, 506),
    ("S", 562, 564),
    ("SW", 628, 633),
    ("W", 654, 656),
    ("NW", 648, 652),
]

last_direction = "Unknown"

# === Helper Functions ===
def voltage_to_resistance(voltage):
    if voltage <= 0 or voltage >= V_IN:
        return None
    resistance = (R_FIXED * voltage) / (V_IN - voltage)
    return resistance

def resistance_to_wind_direction(resistance):
    global last_direction
    if resistance is None:
        return last_direction

    for direction, min_res, max_res in resistance_to_direction:
        if min_res <= resistance <= max_res:
            if direction != last_direction:
                print(f"Direction changed: {last_direction} → {direction}")
            last_direction = direction
            return direction

    return last_direction

# === Main Loop with Averaging ===
SAMPLES = 15  # Number of samples per reading
DELAY_BETWEEN_SAMPLES = 0.05  # Time between samples (seconds)

while True:
    resistances = []

    for _ in range(SAMPLES):
        analog = AnalogIn(ads, ADS.P0)
        voltage = analog.voltage
        resistance = voltage_to_resistance(voltage)
        if resistance is not None:
            resistances.append(resistance)
        time.sleep(DELAY_BETWEEN_SAMPLES)

    if resistances:
        avg_resistance = sum(resistances) / len(resistances)
        direction = resistance_to_wind_direction(avg_resistance)
        print(f"Averaged Resistance: {avg_resistance:.1f}Ω | Direction: {direction}")
        wind_direction_service.update_wind_direction(direction)
    else:
        print("No valid resistance readings.")

    time.sleep(1)
