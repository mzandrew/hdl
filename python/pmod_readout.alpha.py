#!/usr/bin/env python3

# written 2024-04-04 by mza
# based on mza-test046_simple_parallel_interface_and_pollable_memory_althea.py
# last updated 2024-04-09 by mza

import time # time.sleep
import sys # sys.exit
import random # randint
from generic import * # hex, eng
import althea
import re # re.search
import gpiozero

all_gpios = [ 2, 3, 7, 8, 9, 10, 11 ]
nybble_gpios = [ 11, 9, 10, 8 ]

bus = []
for i in range(len(nybble_gpios)):
	bus.append(gpiozero.InputDevice(nybble_gpios[i], pull_up=False))
pmod_strobe = gpiozero.InputDevice(2, pull_up=True)
pmod_acknowledge = gpiozero.OutputDevice(3)

data = 0
count = 1
string = ""
pmod_acknowledge.value = 0
while True:
	pmod_acknowledge.value = 1
	if not pmod_strobe.value:
		count += 1
		data = (bus[3].value<<3) | (bus[2].value<<2) | (bus[1].value<<1) | bus[0].value
		#print("count=" + str(count) + " strobe=" + str(pmod_strobe.value) + " data=" + hex(data))
		string += hex(data)
		if 0==count%4:
			print(string, end=" ")
			match = re.search("0e6a", string)
			if match:
				print("OMGA")
			match = re.search("a1fa", string)
			if match:
				print("ALFA")
			string = ""
	pmod_acknowledge.value = 0
	try:
		sys.stdout.flush()
	except KeyboardInterrupt:
		print("keyboard interrupt")
		break

