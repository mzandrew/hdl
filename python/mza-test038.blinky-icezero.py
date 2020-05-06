#!/usr/bin/env python

# written 2020-05-05 by mza
# last updated 2020-05-05 by mza

# from https://gpiozero.readthedocs.io/en/stable/recipes.html
#from gpiozero import Button
#def say_hello():
#	print("Hello!")
#button = Button(2)
#button.when_pressed = say_hello

# from https://gpiozero.readthedocs.io/en/stable/api_output.html
#import gpiozero
#import signal
import time

#sig1 = gpiozero.OutputDevice(22)
#sig2 = gpiozero.OutputDevice(24)
#sig3 = gpiozero.OutputDevice(25)

#sig1.on()
#sig2.on()
#sig3.on()
#signal.pause()

## https://gpiozero.readthedocs.io/en/stable/api_boards.html
#sig_bus = gpiozero.CompositeOutputDevice(sig1, sig2, sig3)
#counter = 0
#while counter<100:
#	if 0==counter%4:
#		sig_bus.value = [ 0, 0, 0 ]
#	elif 1==counter%4:
#		sig_bus.value = [ 1, 0, 0 ]
#	elif 2==counter%4:
#		sig_bus.value = [ 0, 1, 0 ]
#	elif 3==counter%4:
#		sig_bus.value = [ 0, 0, 1 ]
#	time.sleep(0.05)
#	counter += 1

#sig1.close()
#sig2.close()
#sig3.close()

# from https://raspberrypi.stackexchange.com/a/91602/38978
import RPi.GPIO as GPIO
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(22, GPIO.OUT)
GPIO.setup(24, GPIO.OUT)
GPIO.setup(25, GPIO.OUT)

start = time.time()
counter = 0
while counter<100:
	if 0==counter%4:
		GPIO.output(22, GPIO.LOW)
		GPIO.output(24, GPIO.LOW)
		GPIO.output(25, GPIO.LOW)
	elif 1==counter%4:
		GPIO.output(22, GPIO.HIGH)
		GPIO.output(24, GPIO.LOW)
		GPIO.output(25, GPIO.LOW)
	elif 2==counter%4:
		GPIO.output(22, GPIO.LOW)
		GPIO.output(24, GPIO.HIGH)
		GPIO.output(25, GPIO.LOW)
	elif 3==counter%4:
		GPIO.output(22, GPIO.LOW)
		GPIO.output(24, GPIO.LOW)
		GPIO.output(25, GPIO.HIGH)
	time.sleep(0.05)
	counter += 1
end = time.time()
diff = end - start
print diff
inc = diff / 300.0
print inc

