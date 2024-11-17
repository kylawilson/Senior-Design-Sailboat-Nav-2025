import dbus
from gi.repository import GLib
from dbus.mainloop.glib import DBusGMainLoop
import dbus.service

DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()

# Create advertisement object
class Advertisement(dbus.service.Object):
    PATH_BASE = '/org/bluez/example/advertisement'

    def __init__(self, bus, index):
        self.path = self.PATH_BASE + str(index)
        self.bus = bus
        self.ad_type = "peripheral"
        dbus.service.Object.__init__(self, bus, self.path)

    @dbus.service.method("org.freedesktop.DBus.Properties",
                         in_signature='ss',
                         out_signature='a{sv}')
    def GetAll(self, interface, property):
        return {}

    @dbus.service.method("org.bluez.LEAdvertisement1",
                         in_signature='',
                         out_signature='')
    def Release(self):
        print(f"{self.path}: Released!")

ad = Advertisement(bus, 0)
mainloop = GLib.MainLoop()
mainloop.run()
