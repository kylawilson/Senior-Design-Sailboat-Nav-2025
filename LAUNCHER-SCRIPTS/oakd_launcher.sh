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
python3 DBMRS.py &
cd ../RPI-BLUETOOTH
python3 bluetooth.py &
echo "running gps"
cd ~
cd ..
cd home/triton
pwd
cd Senior-Design-Sailboat-Nav-2025/GPS/
./gps_dbus_test
cd ~
