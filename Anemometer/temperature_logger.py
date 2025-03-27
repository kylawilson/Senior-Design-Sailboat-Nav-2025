import time
import datetime
import signal

# Variables to track the highest temperature and runtime
highest_temp = float('-inf')
highest_temp_time = None
start_time = time.time()
log_file = "temperature_log.txt"

def get_temperature():
    """Reads the Raspberry Pi CPU temperature."""
    try:
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            temp = float(f.read().strip()) / 1000.0  # Convert millidegrees to Celsius
        return temp
    except Exception as e:
        print(f"Error reading temperature: {e}")
        return None

def log_final_results():
    """Logs the highest temperature, its timestamp, and the total runtime."""
    end_time = time.time()
    total_runtime = end_time - start_time
    formatted_runtime = str(datetime.timedelta(seconds=int(total_runtime)))

    with open(log_file, "w") as f:  # Use "w" to overwrite with final results only
        f.write("===== Final Results =====\n")
        if highest_temp_time:
            f.write(f"Highest Temperature: {highest_temp:.2f}°C at {highest_temp_time}\n")
        else:
            f.write("No temperature readings were recorded.\n")
        f.write(f"Total Runtime: {formatted_runtime}\n")
        f.write("==========================\n")
    
    print("\nLogging completed. Exiting script.")
    print(f"Total runtime: {formatted_runtime}")
    if highest_temp_time:
        print(f"Highest temperature: {highest_temp:.2f}°C at {highest_temp_time}")
    else:
        print("No temperature readings were recorded.")

def signal_handler(sig, frame):
    """Handles termination signals gracefully."""
    log_final_results()
    exit(0)

# Catch termination signals (CTRL+C or kill signal)
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

print("Starting temperature logging... Press CTRL+C to stop.")

try:
    # Main loop to read and log temperature
    while True:
        temp = get_temperature()
        
        if temp is not None:
            current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            # Check for the highest temperature
            if temp > highest_temp:
                highest_temp = temp
                highest_temp_time = current_time
                print(f"[{current_time}] New highest temp: {temp:.2f}°C")

        time.sleep(2)  # Read temperature every 2 seconds

except KeyboardInterrupt:
    log_final_results()
