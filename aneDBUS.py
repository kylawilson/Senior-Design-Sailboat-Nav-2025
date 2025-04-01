#dbus
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

class WindSpeedService(dbus.service.Object):
    """D-Bus service that provides the depths of objects in view in base64 format."""

    def __init__(self, bus_name):
        dbus.service.Object.__init__(self, bus_name, '/WindSpeedService')
        self.wind_speed = None  # prob can get rid of this

    @dbus.service.method("com.example.WindSpeedService",
                         in_signature='', out_signature='d')    # returns an array
    def GetDepth(self):
        """Returns the base64-encoded depth if available."""
        print(self.wind_speed)
        if self.wind_speed is not None:         # need to set to None if we're not getting a reading when we set depth_array
            #encoded = base64.b64encode(self.depth_array).decode('utf-8')
            print(f"Sent depth: {self.wind_speed}")
            return self.wind_speed  # Returns an array of floats
        else:
            return 0.0

    def update_wind_speed(self, wind_speed):
        """Updates to the latest depth array."""
        self.wind_speed = wind_speed

def run_dbus_service():
    """Runs the D-Bus main loop in a separate thread."""
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    session_bus = dbus.SessionBus()
    bus_name_wind_speed = dbus.service.BusName("com.example.WindSpeedService", session_bus)
    global wind_speed_service
    wind_speed_service = WindSpeedService(bus_name_wind_speed)
    
    print("D-Bus service running...")
    mainloop = GLib.MainLoop()
    mainloop.run()

dbus_thread = threading.Thread(target=run_dbus_service)
dbus_thread.daemon = True
dbus_thread.start()