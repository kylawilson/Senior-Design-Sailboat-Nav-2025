# Senior-Design-Sailboat-Nav-2025

"The Engineering Addendum is quick-start documentation written to any future team that may continue
to work on your project. This is where you outline the gotchas of your project, types of things to look out
for, the current state of the project, etc. The purpose of README.md is to save any future team weeks
of detective work just to get to where you are today. Think back to what types of things you had wished
you knew earlier, doing future teams a favor by passing that knowledge along. "


**STEREOPIS (PERIPHERAL MODULES)**
OS: Raspberry Pi Debain Bullseye 32-Bit Full Legacy (Released 10/22/2024)
StereoPi Version: StereoPi V2 Slim
Raspberry Pi Device: Compute Module 4, 1GB, Wireless (SC0691)

**RASPBERRY PI (CENTRAL MODULES)**
OS: Raspberry Pi Debian Bookworm 64-Bit (Released 11/19/2024)
Raspberry Pi Device: Raspberry Pi 3B



Need to add in WiringPi repo

To start UI on boot to terminal:
startx

To activate virtual environment:
source ./bin/activate

To get bluetooth working on stereopi:
sudo modprobe btusb
sudo systemctl start bluetooth
