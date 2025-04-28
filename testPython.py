import dbus

def list_advertisements():
    bus = dbus.SystemBus()
    manager = dbus.Interface(bus.get_object('org.bluez', '/'), 'org.freedesktop.DBus.ObjectManager')
    objects = manager.GetManagedObjects()

    for path, interfaces in objects.items():
        if 'org.bluez.LEAdvertisement1' in interfaces:
            print(f'Advertisement found at {path}')
        if 'org.bluez.LEAdvertisingManager1' in interfaces:
            print(f'Advertising Manager at {path}')

if __name__ == "__main__":
    list_advertisements()
