# !/bin/sh
# oakd_launcher.sh

echo "running oakd"
cd ~
cd ..
cd home/triton
pwd
cd Senior-Design-Sailboat-Nav-2025/
. ./bin/activate
cd OAK-D/
export $(dbus-launch)
python3 Triton.py &
cd ../Anemometer
echo "running wind speed"
sudo python3 AneTest.py &
echo "running wind direction"
python3 WindDirection1.py &
cd ../RPI-BLUETOOTH
echo "running bluetooth"
python3 bluetooth.py &
cd ~
cd ..
cd home/triton
pwd
cd Senior-Design-Sailboat-Nav-2025/GPS/
echo "running gps"
./gps_dbus_test
