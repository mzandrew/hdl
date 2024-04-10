#!/usr/bin/env python3

# written 2024-04-04 by mza
# based on mza-test046_simple_parallel_interface_and_pollable_memory_althea.py
# last updated 2024-04-10 by mza

filename = "alpha.data"

import time # time.sleep
import sys # sys.exit
import random # randint
from generic import * # hex, eng
import althea
import re # re.search
import gpiozero

all_gpios = [ 2, 3, 7, 8, 9, 10, 11 ]
nybble_gpios = [ 11, 9, 10, 8 ]

#header_description_bytes = [ "AL", "FA", "ASICID", "finetime", "coarse4", "coarse3", "coarse2", "coarse1", "trigger1", "trigger0", "aftertrigger", "lookback", "samplestoread", "startingsample", "missedtriggers", "status" ]
HEADER_LENGTH_WORDS = 8
#header_length_nybbles = HEADER_LENGTH_WORDS * 4
#header_description_words = [ "ALFA", "IdFi", "cs43", "cs21", "tg10", "SaLo", "StSt", "MiSt" ]

bus = []
for i in range(len(nybble_gpios)):
	bus.append(gpiozero.InputDevice(nybble_gpios[i], pull_up=False))
pmod_strobe = gpiozero.InputDevice(2, pull_up=True)
pmod_acknowledge = gpiozero.OutputDevice(3)

count = 1
nybble_counter = 0
data_string = []
data_nybbles = []
#alignment_nybbles = ( 0xa, 0x1, 0xf, 0xa )
string = ""
datafile = open(filename, "w+")
ALFA_OMGA_counter = 0

def write_strings_and_empty_buffer():
	global data_string
	for s in data_string:
		datafile.write(s)
		data_string = []
	datafile.write("\n")
	datafile.flush()
	sys.stdout.flush()

def handle_strobe():
	global count
	global nybble_counter
	global data_string
	global data_nybbles
	global string
	global ALFA_OMGA_counter
	data = 0
	count += 1
	nybble_counter += 1
	data = (bus[3].value<<3) | (bus[2].value<<2) | (bus[1].value<<1) | bus[0].value
	#print("count=" + str(count) + " strobe=" + str(pmod_strobe.value) + " data=" + hex(data))
	data_nybbles.append(data)
#	for i in range(7):
#
	string += hex(data)
	if 0==nybble_counter%4:
		match = re.search("a1fa", string)
		if match:
			ALFA_OMGA_counter = 0
			print("")
			#write_strings_and_empty_buffer()
		print(string, end=" ")
#		if HEADER_LENGTH_WORDS-1==ALFA_OMGA_counter:
#			print("")
		if 0==(ALFA_OMGA_counter-HEADER_LENGTH_WORDS+1)%16:
			print("")
		data_string.append(string)
		match = re.search("0e6a", string)
		if match:
			print("")
			write_strings_and_empty_buffer()
		string = ""
		ALFA_OMGA_counter += 1

if __name__ == "__main__":
	pmod_acknowledge.value = 1
	while True:
		try:
			if not pmod_strobe.value:
				handle_strobe()
				pmod_acknowledge.value = 0
				pmod_acknowledge.value = 1
		except KeyboardInterrupt:
			print("keyboard interrupt")
			break
	pmod_acknowledge.value = 0

