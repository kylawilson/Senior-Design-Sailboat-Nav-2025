import RPi.GPIO as GPIO
import time
#dbus
# import dbus
# import dbus.service
# import dbus.mainloop.glib
# from gi.repository import GLib
# import threading


# class WindSpeedService(dbus.service.Object):
#     """D-Bus service that provides the depths of objects in view in base64 format."""

#     def __init__(self, bus_name):
#         dbus.service.Object.__init__(self, bus_name, '/WindSpeedService')
#         self.wind_speed = None  # prob can get rid of this

#     @dbus.service.method("com.example.WindSpeedService",
#                          in_signature='', out_signature='d')    # returns a float
#     def GetWindSpeed(self):
#         """Returns the base64-encoded depth if available."""
#         print(self.wind_speed)
#         if self.wind_speed is not None:         # need to set to None if we're not getting a reading when we set depth_array
#             print(f"Sent wind speed: {self.wind_speed}")
#             return self.wind_speed  # Returns an array of floats
#         else:
#             return 0.0

#     def update_wind_speed(self, wind_speed):
#         """Updates to the latest depth array."""
#         self.wind_speed = wind_speed

# def run_dbus_service():
#     """Runs the D-Bus main loop in a separate thread."""
#     dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
#     session_bus = dbus.SessionBus()
#     bus_name_wind_speed = dbus.service.BusName("com.example.WindSpeedService", session_bus)
#     global wind_speed_service
#     wind_speed_service = WindSpeedService(bus_name_wind_speed)
    
#     print("D-Bus service running...")
#     mainloop = GLib.MainLoop()
#     mainloop.run()

# dbus_thread = threading.Thread(target=run_dbus_service)
# dbus_thread.daemon = True
# dbus_thread.start()

# Pin setup
WIND_SPEED_PIN = 18  # Connect the green wire (wind speed) here
RADIUS = 9.0  # cm, radius of the anemometer cups
ANEMOMETER_FACTOR = 2.4  # Pulses per second per m/s

# Variables
pulse_count = 0
start_time = time.time()

# Interrupt function to count pulses
def count_pulse(channel):
    global pulse_count
    pulse_count += 1

# GPIO setup
GPIO.setmode(GPIO.BCM)
GPIO.setup(WIND_SPEED_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
GPIO.add_event_detect(WIND_SPEED_PIN, GPIO.FALLING, callback=count_pulse)

try:
    while True:
        time.sleep(1)  # Measure every 1 second
        elapsed_time = time.time() - start_time
        wind_speed = (pulse_count / elapsed_time) / ANEMOMETER_FACTOR  # Convert to m/s
        knot_speed = wind_speed * 1.944
        print(f"Wind Speed: {wind_speed:.2f} m/s ({wind_speed * 2.237:.2f} mph) {knot_speed:.2f} knots")
        #wind_speed_service.update_wind_speed(knot_speed)

        #Need to test WRITES TO FILE
        with open('WindSpeed.txt', 'w') as file:
            file.write(f"{knot_speed:.2f}")
        
        # Reset for next measurement
        pulse_count = 0
        start_time = time.time()

except KeyboardInterrupt:
    print("Stopping...")
    GPIO.cleanup()
