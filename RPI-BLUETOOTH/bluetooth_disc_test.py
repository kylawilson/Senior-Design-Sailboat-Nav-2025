import sys
import time
import dbus
import argparse
import dbus.mainloop.glib
import gi
gi.require_version('GLib', '2.0')
from gi.repository import GLib

# Constants
BLUEZ_SERVICE_NAME = "org.bluez"
DBUS_OM_IFACE = "org.freedesktop.DBus.ObjectManager"
DBUS_PROP_IFACE = "org.freedesktop.DBus.Properties"
GATT_SERVICE_IFACE = "org.bluez.GattService1"
DEPTH_SVC_UUID = "12345678-1234-5678-1234-56789abcdef0"  # Replace with actual UUID

# Global Variables
bus = None
mainloop = None
depth_service = None


def connect_device(device_path):
    """Ensures the Bluetooth device is connected before proceeding."""
    device = bus.get_object(BLUEZ_SERVICE_NAME, device_path)
    device_iface = dbus.Interface(device, "org.bluez.Device1")
    props_iface = dbus.Interface(device, DBUS_PROP_IFACE)

    # Check if already connected
    connected = props_iface.Get("org.bluez.Device1", "Connected")

    if not connected:
        print(f"Connecting to device {device_path}...")
        device_iface.Connect()
        time.sleep(2)  # Wait for connection
        connected = props_iface.Get("org.bluez.Device1", "Connected")
    
    if connected:
        print("Device connected successfully!")
    else:
        print("Failed to connect.")
        sys.exit(1)


def process_chrc(chrc_path):
    """Placeholder function to process characteristics."""
    print(f"Processing characteristic: {chrc_path}")


def process_depth_service(service_path):
    """Processes the GATT Depth Service, checking UUID and handling characteristics."""
    global depth_service

    service = bus.get_object(BLUEZ_SERVICE_NAME, service_path)
    service_props_iface = dbus.Interface(service, DBUS_PROP_IFACE)
    service_props = service_props_iface.GetAll(GATT_SERVICE_IFACE)

    uuid = service_props['UUID']

    if uuid != DEPTH_SVC_UUID:
        print(f"Service is not a Depth Service: {uuid}")
        return False

    # Process characteristics
    chrc_paths = service_props.get('Characteristics', [])
    for chrc_path in chrc_paths:
        process_chrc(chrc_path)

    depth_service = (service, service_props, service_path)
    print("Depth Service successfully processed.")
    return True


def main():
    global bus, mainloop

    # Parse arguments
    parser = argparse.ArgumentParser(description="D-Bus Depth Service client example")
    parser.add_argument('service_path', metavar='<service-path>', type=str, nargs=1,
                        help='GATT service object path')
    args = parser.parse_args()
    service_path = args.service_path[0]

    # Set up D-Bus main loop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    mainloop = GLib.MainLoop()

    # Extract device path from service path
    device_path_parts = service_path.split('/service')[0]
    device_path = device_path_parts  # Example: "/org/bluez/hci0/dev_xx_xx_xx_xx_xx_xx"

    # Ensure the device is connected
    connect_device(device_path)

    # Process the depth service
    if not process_depth_service(service_path):
        sys.exit(1)

    print("Depth Service ready. Listening for updates...")
    mainloop.run()


if __name__ == '__main__':
    main()

