# written 2020-05-23 by mza
# last updated 2020-05-23 by mza

import time
import RPi.GPIO as GPIO
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)

def reset(gpio=19):
	GPIO.setup(gpio, GPIO.OUT)
	GPIO.output(gpio, GPIO.HIGH)
	time.sleep(0.1)
	GPIO.output(gpio, GPIO.LOW)
	

def test():
	GPIO.setup(13, GPIO.OUT)
	GPIO.setup(19, GPIO.OUT)
	GPIO.output(13, GPIO.HIGH)
	GPIO.output(19, GPIO.HIGH)
	time.sleep(1.0)
	GPIO.output(13, GPIO.LOW)
	GPIO.output(19, GPIO.LOW)
	
