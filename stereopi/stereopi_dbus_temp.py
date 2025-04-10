#DBUS
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import threading

class DepthService(dbus.service.Object):
    """D-Bus service that provides the depths of objects in view in base64 format."""

    def __init__(self, bus_name):
        dbus.service.Object.__init__(self, bus_name, '/DepthService')
        self.depth = None  

    @dbus.service.method("com.example.DepthService",
                         in_signature='', out_signature='ad')    # returns an array
    def GetDepth(self):
        """Returns the base64-encoded depth if available."""
        print(self.depth)
        if self.depth is not None:         # need to set to None if we're not getting a reading when we set depth_array
            print(f"Sent depth: {self.depth}")
            return self.depth  # Returns an array of floats containing the depth repeated in 1x10 array
        else:
            return [1.0, 2.0, 3.0, 4.0]

    def update_depth(self, depth):
        """Updates to the latest depth array."""
        self.depth = depth

def run_dbus_service():
    """Runs the D-Bus main loop in a separate thread."""
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    session_bus = dbus.SessionBus()
    bus_name_depth = dbus.service.BusName("com.example.DepthService", session_bus)
    global depth_service
    depth_service = DepthService(bus_name_depth)
    
    print("D-Bus service running...")
    mainloop = GLib.MainLoop()
    mainloop.run()

# dbus_thread = threading.Thread(target=run_dbus_service)
# dbus_thread.daemon = True
# dbus_thread.start()