# BLUEZ example code

#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1-or-later
#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1-or-later

# Import necessary libraries
from __future__ import print_function

import argparse  # For parsing command-line arguments
import dbus  # For interacting with the D-Bus system bus
import dbus.exceptions  # For handling D-Bus exceptions
import dbus.mainloop.glib  # For integrating D-Bus with the GLib event loop
import dbus.service  # For creating D-Bus services
import time  # For time-related functions
import threading  # For running operations in a separate thread

# Try importing GObject for GLib integration, depending on Python version
try:
    from gi.repository import GObject  # python3
except ImportError:
    import gobject as GObject  # python2

# Global variable for the GLib main loop
mainloop = None

# Constants for BlueZ and D-Bus interfaces
BLUEZ_SERVICE_NAME = 'org.bluez'
LE_ADVERTISING_MANAGER_IFACE = 'org.bluez.LEAdvertisingManager1'
DBUS_OM_IFACE = 'org.freedesktop.DBus.ObjectManager'
DBUS_PROP_IFACE = 'org.freedesktop.DBus.Properties'
LE_ADVERTISEMENT_IFACE = 'org.bluez.LEAdvertisement1'

# Custom exception classes for specific Bluetooth errors
class InvalidArgsException(dbus.exceptions.DBusException):
    _dbus_error_name = 'org.freedesktop.DBus.Error.InvalidArgs'


class NotSupportedException(dbus.exceptions.DBusException):
    _dbus_error_name = 'org.bluez.Error.NotSupported'


class NotPermittedException(dbus.exceptions.DBusException):
    _dbus_error_name = 'org.bluez.Error.NotPermitted'


class InvalidValueLengthException(dbus.exceptions.DBusException):
    _dbus_error_name = 'org.bluez.Error.InvalidValueLength'


class FailedException(dbus.exceptions.DBusException):
    _dbus_error_name = 'org.bluez.Error.Failed'

# Represents a BLE advertisement
class Advertisement(dbus.service.Object):
    PATH_BASE = '/org/bluez/example/advertisement'

    def __init__(self, bus, index, advertising_type):
        # Initialize advertisement properties
        self.path = self.PATH_BASE + str(index)
        self.bus = bus
        self.ad_type = advertising_type
        self.service_uuids = None
        self.manufacturer_data = None
        self.solicit_uuids = None
        self.service_data = None
        self.local_name = None
        self.include_tx_power = False
        self.data = None
        # Register the advertisement as a D-Bus object
        dbus.service.Object.__init__(self, bus, self.path)

    def get_properties(self):
        # Returns the advertisement properties
        properties = dict()
        properties['Type'] = self.ad_type
        if self.service_uuids is not None:
            properties['ServiceUUIDs'] = dbus.Array(self.service_uuids, signature='s')
        if self.solicit_uuids is not None:
            properties['SolicitUUIDs'] = dbus.Array(self.solicit_uuids, signature='s')
        if self.manufacturer_data is not None:
            properties['ManufacturerData'] = dbus.Dictionary(self.manufacturer_data, signature='qv')
        if self.service_data is not None:
            properties['ServiceData'] = dbus.Dictionary(self.service_data, signature='sv')
        if self.local_name is not None:
            properties['LocalName'] = dbus.String(self.local_name)
        if self.include_tx_power:
            properties['Includes'] = dbus.Array(["tx-power"], signature='s')
        if self.data is not None:
            properties['Data'] = dbus.Dictionary(self.data, signature='yv')
        return {LE_ADVERTISEMENT_IFACE: properties}

    def get_path(self):
        # Returns the D-Bus path for the advertisement
        return dbus.ObjectPath(self.path)

    # Add utility methods for setting various advertisement properties
    def add_service_uuid(self, uuid):
        if not self.service_uuids:
            self.service_uuids = []
        self.service_uuids.append(uuid)

    def add_solicit_uuid(self, uuid):
        if not self.solicit_uuids:
            self.solicit_uuids = []
        self.solicit_uuids.append(uuid)

    def add_manufacturer_data(self, manuf_code, data):
        if not self.manufacturer_data:
            self.manufacturer_data = dbus.Dictionary({}, signature='qv')
        self.manufacturer_data[manuf_code] = dbus.Array(data, signature='y')

    def add_service_data(self, uuid, data):
        if not self.service_data:
            self.service_data = dbus.Dictionary({}, signature='sv')
        self.service_data[uuid] = dbus.Array(data, signature='y')

    def add_local_name(self, name):
        if not self.local_name:
            self.local_name = ""
        self.local_name = dbus.String(name)

    def add_data(self, ad_type, data):
        if not self.data:
            self.data = dbus.Dictionary({}, signature='yv')
        self.data[ad_type] = dbus.Array(data, signature='y')

    # D-Bus method to get all properties for the advertisement
    @dbus.service.method(DBUS_PROP_IFACE,
                         in_signature='s',
                         out_signature='a{sv}')
    def GetAll(self, interface):
        if interface != LE_ADVERTISEMENT_IFACE:
            raise InvalidArgsException()
        return self.get_properties()[LE_ADVERTISEMENT_IFACE]

    # D-Bus method to release the advertisement
    @dbus.service.method(LE_ADVERTISEMENT_IFACE,
                         in_signature='',
                         out_signature='')
    def Release(self):
        print('%s: Released!' % self.path)

# Subclass of Advertisement with predefined properties for testing
class TestAdvertisement(Advertisement):
    def __init__(self, bus, index):
        Advertisement.__init__(self, bus, index, 'peripheral')
        self.add_service_uuid('180D')  # Heart Rate Service UUID
        self.add_service_uuid('180F')  # Battery Service UUID
        self.add_manufacturer_data(0xffff, [0x00, 0x01, 0x02, 0x03])  # Example manufacturer data
        self.add_service_data('9999', [0x00, 0x01, 0x02, 0x03, 0x04])  # Example service data
        self.add_local_name('TRITON')  # Local name of the device
        self.include_tx_power = True  # Include TX power level
        self.add_data(0x26, [0x01, 0x01, 0x00])  # Example additional data

# Callback for successful advertisement registration
def register_ad_cb():
    print('Advertisement registered')

# Callback for advertisement registration failure
def register_ad_error_cb(error):
    print('Failed to register advertisement: ' + str(error))
    mainloop.quit()

# Utility function to find the LE Advertising Manager on the adapter
def find_adapter(bus):
    remote_om = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, '/'),
                               DBUS_OM_IFACE)
    objects = remote_om.GetManagedObjects()
    for o, props in objects.items():
        if LE_ADVERTISING_MANAGER_IFACE in props:
            return o
    return None

# Function to shut down the main loop after a timeout
def shutdown(timeout):
    print('Advertising for {} seconds...'.format(timeout))
    time.sleep(timeout)
    mainloop.quit()

# Define GATT services and characteristics below...
class GattApplication(dbus.service.Object):
    """Gatt Application wrapper to manage services."""
    PATH_BASE = "/org/bluez/example/service"

    def __init__(self, bus):
        self.path = self.PATH_BASE
        self.services = []
        dbus.service.Object.__init__(self, bus, self.path)

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_service(self, service):
        self.services.append(service)


class GattService(dbus.service.Object):
    """A GATT service."""
    def __init__(self, bus, index, uuid, primary):
        self.path = GattApplication.PATH_BASE + str(index)
        self.bus = bus
        self.uuid = uuid
        self.primary = primary
        self.characteristics = []
        dbus.service.Object.__init__(self, bus, self.path)

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_characteristic(self, characteristic):
        self.characteristics.append(characteristic)


class GattCharacteristic(dbus.service.Object):
    """A GATT characteristic."""
    def __init__(self, bus, index, uuid, flags, service):
        self.path = service.path + "/char" + str(index)
        self.bus = bus
        self.uuid = uuid
        self.flags = flags
        self.service = service
        dbus.service.Object.__init__(self, bus, self.path)

    def get_path(self):
        return dbus.ObjectPath(self.path)

    @dbus.service.method(DBUS_PROP_IFACE,
                         in_signature='s',
                         out_signature='a{sv}')
    def GetAll(self, interface):
        if interface != 'org.bluez.GattCharacteristic1':
            raise InvalidArgsException()

        return {
            'UUID': self.uuid,
            'Service': self.service.get_path(),
            'Flags': self.flags
        }

    @dbus.service.method('org.bluez.GattCharacteristic1',
                         in_signature='',
                         out_signature='')
    def StartNotify(self):
        print("Central connected: Sending 'Hello World'")
        # Simulate sending a notification
        self.send_notification("Hello World")

    def send_notification(self, message):
        print(f"Notification sent: {message}")


class HelloWorldService(GattService):
    """A GATT service that sends 'Hello World'."""
    HELLO_WORLD_UUID = "ec2ce16f-f774-4c1f-b3dd-a56b64bc9037"

    def __init__(self, bus, index):
        GattService.__init__(self, bus, index, self.HELLO_WORLD_UUID, True)
        self.add_characteristic(HelloWorldCharacteristic(bus, 0, self))


class HelloWorldCharacteristic(GattCharacteristic):
    """A characteristic to notify 'Hello World'."""
    HELLO_WORLD_CHAR_UUID = "842c3d51-9599-4c9c-aa41-15a28cb48bce"

    def __init__(self, bus, index, service):
        GattCharacteristic.__init__(self, bus, index,
                                     self.HELLO_WORLD_CHAR_UUID,
                                     ['notify', 'read'], service)


def main(timeout=0):
    global mainloop

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    adapter = find_adapter(bus)
    if not adapter:
        print('LEAdvertisingManager1 interface not found')
        return

    adapter_props = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                                   "org.freedesktop.DBus.Properties")

    adapter_props.Set("org.bluez.Adapter1", "Powered", dbus.Boolean(1))

    ad_manager = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                                LE_ADVERTISING_MANAGER_IFACE)

    test_advertisement = TestAdvertisement(bus, 0)
    mainloop = GObject.MainLoop()

    ad_manager.RegisterAdvertisement(test_advertisement.get_path(), {},
                                     reply_handler=register_ad_cb,
                                     error_handler=register_ad_error_cb)

    # Add the GATT service for notifications
    gatt_manager = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                                   "org.bluez.GattManager1")
    app = GattApplication(bus)
    hello_world_service = HelloWorldService(bus, 0)
    app.add_service(hello_world_service)

    # Register the GATT application
    gatt_manager.RegisterApplication(app.get_path(), {},
                                     reply_handler=register_ad_cb,
                                     error_handler=register_ad_error_cb)


    if timeout > 0:
        threading.Thread(target=shutdown, args=(timeout,)).start()
    else:
        print('Advertising and serving GATT forever...')

    mainloop.run()  # blocks until mainloop.quit() is called

    ad_manager.UnregisterAdvertisement(test_advertisement)
    print('Advertisement unregistered')
    dbus.service.Object.remove_from_connection(test_advertisement)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--timeout', default=0, type=int, help="advertise " +
                        "for this many seconds then stop, 0=run forever " +
                        "(default: 0)")
    args = parser.parse_args()

    main(args.timeout)