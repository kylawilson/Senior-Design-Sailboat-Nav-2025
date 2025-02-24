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
python3 MRS_Picture.py &
cd ../RPI-BLUETOOTH
python3 bluetooth.py &
