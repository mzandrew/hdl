#!/usr/bin/env python

# written 2020-05-05 by mza
# last updated 2020-05-06 by mza

import time
import random

# from https://github.com/doceme/py-spidev
import spidev
spi = spidev.SpiDev()
bus = 0
device = 0
spi.open(bus, device)
spi.max_speed_hz = int(10e6)
spi.mode = 0b01

command = 0xef
address = 0xabcd
data = 0x12345678

def send_spi(bus, device, command, address, data):
	address_low  =  address     & 0xff
	address_high = (address>>8) & 0xff
	data_0 =  data      & 0xff
	data_1 = (data>> 8) & 0xff
	data_2 = (data>>16) & 0xff
	data_3 = (data>>24) & 0xff
	to_send = [ command, address_high, address_low, data_3, data_2, data_1, data_0 ]
#	spi.writebytes(to_send)
#	spi.xfer(to_send)
	spi.xfer2(to_send)
#	spi.xfer3(to_send)
#	time.sleep(0.001)
#	spi.writebytes2(to_send)
#	result = spi.readbytes(4)

size = 100000

command_list = []
address_list = []
data_list = []
for i in range(size):
	command_list.append(random.randint(0,255))
	address_list.append(random.randint(0,2**16-1))
	data_list.append(random.randint(0,2**32-1))

# 30k transfers per second on a rpi2 @ 10e6 Hz
while True:
	start = time.time()
	for i in range(size):
		send_spi(0, 0, command_list[i], address_list[i], data_list[i])
	end = time.time()
	diff = end - start
	per = diff / size
	transfers_per_sec = size / diff
	print transfers_per_sec

#byte_list = []
#for i in range(size):
#	byte_list.append(random.randint(0,255))

# 1.14 MB/sec on a rpi2 @ 10e6 Hz
#while True:
#	start = time.time()
#	spi.writebytes2(byte_list)
#	end = time.time()
#	diff = end - start
#	per = diff / size
#	MB_per_sec = size / diff / 1.0e6
#	#print diff
#	#print per
#	print MB_per_sec

