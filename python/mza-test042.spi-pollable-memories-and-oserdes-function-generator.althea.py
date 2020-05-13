#!/usr/bin/env python

# written 2020-05-11 by mza
# based on mza-test041.spi-pollable-memory.althea.py
# last updated 2020-05-13 by mza

import time
import random
import sys
import math

# from https://github.com/doceme/py-spidev
import spidev
spi_ce0 = spidev.SpiDev()
spi_ce0.open(0, 0)
spi_ce0.max_speed_hz = int(6e6) # 11e6 works without errors; 12e6 fails often (BER=640e-3)
spi_ce0.mode = 0b00
spi_ce1 = spidev.SpiDev()
spi_ce1.open(0, 1)
spi_ce1.max_speed_hz = int(6e6) # 11e6 works without errors; 12e6 fails often (BER=640e-3)
spi_ce1.mode = 0b00

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

def show_c8_a16_d32(c8_a16_d32, suffix_string=""):
	if 7!=len(c8_a16_d32):
		print "blah"
	else:
		#print hex(c8_a16_d32[0],2)
		#print hex(c8_a16_d32[1],2) + " " + hex(c8_a16_d32[2],2)
		print hex(c8_a16_d32[3],2) + " " + hex(c8_a16_d32[4],2) + " " + hex(c8_a16_d32[5],2) + " " + hex(c8_a16_d32[6],2) + suffix_string

def show_d8_4(datum, suffix_string=""):
	if 4!=len(datum):
		print "blah_datum"
		sys.exit(1)
	else:
		print hex(datum[0],2) + " " + hex(datum[1],2) + " " + hex(datum[2],2) + " " + hex(datum[3],2) + suffix_string

def show_d32(d32, suffix_string=""):
	print hex((d32>>24)&0xff,2) + " " + hex((d32>>16)&0xff,2) + " " + hex((d32>>8)&0xff,2) + " " + hex((d32>>0)&0xff,2) + suffix_string

import copy
def unpack32(data):
#	string = "unpack32(" + hex(data, 8) + ")="
#	print string
	datum = [ 0 for d in range(4) ]
	datum[0] = int((data>>24) & 0xff) # the weird bug was here
	datum[1] = int((data>>16) & 0xff) # the weird bug was here
	datum[2] = int((data>> 8) & 0xff) # the weird bug was here
	datum[3] = int( data      & 0xff) # the weird bug was here
#	show_d32(data, " unpack32")
#	show_d8_4(datum, " unpack32")
	#result = copy.copy(datum)
	#return result
	return datum

def pack32(datum):
#	show_d8_4(datum, " pack32")
#	string = "pack32(" + hex(datum[0], 2) + "," + hex(datum[1], 2) + "," + hex(datum[2], 2) + "," + hex(datum[3], 2) + ")="
#	print string
	if 4!=len(datum):
		print "error"
		sys.exit(1)
#	for i in range(len(datum)):
#		datum[i] &= 0xff
	data = int(((datum[0]&0xff)<<24) | ((datum[1]&0xff)<<16) | ((datum[2]&0xff)<<8) | (datum[3]&0xff))
#	show_d8_4(datum, " pack32")
#	show_d32(data, " pack32")
	return data

#import hypothesis # sudo apt install python-hypothesis python-hypothesis-doc
##@hypothesis.given(hypothesis.strategies.text())
##def test_decode_inverts_encode(s):
##	assert pack32(unpack32(s)) == s
#import unittest # sudo apt install python-unittest2
#class TestEncoding(unittest.TestCase):
#	@hypothesis.given(hypothesis.strategies.integers(-1, 2**32))
#	#@hypothesis.given(hypothesis.strategies.integers(-1, 2**8))
#	#def test_decode_inverts_encode(self, s):
#	#def test_decode_inverts_encode(self, a, b, c, d):
#		#self.assertEqual(pack32(unpack32(s)), s)
#		#self.assertEqual(unpack32(pack32(a, b, c, d)), a, b, c, d)
#	def execute_example(self, f, e):
#		a, b, c, d = f(s)
#		s_prime = e(a, b, c, d)
#		selt.assertEqual(s_prime, s)
##unittest.main()
##include pytest # sudo apt install python-pytest

#unpack32(0xff000000)
#sys.exit(1)

def spi_send_command8_address16_data32(spi, command, address, data):
	command &= 0xff
	address_low  =  address     & 0xff
	address_high = (address>>8) & 0xff
	datum = unpack32(data)
	to_send = [ command, address_high, address_low, datum[0], datum[1], datum[2], datum[3] ]
#	show_d8_4(datum, " datum spi_send_command8_address16_data32")
	#to_send_a = [ command, address_high, address_low, 0x80, 0x0f, 0x00, 0xf0 ]
#	to_send_a = []
#	to_send_a.append(command)
#	to_send_a.append(address_high)
#	to_send_a.append(address_low)
#	to_send_a.append(0x80)
#	to_send_a.append(0x0f)
#	to_send_a.append(0x00)
#	to_send_a.append(0xf0)
#	to_send = [ 0 for cad in range(7) ]
#	to_send.append(command)
#	to_send.append(address_high)
#	to_send.append(address_low)
#	to_send[0] = command
#	to_send[1] = address_high
#	to_send[2] = address_low
#	to_send[3] = datum[0]
#	to_send[4] = datum[1]
#	to_send[5] = datum[2]
#	to_send[6] = datum[3]
#	if 0x80!=datum[0]:
	#print hex(datum[0], 2)
#	to_send_b.append(0x80)
	#to_send_b.append(int(datum[0]))
	#to_send_b.append(copy.copy(datum[0]))
	#to_send_b.append(copy.deepcopy(datum[0]))
#	to_send_b.append(0x0f)
	#to_send_b.append(datum[1])
#	to_send_b.append(0x00)
	#to_send_b.append(datum[2])
#	to_send_b.append(0xf0)
	#to_send_b.append(datum[3])
#	to_send_b[3] = datum[0]
	#to_send_b[3] = 0x80
	#to_send_b = [ command, address_high, address_low, data_3, data_2, data_1, data_0 ]
#	show_c8_a16_d32(to_send_a, " to_send_a spi_send_command8_address16_data32")
#	show_c8_a16_d32(to_send_b, " to_send_b spi_send_command8_address16_data32")
#	spi.writebytes(to_send)
#	spi.xfer(to_send)
	#values = spi.xfer2(copy.deepcopy(to_send_b))
	#to_send = to_send_b
#	to_send = copy.deepcopy(to_send_b)
	if 7!=len(to_send):
		print "message to send is not length 7"
		sys.exit(2)
	values = spi.xfer2(to_send)
#	spi.xfer3(to_send)
#	time.sleep(0.001)
#	spi.writebytes2(to_send)
#	result = spi.readbytes(4)
#	show_c8_a16_d32(values, " values spi_send_command8_address16_data32")
	return values

def prepare_list_with_pseudorandom_values(memsize):
	data_list = [ d for d in range(memsize) ]
	for i in range(memsize):
		#pass
		#command_list[i] = random.randint(0,255)
		data_list[i] = random.randint(0,2**32-1)
		#data_list[i] = random.randint(0,2**31-1)
		#data_list[i] *= (1<<28) + (1<<24) + (1<<20) + (1<<16) + (1<<12) + (1<<8) + (1<<4) + 1
	#responses = [ set() for s in range(memsize) ]
	for i in range(memsize):
		data_list[i] &= 0xffffffff
		#data_list[i] &= 0x7fffffff
		#data_list[i] &= 0xf0000000
		#data_list[i] &= 0xff000000
		#data_list[i] &= 0x00ff0000
		#data_list[i] &= 0x0000ff00
		#data_list[i] &= 0x000000ff
		#data_list[i] = (i%2)<<31
		#if i%2:
		#	data_list[i] = 0x7fffffff
		#else:
		#	data_list[i] = 0xff000000
		#data_list[i] = 0xff00ff00
		#data_list[i] = 0x00ff00ff
		#data_list[i] = 0x800f00f0
		#print hex(data_list[i], 8)
#		datum = unpack32(data_list[i])
#		show_d8_4(datum, " test_command8_address16_data32")
#		data_list[i] = 0
#		if 128==i:
#			data_list[i] = 0xffffffff
#		if 128<i and i<132:
#			data_list[i] = i
#		if 132==i:
#			data_list[i] = 0xffffffff
#		if 134==i:
#			data_list[i] = 0xff773311
		if i<16:
			data_list[i] = 0
#		else:
#			data_list[i] = i
	return data_list

def write_list_to_spi_pollable_memory_in_pseudorandom_order(spi, memsize, command_list, address_list, data_list):
	global total_errors
	for i in random.sample(range(memsize), memsize):
		response = spi_send_command8_address16_data32(spi, command_list[i], address_list[i], data_list[i])
		if 7!=len(response):
			total_errors += 1
			print "function returned " + str(len(response)) + " words instead of 7"

def write_list_to_spi_pollable_memory_in_pseudorandom_order_and_record_responses_for_each_one(spi, memsize, command_list, address_list, data_list):
	global responses
	try:
		responses[i]
	except:
		responses = [ list() for s in range(memsize) ]
	global total_transfers
	try:
		total_transfers
	except:
		total_transfers = 0
	global total_errors
	try:
		total_errors
	except:
		total_errors = 0
	for i in random.sample(range(memsize), memsize):
		response = spi_send_command8_address16_data32(spi, command_list[i], address_list[i], data_list[i])
		if 7!=len(response):
			total_errors += 1
			print "function returned " + str(len(response)) + " words instead of 7"
		total_transfers += 1
		responses[i].append(response[3:7])

def verify_responses_match_input_data(spi, memsize, data_list, address_list):
	global responses
	for i in range(memsize):
		#print str(responses[i])
		string = "[" + hex(address_list[i], 4) + "]"
		#temp = pack32(unpack32(data_list[i]))
		#if temp!=data_list[i]:
		#	print "whoa!"
		#string += " value_written=" + hex(temp, 8)
		string += " value_written=" + hex(data_list[i], 8) + " read:"
		j = 0
		errors = 0
		values = {}
		for response in responses[i]:
#			print response
			value_read = pack32(response)
			try:
				values[value_read] += 1
			except:
				values[value_read] = 1
			#temp = data_list[i] & 0x55555555
			#if (temp!=value_read):
			if (data_list[i]!=value_read):
				errors += 1
			j += 1
		for key in values.keys():
			string += " [" + str(values[key]) + "]:" + hex(key, 8)
		if errors:
			total_errors += errors
			print string

def test_command8_address16_data32(spi, memsize, number_of_passes):
	# 30k transfers per second on a rpi2 @ 10e6 Hz
	print "testing spi_command8_address16_data32 peripheral..."
	size = number_of_passes * memsize
	global total_transfers
	total_transfers = 0
	global total_errors
	total_errors = 0
	command_list = [ c for c in range(memsize) ]
	address_list = [ a for a in range(memsize) ]
	global responses
	responses = [ list() for s in range(memsize) ]
	for i in range(memsize):
		command_list[i] &= 0xff
		address_list[i] &= 0xffff
	data_list = prepare_list_with_pseudorandom_values(memsize)
	start = time.time()
	write_list_to_spi_pollable_memory_in_pseudorandom_order(spi, memsize, command_list, address_list, data_list)
	for j in range(number_of_passes):
		write_list_to_spi_pollable_memory_in_pseudorandom_order_and_record_responses_for_each_one(spi, memsize, command_list, address_list, data_list)
	end = time.time()
	diff = end - start
	per = diff / memsize
	transfers_per_sec = size / diff
	verify_responses_match_input_data(spi, memsize, data_list, address_list)
#	print "total_errors=" + str(total_errors)
#	print "total_transfers=" + str(total_transfers)
	if (total_errors):
		BER = float(total_errors+1)/total_transfers
		print "BER<=" + eng(BER, "%.1f")
	else:
		print str(size) + " transfers completed successfully"
	print eng(transfers_per_sec) + " transfers per second"

def write_list_to_pollable_memory_and_then_verify(spi, memsize, command_list, address_list, data_list):
	write_list_to_spi_pollable_memory_in_pseudorandom_order(spi, memsize, command_list, address_list, data_list)
	write_list_to_spi_pollable_memory_in_pseudorandom_order_and_record_responses_for_each_one(spi, memsize, command_list, address_list, data_list)
	verify_responses_match_input_data(spi, memsize, data_list, address_list)

def write_pseudorandom_values_to_spi_pollable_memory_and_verify(spi, memsize):
	command_list = [ c for c in range(memsize) ]
	address_list = [ a for a in range(memsize) ]
	data_list = prepare_list_with_pseudorandom_values(memsize)
	write_list_to_pollable_memory_and_then_verify(spi, memsize, command_list, address_list, data_list)

def write_zero_values_to_spi_pollable_memory_and_verify(spi, memsize):
	command_list = [ c for c in range(memsize) ]
	address_list = [ a for a in range(memsize) ]
	data_list = [ 0 for d in range(memsize) ]
	write_list_to_pollable_memory_and_then_verify(spi, memsize, command_list, address_list, data_list)

import os
import re
RF_buckets = 5120
MAX_FOR_NORMALIZATION = 6.0
# borrowed from xrm.py in uh-svn-repo; reads from csv files generated by xrm.py
def read_bcm_csv(input_filename, date_string):
	print "loading bcm timeseries from file..."
	scaling = 2
	values = []
	if os.path.isfile(input_filename):
		input_file = open(input_filename)
		lines = input_file.readlines()
		for line in lines:
			match = re.search("^" + date_string + ",(.*)", line)
			if match:
				valuestring = match.group(1)
				values = re.split(r',', valuestring)
				count = len(values)
				if not count==scaling*RF_buckets:
					#warning("read in " + str(count) + " datapoints")
					pass
	max_value = 0
	if len(values)==0:
		#warning("no data found in file")
		return
	for i in range(len(values)):
		values[i] = int(values[i])
		max_value = max(max_value, values[i])
	#info("max_value: " + str(max_value))
	if max_value==0:
		#warning("no data found in file")
		return
	normalization = MAX_FOR_NORMALIZATION / max_value
	#info("normalization: " + str(normalization))
	for i in range(len(values)):
		values[i] = int(values[i]*normalization)
	return values

def write_bcm_values_to_spi_pollable_memory_and_verify(spi, memsize, input_filename, date_string):
	print "uploading bcm timeseries to device..."
	command_list = [ c for c in range(memsize) ]
	address_list = [ a for a in range(memsize) ]
	data_list = [ 0 for d in range(memsize) ]
	if 1:
		bcm_list = read_bcm_csv(input_filename, date_string)
	else:
		bcm_list = [ 
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
			1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
			1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1  ]
	# bcm_list has an integer entry for each RF_bucket as a time series
	# data_list has an entry for each group of 32 RF_buckets
	k = 0
	value_low = 0
	for i in range(0, len(bcm_list), 32):
		value = value_low<<32
		for j in range(32):
			if bcm_list[i+j]:
				#pulse_width = 2
				pulse_width = bcm_list[i+j]
				index = 31-j-pulse_width+32 # fill the high part of a 64-bit word
				value |= (2**pulse_width-1)<<index
		#print hex(value, 8)
		value_low = value & 0xffffffff # save what spilled over into the low 32 bits for next time
		value_high = value - value_low
		data_list[k] = value_high>>32
		k += 1
	#print k
	#print len(data_list)
	if len(data_list)<memsize:
		for i in range(len(data_list), memsize):
			data_list.append(0)
#	for i in range(memsize):
#		if i<64:
#			data_list[i] = 0
#	print len(data_list)
	for i in range(memsize):
		data_list[i] &= 0xffffffff
	write_list_to_pollable_memory_and_then_verify(spi, memsize, command_list, address_list, data_list)

#test_command8_address16_data32(spi_ce0, 2**4, 40)
#test_command8_address16_data32(spi_ce1, 2**12, 10)

#write_pseudorandom_values_to_spi_pollable_memory_and_verify(spi_ce1, 2**12)
#write_zero_values_to_spi_pollable_memory_and_verify(spi_ce1, 2**12)
date_string = "2019-11-15.075530"
write_bcm_values_to_spi_pollable_memory_and_verify(spi_ce1, 2**12, "bcm.csv", date_string)

