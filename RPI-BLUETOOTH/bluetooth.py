#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1-or-later

import argparse
import dbus
import dbus.exceptions
import dbus.mainloop.glib
import dbus.service
import time
import threading
import struct

import array
from gi.repository import GLib
import sys

try:
    from gi.repository import GObject  # python3
except ImportError:
    import gobject as GObject  # python2

from random import randint

mainloop = None

BLUEZ_SERVICE_NAME = 'org.bluez'
GATT_MANAGER_IFACE = 'org.bluez.GattManager1'
LE_ADVERTISING_MANAGER_IFACE = 'org.bluez.LEAdvertisingManager1'
DBUS_OM_IFACE =      'org.freedesktop.DBus.ObjectManager'
DBUS_PROP_IFACE =    'org.freedesktop.DBus.Properties'

GATT_SERVICE_IFACE = 'org.bluez.GattService1'
GATT_CHRC_IFACE =    'org.bluez.GattCharacteristic1'
GATT_DESC_IFACE =    'org.bluez.GattDescriptor1'
LE_ADVERTISEMENT_IFACE = 'org.bluez.LEAdvertisement1'

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


class Advertisement(dbus.service.Object):
    PATH_BASE = '/org/bluez/example/advertisement'

    def __init__(self, bus, index, advertising_type):
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
        dbus.service.Object.__init__(self, bus, self.path)

    def get_properties(self):
        properties = dict()
        properties['Type'] = self.ad_type
        if self.service_uuids is not None:
            properties['ServiceUUIDs'] = dbus.Array(self.service_uuids,
                                                    signature='s')
        if self.solicit_uuids is not None:
            properties['SolicitUUIDs'] = dbus.Array(self.solicit_uuids,
                                                    signature='s')
        if self.manufacturer_data is not None:
            properties['ManufacturerData'] = dbus.Dictionary(
                self.manufacturer_data, signature='qv')
        if self.service_data is not None:
            properties['ServiceData'] = dbus.Dictionary(self.service_data,
                                                        signature='sv')
        if self.local_name is not None:
            properties['LocalName'] = dbus.String(self.local_name)
        if self.include_tx_power:
            properties['Includes'] = dbus.Array(["tx-power"], signature='s')

        if self.data is not None:
            properties['Data'] = dbus.Dictionary(
                self.data, signature='yv')
        return {LE_ADVERTISEMENT_IFACE: properties}

    def get_path(self):
        return dbus.ObjectPath(self.path)

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

    @dbus.service.method(DBUS_PROP_IFACE,
                         in_signature='s',
                         out_signature='a{sv}')
    def GetAll(self, interface):
        print('GetAll')
        if interface != LE_ADVERTISEMENT_IFACE:
            raise InvalidArgsException()
        print('returning props')
        return self.get_properties()[LE_ADVERTISEMENT_IFACE]

    @dbus.service.method(LE_ADVERTISEMENT_IFACE,
                         in_signature='',
                         out_signature='')
    def Release(self):
        print('%s: Released!' % self.path)


class TestAdvertisement(Advertisement):

    def __init__(self, bus, index):
        Advertisement.__init__(self, bus, index, 'peripheral')
        self.add_service_uuid('A3A3')
        self.add_manufacturer_data(0xffff, [0x00, 0x01, 0x02, 0x03])
        self.add_service_data('9999', [0x00, 0x01, 0x02, 0x03, 0x04])
        self.add_local_name('Triton1')
        self.include_tx_power = True
        self.add_data(0x26, [0x01, 0x01, 0x00])


class Application(dbus.service.Object):
    """
    org.bluez.GattApplication1 interface implementation
    """
    def __init__(self, bus):
        self.path = '/'
        self.services = []
        dbus.service.Object.__init__(self, bus, self.path)
        self.add_service(GPSservice(bus, 0))
        self.add_service(TestService(bus, 1))

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_service(self, service):
        self.services.append(service)

    @dbus.service.method(DBUS_OM_IFACE, out_signature='a{oa{sa{sv}}}')
    def GetManagedObjects(self):
        response = {}
        print('GetManagedObjects')

        for service in self.services:
            response[service.get_path()] = service.get_properties()
            chrcs = service.get_characteristics()
            for chrc in chrcs:
                response[chrc.get_path()] = chrc.get_properties()
                descs = chrc.get_descriptors()
                for desc in descs:
                    response[desc.get_path()] = desc.get_properties()

        return response


class Service(dbus.service.Object):
    """
    org.bluez.GattService1 interface implementation
    """
    PATH_BASE = '/org/bluez/example/service'

    def __init__(self, bus, index, uuid, primary):
        self.path = self.PATH_BASE + str(index)
        self.bus = bus
        self.uuid = uuid
        self.primary = primary
        self.characteristics = []
        dbus.service.Object.__init__(self, bus, self.path)

    def get_properties(self):
        return {
                GATT_SERVICE_IFACE: {
                        'UUID': self.uuid,
                        'Primary': self.primary,
                        'Characteristics': dbus.Array(
                                self.get_characteristic_paths(),
                                signature='o')
                }
        }

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_characteristic(self, characteristic):
        self.characteristics.append(characteristic)

    def get_characteristic_paths(self):
        result = []
        for chrc in self.characteristics:
            result.append(chrc.get_path())
        return result

    def get_characteristics(self):
        return self.characteristics

    @dbus.service.method(DBUS_PROP_IFACE,
                         in_signature='s',
                         out_signature='a{sv}')
    def GetAll(self, interface):
        if interface != GATT_SERVICE_IFACE:
            raise InvalidArgsException()

        return self.get_properties()[GATT_SERVICE_IFACE]


class Characteristic(dbus.service.Object):
    """
    org.bluez.GattCharacteristic1 interface implementation
    """
    def __init__(self, bus, index, uuid, flags, service):
        self.path = service.path + '/char' + str(index)
        self.bus = bus
        self.uuid = uuid
        self.service = service
        self.flags = flags
        self.descriptors = []
        dbus.service.Object.__init__(self, bus, self.path)

    def get_properties(self):
        return {
                GATT_CHRC_IFACE: {
                        'Service': self.service.get_path(),
                        'UUID': self.uuid,
                        'Flags': self.flags,
                        'Descriptors': dbus.Array(
                                self.get_descriptor_paths(),
                                signature='o')
                }
        }

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_descriptor(self, descriptor):
        self.descriptors.append(descriptor)

    def get_descriptor_paths(self):
        result = []
        for desc in self.descriptors:
            result.append(desc.get_path())
        return result

    def get_descriptors(self):
        return self.descriptors

    @dbus.service.method(DBUS_PROP_IFACE,
                         in_signature='s',
                         out_signature='a{sv}')
    def GetAll(self, interface):
        if interface != GATT_CHRC_IFACE:
            raise InvalidArgsException()

        return self.get_properties()[GATT_CHRC_IFACE]

    @dbus.service.method(GATT_CHRC_IFACE,
                        in_signature='a{sv}',
                        out_signature='ay')
    def ReadValue(self, options):
        print('Default ReadValue called, returning error')
        raise NotSupportedException()

    @dbus.service.method(GATT_CHRC_IFACE, in_signature='aya{sv}')
    def WriteValue(self, value, options):
        print('Default WriteValue called, returning error')
        raise NotSupportedException()

    @dbus.service.method(GATT_CHRC_IFACE)
    def StartNotify(self):
        print('Default StartNotify called, returning error')
        raise NotSupportedException()

    @dbus.service.method(GATT_CHRC_IFACE)
    def StopNotify(self):
        print('Default StopNotify called, returning error')
        raise NotSupportedException()

    @dbus.service.signal(DBUS_PROP_IFACE,
                         signature='sa{sv}as')
    def PropertiesChanged(self, interface, changed, invalidated):
        pass


class Descriptor(dbus.service.Object):
    """
    org.bluez.GattDescriptor1 interface implementation
    """
    def __init__(self, bus, index, uuid, flags, characteristic):
        self.path = characteristic.path + '/desc' + str(index)
        self.bus = bus
        self.uuid = uuid
        self.flags = flags
        self.chrc = characteristic
        dbus.service.Object.__init__(self, bus, self.path)

    def get_properties(self):
        return {
                GATT_DESC_IFACE: {
                        'Characteristic': self.chrc.get_path(),
                        'UUID': self.uuid,
                        'Flags': self.flags,
                }
        }

    def get_path(self):
        return dbus.ObjectPath(self.path)

    @dbus.service.method(DBUS_PROP_IFACE,
                         in_signature='s',
                         out_signature='a{sv}')
    def GetAll(self, interface):
        if interface != GATT_DESC_IFACE:
            raise InvalidArgsException()

        return self.get_properties()[GATT_DESC_IFACE]

    @dbus.service.method(GATT_DESC_IFACE,
                        in_signature='a{sv}',
                        out_signature='ay')
    def ReadValue(self, options):
        print ('Default ReadValue called, returning error')
        raise NotSupportedException()

    @dbus.service.method(GATT_DESC_IFACE, in_signature='aya{sv}')
    def WriteValue(self, value, options):
        print('Default WriteValue called, returning error')
        raise NotSupportedException()

#global variables
GPS_FILE = "/home/triton/Senior-Design-Sailboat-Nav-2025/GPS/gps_data1.txt"

def read_gps_data(file_path):
    """
    Reads GPS data from a text file and yields it line by line.
    """
    print("calling read GPS data")
    with open(file_path, 'r') as file:
        print("opened file")
        lines = file.readlines()
        for i in range(0, len(lines), 2):  # Read two lines (UTCtime and Date)
            utc_time = lines[i].split(": ")[1].strip()  # Extract UTC time
            date = lines[i + 1].split(": ")[1].strip()  # Extract Date
        return float(utc_time), date


class GPSservice(Service):
    """
    """
    GPS_UUID = 'ec2ce16f-f774-4c1f-b3dd-a56b64bc9037'

    def __init__(self, bus, index):
        Service.__init__(self, bus, index, self.GPS_UUID, True)
        self.add_characteristic(LongitudeCharacteristic(bus, 0, self))
        self.add_characteristic(LongitudeIndicatorCharacteristic(bus, 1, self))
        self.add_characteristic(LatitudeCharacteristic(bus, 2, self))
        self.add_characteristic(LatitudeIndicatorCharacteristic(bus, 3, self))
        self.add_characteristic(GPSTimeCharacteristic(bus, 4, self))
        self.add_characteristic(GPSAltitudeCharacteristic(bus, 5, self))
        self.add_characteristic(GPSSpeedCharacteristic(bus, 6, self))
        self.add_characteristic(GPSCOGCharacteristic(bus, 7, self))
        self.add_characteristic(GPSDateCharacteristic(bus, 8, self))
        self.energy_expended = 0


class GPSChrc(Characteristic):
    GPS_MSRMT_UUID = 'ec2ce16f-f774-4c1f-b3dd-a56b64bc9037'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.GPS_MSRMT_UUID,
                ['notify'],
                service)
        self.notifying = False

    def hr_msrmt_cb(self):
        value = []
        value.append(dbus.Byte(0x06))
        value.append(dbus.Byte(randint(90, 130)))
        print('Updating GPS: ' + repr(value))
        self.PropertiesChanged(GATT_CHRC_IFACE, { 'Value': value }, [])
        return self.notifying

    def _update_hr_msrmt_simulation(self):
        print('Update GPS')

        if not self.notifying:
            return

        GLib.timeout_add(1000, self.hr_msrmt_cb)

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self._update_hr_msrmt_simulation()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False
        self._update_hr_msrmt_simulation()


class LongitudeCharacteristic(Characteristic):
    """

    """
    LONG_UUID = '842c3d51-9599-4c9c-aa41-15a28cb48bce'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.LONG_UUID,
                ['read', 'notify'],
                service)
        self.notifying = False
        self.long = 100
        GLib.timeout_add(5000, self.drain_battery)
    def notify_longitude(self):
        if not self.notifying:
            return
        self.PropertiesChanged(
                GATT_CHRC_IFACE,
                { 'Value': [dbus.Byte(self.long)] }, [])
    def drain_battery(self):
        if not self.notifying:
            return True
        if self.long > 0:
            self.long -= 2
            if self.long < 0:
                self.long = 0
        print('Longitude: ' + repr(self.long))
        self.notify_longitude()
        return True
    def ReadValue(self, options):
        print('Longitude read: ' + repr(self.long))
        return [dbus.Byte(self.long)]
    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return
        self.notifying = True
        self.notify_longitude()
    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return
        self.notifying = False

    # def __init__(self, bus, index, service):
    #     Characteristic.__init__(
    #             self, bus, index,
    #             self.LONG_UUID,
    #             ['read', 'notify'],
    #             service)
    #     self.notifying = False
    #     self.long = self.append(dbus.Byte(0x01))
    #     GLib.timeout_add(5000)

    # def notify_longitude(self):
    #     if not self.notifying:
    #         return
    #     self.PropertiesChanged(
    #             GATT_CHRC_IFACE,
    #             { 'Value': [dbus.Byte(self.long)] }, [])

    # def ReadValue(self, options):
    #     print('Longitude read: ' + repr(self.long))
    #     return [dbus.Byte(self.long)]

    # def StartNotify(self):
    #     if self.notifying:
    #         print('Already notifying, nothing to do')
    #         return
    #     self.notifying = True
    #     self.notify_longitude()

    # def StopNotify(self):
    #     if not self.notifying:
    #         print('Not notifying, nothing to do')
    #         return

    #     self.notifying = False

class LongitudeIndicatorCharacteristic(Characteristic):
    """

    """
    LONG_INDI_UUID = '156a777b-a6b7-4a8c-b9a5-8e674db49320'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.LONG_INDI_UUID,
                ['read', 'notify'],
                service)
        self.longindi = dbus.Byte(0x02)
        self.notifying = False
        #GLib.timeout_add(5000)

    def notify_longindi(self):
        if not self.notifying:
            return
        self.PropertiesChanged(
                GATT_CHRC_IFACE,
                { 'Value': [dbus.Byte(self.longindi)] }, [])

    def ReadValue(self, options):
        print('Latitude ' + repr(self.battery_lvl))
        return [dbus.Byte(self.battery_lvl)]

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_battery_level()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False

class LatitudeCharacteristic(Characteristic):
    """

    """
    LATI_UUID = 'cc29cd0d-5a2a-43c6-bd68-3aea185c8605'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.LATI_UUID,
                ['read', 'notify'],
                service)
        self.notifying = False
        self.lati = dbus.Byte(0x03)
        #GLib.timeout_add(5000)

    def notify_lat(self):
        if not self.notifying:
            return
        self.PropertiesChanged(
                GATT_CHRC_IFACE,
                { 'Value': [dbus.Byte(self.lati)] }, [])

    def ReadValue(self, options):
        print('Latitude ' + repr(self.lati))
        return [dbus.Byte(self.lati)]

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_battery_level()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False

class LatitudeIndicatorCharacteristic(Characteristic):
    """

    """
    LATI_INDI_UUID = '67fd8c36-b6f0-48e6-a672-03f0986fbca7'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.LATI_INDI_UUID,
                ['read', 'notify'],
                service)
        self.notifying = False
        self.latiindi = dbus.Byte(0x04)
        #GLib.timeout_add(5000)

    def notify_lat(self):
        if not self.notifying:
            return
        self.PropertiesChanged(
                GATT_CHRC_IFACE,
                { 'Value': [dbus.Byte(self.latiindi)] }, [])

    def ReadValue(self, options):
        print('Latitude Indicator ' + repr(self.latiinid))
        return [dbus.Byte(self.battery_lvl)]

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_battery_level()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False

class GPSTimeCharacteristic(Characteristic):
    """

    """
    TIME_UUID = '70685f3a-dc84-4654-a31a-a3b87fb3817d'
    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.TIME_UUID,
                ['read', 'notify'],
                service)
        self.notifying = False
        self.time = 0
        GLib.timeout_add(5000, self.get_data)

    def get_data(self):
        self.time, _ = read_gps_data(GPS_FILE)
        if not self.notifying:
            return True
        if (self.time):
            print('Time ' + repr(self.time))
            self.notify_time()
        return True


    def notify_time(self):
        if not self.notifying:
            return
        scaled_time = int(self.time * 1000)
        time_bytes = struct.pack(">I", scaled_time)
        self.PropertiesChanged(
                GATT_CHRC_IFACE,
                { 'Value': [dbus.Byte(b) for b in time_bytes] }, [])

    def ReadValue(self, options):
        print('Time ' + repr(self.time))
        return [dbus.Byte(self.time)]

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_time()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False

class GPSAltitudeCharacteristic(Characteristic):
    """

    """
    ALTI_UUID = 'b189e5f8-0217-47ad-b29e-35dc95386c87'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.ALTI_UUID,
                ['read', 'notify'],
                service)
        self.notifying = False
        self.alti = dbus.Byte(0x06)
        #GLib.timeout_add(5000)

    def notify_lat(self):
        if not self.notifying:
            return
        self.PropertiesChanged(
                GATT_CHRC_IFACE,
                { 'Value': [dbus.Byte(self.alti)] }, [])

    def ReadValue(self, options):
        print('Altitude ' + repr(self.alti))
        return [dbus.Byte(self.alti)]

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_lat()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False

class GPSSpeedCharacteristic(Characteristic):
    """

    """
    WHEE_UUID = 'd8d76975-9d5d-41d2-b9d2-c9b861bbd80b'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.WHEE_UUID,
                ['read', 'notify'],
                service)
        self.notifying = False
        self.speed = dbus.Byte(0x07)
        #GLib.timeout_add(5000)

    def notify_lat(self):
        if not self.notifying:
            return
        self.PropertiesChanged(
                GATT_CHRC_IFACE,
                { 'Value': [dbus.Byte(self.speed)] }, [])

    def ReadValue(self, options):
        print('Speed ' + repr(self.speed))
        return [dbus.Byte(self.speed)]

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_battery_level()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False

class GPSCOGCharacteristic(Characteristic):
    """

    """
    COG_UUID = 'e20c75dc-8dc5-4ecf-83bb-b87bc26963b4'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.COG_UUID,
                ['read', 'notify'],
                service)
        self.cog = dbus.Byte(0x08)
        self.notifying = False
        #GLib.timeout_add(5000, self.drain_battery)

    def notify_lat(self):
        if not self.notifying:
            return
        self.PropertiesChanged(
                GATT_CHRC_IFACE,
                { 'Value': [dbus.Byte(self.cog)] }, [])

    def ReadValue(self, options):
        print('COG ' + repr(self.cog))
        return [dbus.Byte(self.cog)]

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_battery_level()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False

class GPSDateCharacteristic(Characteristic):
    """

    """
    DIA_UUID = '0892b3f5-60d6-4d52-97f2-e7fb187d7253'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.DIA_UUID,
                ['read', 'notify'],
                service)
        self.notifying = False
        self.date = dbus.Byte(0x09)
        #GLib.timeout_add(5000)

    def notify_lat(self):
        if not self.notifying:
            return
        self.PropertiesChanged(
                GATT_CHRC_IFACE,
                { 'Value': [dbus.Byte(self.date)] }, [])

    def ReadValue(self, options):
        print('Date ' + repr(self.date))
        return [dbus.Byte(self.date)]

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_battery_level()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False
class TestService(Service):
    """
    Dummy test service that provides characteristics and descriptors that
    exercise various API functionality.

    """
    TEST_SVC_UUID = '12345678-1234-5678-1234-56789abcdef0'

    def __init__(self, bus, index):
        Service.__init__(self, bus, index, self.TEST_SVC_UUID, True)
        self.add_characteristic(TestCharacteristic(bus, 0, self))

class TestCharacteristic(Characteristic):
    """
    Dummy test characteristic. Allows writing arbitrary bytes to its value, and
    contains "extended properties", as well as a test descriptor.

    """
    TEST_CHRC_UUID = '12345678-1234-5678-1234-56789abcdef1'

    def __init__(self, bus, index, service):
        Characteristic.__init__(
                self, bus, index,
                self.TEST_CHRC_UUID,
                ['read', 'write', 'writable-auxiliaries', 'notify'],
                service)
        self.notifying = False
        self.value = []
        self.add_descriptor(TestDescriptor(bus, 0, self))
        self.add_descriptor(
                CharacteristicUserDescriptionDescriptor(bus, 1, self))

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return

        self.notifying = True
        self.notify_battery_level()

    def StopNotify(self):
        if not self.notifying:
            print('Not notifying, nothing to do')
            return

        self.notifying = False

    def ReadValue(self, options):
        print('TestCharacteristic Read: ' + repr(self.value))
        return self.value

    def WriteValue(self, value, options):
        print('TestCharacteristic Write: ' + repr(value))
        self.value = value


class TestDescriptor(Descriptor):
    """
    Dummy test descriptor. Returns a static value.

    """
    TEST_DESC_UUID = '12345678-1234-5678-1234-56789abcdef2'

    def __init__(self, bus, index, characteristic):
        Descriptor.__init__(
                self, bus, index,
                self.TEST_DESC_UUID,
                ['read', 'write'],
                characteristic)

    def ReadValue(self, options):
        return [
                dbus.Byte('T'), dbus.Byte('e'), dbus.Byte('s'), dbus.Byte('t')
        ]


class CharacteristicUserDescriptionDescriptor(Descriptor):
    """
    Writable CUD descriptor.

    """
    CUD_UUID = '2901'

    def __init__(self, bus, index, characteristic):
        self.writable = 'writable-auxiliaries' in characteristic.flags
        self.value = array.array('B', b'This is a characteristic for testing')
        self.value = self.value.tolist()
        Descriptor.__init__(
                self, bus, index,
                self.CUD_UUID,
                ['read', 'write'],
                characteristic)

    def ReadValue(self, options):
        return self.value

    def WriteValue(self, value, options):
        if not self.writable:
            raise NotPermittedException()
        self.value = value

def register_app_cb():
    print('GATT application registered')


def register_app_error_cb(error):
    print('Failed to register application: ' + str(error))
    mainloop.quit()


def register_ad_cb():
    print('Advertisement registered')


def register_ad_error_cb(error):
    print('Failed to register advertisement: ' + str(error))
    mainloop.quit()


def find_adapter(bus):
    remote_om = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, '/'),
                               DBUS_OM_IFACE)
    objects = remote_om.GetManagedObjects()

    for o, props in objects.items():
        if (GATT_MANAGER_IFACE in props.keys()) & (LE_ADVERTISING_MANAGER_IFACE in props):
            return o

    return None

def shutdown(timeout):
    print('Advertising for {} seconds...'.format(timeout))
    time.sleep(timeout)
    mainloop.quit()

def main(timeout = 0):
    global mainloop

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()

    adapter = find_adapter(bus)
    if not adapter:
        print('GattManager1 interface not found or LEAdvertisingManager1 interface not found')
        return

    adapter_props = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                                   "org.freedesktop.DBus.Properties")

    service_manager = dbus.Interface(
            bus.get_object(BLUEZ_SERVICE_NAME, adapter),
            GATT_MANAGER_IFACE)
    ad_manager = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                                LE_ADVERTISING_MANAGER_IFACE)

    app = Application(bus)
    test_advertisement = TestAdvertisement(bus, 0)

    mainloop = GLib.MainLoop()

    print('Registering GATT application...')

    service_manager.RegisterApplication(app.get_path(), {},
                                    reply_handler=register_app_cb,
                                    error_handler=register_app_error_cb)
    ad_manager.RegisterAdvertisement(test_advertisement.get_path(), {},
                                     reply_handler=register_ad_cb,
                                     error_handler=register_ad_error_cb)

    mainloop.run()

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

