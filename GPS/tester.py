import socket
import serial
import time
from threading import Thread

# Constants
GPS_SERIAL_PORT = "/dev/serial0"
BAUD_RATE = 9600
HOST = '127.0.0.1'
PORT = 12345

# Parse GGA sentence
def process_gga(line):
    fields = line.split(',')

    if len(fields) >= 10:
        utc_time = fields[1]
        latitude = fields[2]
        lat_indicator = fields[3]
        longitude = fields[4]
        long_indicator = fields[5]
        altitude = fields[9]

        data = {
            "UTCtime": utc_time,
            "Latitude": latitude,
            "latIndicator": lat_indicator,
            "Longitude": longitude,
            "longIndicator": long_indicator,
            "Altitude": altitude
        }
        return data
    else:
        return None

# GPS Thread to read data
class GPSThread(Thread):
    def __init__(self, serial_port, server_socket):
        super().__init__()
        self.serial_port = serial_port
        self.server_socket = server_socket
        self.running = True

    def run(self):
        gps_data = ""
        while self.running:
            if self.serial_port.in_waiting:
                char = self.serial_port.read().decode('utf-8', errors='ignore')
                gps_data += char

                if char == '\n':
                    if "GGA" in gps_data:
                        data = process_gga(gps_data)
                        if data:
                            self.send_to_client(data)
                    gps_data = ""

    def send_to_client(self, data):
        try:
            message = ",".join([f"{key}:{value}" for key, value in data.items()])
            self.server_socket.sendall(message.encode('utf-8'))
        except Exception as e:
            print(f"Error sending data to client: {e}")

    def stop(self):
        self.running = False

# Bluetooth server
class BluetoothServer:
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.server_socket = None
        self.connection = None

    def start_server(self):
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(1)
        print(f"Listening on {self.host}:{self.port}...")
        self.connection, addr = self.server_socket.accept()
        print(f"Connected by {addr}")
        return self.connection

    def stop_server(self):
        if self.connection:
            self.connection.close()
        if self.server_socket:
            self.server_socket.close()

# Main
if __name__ == '__main__':
    try:
        # Initialize Bluetooth server
        bt_server = BluetoothServer(HOST, PORT)
        client_socket = bt_server.start_server()

        # Initialize GPS
        gps_serial = serial.Serial(GPS_SERIAL_PORT, BAUD_RATE, timeout=1)

        # Start GPS thread
        gps_thread = GPSThread(gps_serial, client_socket)
        gps_thread.start()

        print("System running. Press Ctrl+C to stop.")

        # Keep running until interrupted
        while True:
            time.sleep(1)

    except KeyboardInterrupt:
        print("Shutting down...")
        gps_thread.stop()
        gps_thread.join()
        bt_server.stop_server()

    except Exception as e:
        print(f"An error occurred: {e}")
        if 'gps_thread' in locals():
            gps_thread.stop()
            gps_thread.join()
        if 'bt_server' in locals():
            bt_server.stop_server()
