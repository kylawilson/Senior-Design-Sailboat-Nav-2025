from gpiozero import Servo 
import time


servo_pin = 18
servo = Servo(servo_pin)

position = 0.0
step = 0.1

while True:
	
	try:
		command = input("Enter command (a/d/q): ")
		if command == 'a':
			position = max(-1.0, position-step)
			servo.value = position
			time.sleep(0.1)
		elif command == 'd':
			position = min(1.0, position + step)
			servo.value = position
			time.sleep(0.1)
		elif command == 'q':
			print("Exiting")
			break
	except KeyboardInterrupt:
		print("Ended")
		break

