import RPi.GPIO as GPIO
import time

# Pin setup
WIND_SPEED_PIN = 18  # Connect the green wire (wind speed) here
RADIUS = 9.0  # cm, radius of the anemometer cups
ANEMOMETER_FACTOR = 2.4  # Pulses per second per m/s

# Variables
pulse_count = 0
start_time = time.time()

# Interrupt function to count pulses
def count_pulse(channel):
    global pulse_count
    pulse_count += 1

# GPIO setup
GPIO.setmode(GPIO.BCM)
GPIO.setup(WIND_SPEED_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
GPIO.add_event_detect(WIND_SPEED_PIN, GPIO.FALLING, callback=count_pulse)

try:
    while True:
        time.sleep(1)  # Measure every 1 second
        elapsed_time = time.time() - start_time
        wind_speed = (pulse_count / elapsed_time) / ANEMOMETER_FACTOR  # Convert to m/s
        knot_speed = wind_speed * 1.944
        print(f"Wind Speed: {wind_speed:.2f} m/s ({wind_speed * 2.237:.2f} mph) {knot_speed:.2f} knots")
        # Reset for next measurement
        pulse_count = 0
        start_time = time.time()

except KeyboardInterrupt:
    print("Stopping...")
    GPIO.cleanup()
