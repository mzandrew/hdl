#!/usr/bin/env python3

# written 2024-05-10 by mza
# following 

import zmq # pip3 install zmq
import time
import sys
import calendar
import struct
import generic

port = 9001
context = zmq.Context()
socket = context.socket(zmq.REQ)
url = "tcp://localhost:" + str(port)
print("connecting to " + url)
socket.connect(url)

for i in range(3):
#while True:
	try:
		ns = int(calendar.timegm(time.gmtime()) * 1e9)
		message = struct.pack("!Q", ns)
		message2 = time.gmtime(ns//1e9)
		message3 = time.strftime("%Y-%m-%d %H:%M:%S", message2)
		print("sending: " + str(message3))
		socket.send(message)
		message = socket.recv()
		hitmap_message = struct.unpack("!BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", message)
		for i in range(4):
			string = "bank" + chr(i+ord('A')) + ": "
			for j in range(12):
				string += generic.hex(hitmap_message[i*12+j], 2)
			print(string)
		#message2 = time.gmtime(message1//1e9)
		#message3 = time.strftime("%Y-%m-%d %H:%M:%S", message2)
		#print("received: " + str(message))
		time.sleep(0.1)
	except KeyboardInterrupt:
		print("")
		print("shutting down client...")
		sys.exit(2)

