#!/usr/bin/env python

# written 2020-05-05 by mza
# last updated 2020-05-06 by mza

import time
import random
import sys
import math

# from https://github.com/doceme/py-spidev
import spidev
spi_simple8 = spidev.SpiDev()
spi_simple8.open(0, 0)
spi_simple8.max_speed_hz = int(24e6) # 24e6 works without errors; 25e6 fails often (BER=500e-3)
spi_simple8.mode = 0b01
spi_c8_a16_d32 = spidev.SpiDev()
spi_c8_a16_d32.open(0, 1)
spi_c8_a16_d32.max_speed_hz = int(24e6) # 24e6 works without errors; 25e6 fails often (BER=500e-3)
spi_c8_a16_d32.mode = 0b01

def hex(number, width=1):
	return "%0*x" % (width, number)

# from https://stackoverflow.com/a/19270863/5728815
#def eng(x, format='%s', si=False):
def eng(x, format='%.1f', si=False):
	'''
	Returns float/int value <x> formatted in a simplified engineering format -
	using an exponent that is a multiple of 3.
	format: printf-style string used to format the value before the exponent.
	si: if true, use SI suffix for exponent, e.g. k instead of e3, n instead of
	e-9 etc.
	E.g. with format='%.2f':
	    1.23e-08 => 12.30e-9
	         123 => 123.00
	      1230.0 => 1.23e3
	  -1230000.0 => -1.23e6
	and with si=True:
	      1230.0 => 1.23k
	  -1230000.0 => -1.23M
	'''
	sign = ''
	if x < 0.0:
		x = -x
		sign = '-'
	exp = int(math.floor(math.log10(x)))
	exp3 = exp - ( exp % 3)
	x3 = x / ( 10 ** exp3)
	if si and exp3 >= -24 and exp3 <= 24 and exp3 != 0:
		exp3_text = 'yzafpnum kMGTPEZY'[ ( exp3 - (-24)) / 3]
	elif exp3 == 0:
		exp3_text = ''
	else:
		exp3_text = 'e%s' % exp3
	return ( '%s'+format+'%s') % ( sign, x3, exp3_text)

def test_single8(size):
	print "testing spi_single8 peripheral..."
	#data_list = [ 0x00, 0x01, 0x03, 0x06, 0x04 ]
	data_list = []
	for i in range(size):
		data_list.append(random.randint(0,255))
	total_transfers = 0
	total_errors = 0
	i = 0
	previous_value_written = 0
	for value_written in data_list:
		value_read, = spi_simple8.xfer([value_written])
		total_transfers += 1
		if 0!=i:
			#print hex(previous_value_written, 1) + " " + hex(value_read, 1)
			if value_read!=previous_value_written:
				total_errors += 1
				#BER = float(total_errors)/total_transfers
				#print "value_read (" + hex(value_read, 2) + ") != value_written (" + hex(previous_value_written, 2) + ")  BER<=" + eng(BER, "%.1f")
		previous_value_written = value_written
		#time.sleep(0.05)
		i += 1
	if (total_errors):
		BER = float(total_errors)/total_transfers
		print "BER<=" + eng(BER, "%.1f")
	else:
		print str(size) + " transfers completed successfully"

def spi_send_command8_address16_data32(bus, device, command, address, data):
	address_low  =  address     & 0xff
	address_high = (address>>8) & 0xff
	data_0 = int( data      & 0xff)
	data_1 = int((data>> 8) & 0xff)
	data_2 = int((data>>16) & 0xff)
	data_3 = int((data>>24) & 0xff)
	to_send = [ command, address_high, address_low, data_3, data_2, data_1, data_0 ]
#	spi_c8_a16_d32.writebytes(to_send)
#	spi_c8_a16_d32.xfer(to_send)
	values = spi_c8_a16_d32.xfer2(to_send)
#	spi_c8_a16_d32.xfer3(to_send)
#	time.sleep(0.001)
#	spi_c8_a16_d32.writebytes2(to_send)
#	result = spi_c8_a16_d32.readbytes(4)
	return values

def test_command8_address16_data32(size):
	print "testing spi_command8_address16_data32 peripheral..."
	# 30k transfers per second on a rpi2 @ 10e6 Hz
	command_list = []
	address_list = []
	data_list = []
	for i in range(size):
		command_list.append(random.randint(0,255))
		address_list.append(random.randint(0,2**16-1))
		data_list.append(random.randint(0,2**32-1))
	start = time.time()
	for i in range(size):
		spi_send_command8_address16_data32(0, 1, command_list[i], address_list[i], data_list[i])
	end = time.time()
	diff = end - start
	per = diff / size
	transfers_per_sec = size / diff
	print str(size) + " transfers completed successfully"
	print eng(transfers_per_sec) + " transfers per second"

size = 100000

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

test_single8(size)

#command = 0x01
#address = 0x3456
#data = 0x89abcdef
#spi_send_command8_address16_data32(0, 1, command, address, data)

test_command8_address16_data32(size)

