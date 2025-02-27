from gpiozero import Servo
import keyboard
import time

servo_pin = 18
servo = Servo(servo_pin)

position = 0.0
step = 0.1

while True:
	if keyboard.is_pressed('l'):
		position = max(-1.0, position-step)
		servo.value = position
	elif keyboard.is_pressed('r'):
		position =  min(1.0, position+step)
		servo.value = position
	elif keyboard.is_pressed('g'):
		position = 0.0
		servo.value = position
	elif keyboard.is_pressed('q'):
		break

	time.sleep(0.05)
