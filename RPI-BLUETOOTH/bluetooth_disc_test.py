import sys
import time
import dbus
import dbus.mainloop.glib
import gi
gi.require_version('GLib', '2.0')
from gi.repository import GLib

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


def subscribe_to_notifications(char_path):
    """Subscribes to notifications for a characteristic."""
    if not char_path:
        print("Target characteristic not found.")
        return

    char = bus.get_object(BLUEZ_SERVICE_NAME, char_path)
    char_iface = dbus.Interface(char, GATT_CHARACTERISTIC_IFACE)

    def on_characteristic_changed(value):
        notification_callback(value)

    char_iface.connect_to_signal("PropertiesChanged", on_characteristic_changed)
    char_iface.StartNotify()
    print(f"Subscribed to notifications on {char_path}.")

    # Keep the event loop running
    global mainloop
    mainloop.run()


def main():
    global bus, mainloop

    # Set up D-Bus main loop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
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

