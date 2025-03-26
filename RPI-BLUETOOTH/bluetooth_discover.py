import sys
import time
import dbus
import dbus.mainloop.glib
import gi
gi.require_version('GLib', '2.0')
from gi.repository import GLib
import dbus.service

# Constants
BLUEZ_SERVICE_NAME = "org.bluez"
ADAPTER_PATH = "/org/bluez/hci0"
DEVICE_INTERFACE = "org.bluez.Device1"
GATT_CHARACTERISTIC_IFACE = "org.bluez.GattCharacteristic1"

# Test parameters, change for triton
TARGET_DEVICE_NAME = "Kyla Phone Test"
TARGET_SERVICE_UUID = "00001801-0000-1000-8000-00805f9b34fb"
TARGET_CHARACTERISTIC_UUID = "00002a05-0000-1000-8000-00805f9b34fb"

# Global variables
bus = None
mainloop = None
depth_array = None

class StereoPiDepthService(dbus.service.Object):
    """D-Bus service that provides the depths of objects in stereo pi's view in base64 format."""

    def __init__(self, bus_name):
        dbus.service.Object.__init__(self, bus_name, '/StereoPiDepthService')
        self.latest_depth_array = None 

    @dbus.service.method("com.example.StereoPiDepthService",
                         in_signature='', out_signature='s')    # returns a string
    def GetDepth(self):
        """Returns the base64-encoded depth if available."""
        if depth_array is None:         # need to set to None if we're not getting a reading when we set depth_array
            encoded = base64.b64encode(depth_array).decode('utf-8')
            print(f"Sent encoded image: {self.latest_depth_array}")
            return encoded  # Returns the base64 string
        else:
            return "No depths available"

    def update_latest_array(self, depth_array):
        """Updates to the latest depth array."""
        self.latest_depth_array = depth_array


def find_device():
    """Scans for BLE devices and returns the correct device path."""
    adapter = bus.get_object(BLUEZ_SERVICE_NAME, ADAPTER_PATH)
    adapter_methods = dbus.Interface(adapter, "org.freedesktop.DBus.Properties")

    # Start scanning
    adapter_methods.Set("org.bluez.Adapter1", "Powered", dbus.Boolean(1))
    adapter_methods.Set("org.bluez.Adapter1", "Discoverable", dbus.Boolean(1))
    adapter_methods.Set("org.bluez.Adapter1", "Pairable", dbus.Boolean(1))

    adapter_iface = dbus.Interface(adapter, "org.bluez.Adapter1")
    adapter_iface.StartDiscovery()
    
    print("Scanning for BLE devices...")
    time.sleep(5)  # Scan for 5 seconds
    adapter_iface.StopDiscovery()

    # Get discovered devices
    om = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, "/"), "org.freedesktop.DBus.ObjectManager")
    objects = om.GetManagedObjects()

    for path, interfaces in objects.items():
        if DEVICE_INTERFACE in interfaces:
            properties = interfaces[DEVICE_INTERFACE]
            name = properties.get("Name", "")
            print(f"Found target device: {name} ({path})")

            if TARGET_DEVICE_NAME in name:
                print(f"Found target device: {name} ({path})")
                return path

    print("Target device not found.")
    return None


def connect_device(device_path):
    """Connects to the BLE device."""
    device = bus.get_object(BLUEZ_SERVICE_NAME, device_path)
    device_iface = dbus.Interface(device, DEVICE_INTERFACE)

    # Connect if not already connected
    props_iface = dbus.Interface(device, "org.freedesktop.DBus.Properties")
    connected = props_iface.Get(DEVICE_INTERFACE, "Connected")

    if not connected:
        print(f"Connecting to {device_path}...")
        device_iface.Connect()
        time.sleep(2)  # Wait for connection

        connected = props_iface.Get(DEVICE_INTERFACE, "Connected")
        if connected:
            print("Connected successfully!")
        else:
            print("Failed to connect.")
            sys.exit(1)


def discover_services(device_path):
    """Discovers and prints available services and characteristics."""
    om = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, "/"), "org.freedesktop.DBus.ObjectManager")
    objects = om.GetManagedObjects()

    target_characteristic = None

    for path, interfaces in objects.items():
        if "org.bluez.GattService1" in interfaces:
            service_uuid = interfaces["org.bluez.GattService1"]["UUID"]
            print(f"Service: {service_uuid} ({path})")


            if service_uuid == TARGET_SERVICE_UUID:
                print(f"Service UUID == TARGET_SERVICE_UUID")
                for char_path, char_interfaces in objects.items():
                    if "org.bluez.GattCharacteristic1" in char_interfaces:
                        service_path = char_path.rsplit("/", 1)[0]
                        if service_path == path:
                            char_uuid = char_interfaces["org.bluez.GattCharacteristic1"]["UUID"]
                            print(f"  Characteristic: {char_uuid} ({char_path})")

                            if char_uuid == TARGET_CHARACTERISTIC_UUID:
                                target_characteristic = char_path

    return target_characteristic


def notification_callback(value):
    """Handles received BLE notifications."""
    print(f"Notification received: {value}")
    # Change this depending on formatting
    depth_array = value
    


def subscribe_to_notifications(char_path):
    """Subscribes to notifications for a characteristic."""
    if not char_path:
        print("Target characteristic not found.")
        return

    char = bus.get_object(BLUEZ_SERVICE_NAME, char_path)
    char_iface = dbus.Interface(char, GATT_CHARACTERISTIC_IFACE)


    #test notification changing functionality
    def on_characteristic_changed(value):
        notification_callback(value)

    char_iface.connect_to_signal("PropertiesChanged", on_characteristic_changed)
    char_iface.StartNotify()
    print(f"Subscribed to notifications on {char_path}.")

    # Keep the event loop running
    global mainloop
    mainloop.run()


def main():
    global bus, mainloop, depth_service

    # Set up D-Bus main loop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    session_bus = dbus.SessionBus()
    bus = dbus.SystemBus()
    bus_name_depth = dbus.service.BusName("com.example.StereoPiDepthService", session_bus)
    depth_service = StereoPiDepthService(bus_name_depth)
    mainloop = GLib.MainLoop()

    # Find and connect to the target device
    device_path = find_device()
    if not device_path:
        sys.exit(1)

    connect_device(device_path)

    # Discover services and characteristics
    char_path = discover_services(device_path)

    # Subscribe to notifications
    subscribe_to_notifications(char_path)


if __name__ == "__main__":
    main()

