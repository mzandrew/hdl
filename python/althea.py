# written 2020-05-23 by mza
# based on ./mza-test042.spi-pollable-memories-and-oserdes-function-generator.althea.py
# last updated 2020-05-23 by mza

import time
import RPi.GPIO as GPIO
import time # time.sleep
import random #
import sys # sys.exit
import math
import spidev

from generic import * # hex, eng

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)

def pulse(gpio, duration):
	GPIO.setup(gpio, GPIO.OUT)
	GPIO.output(gpio, GPIO.HIGH)
	time.sleep(duration)
	GPIO.output(gpio, GPIO.LOW)

def reset(gpio=19):
	pulse(gpio, 0.1)

def test_some_gpios():
	GPIO.setup(13, GPIO.OUT)
	GPIO.setup(19, GPIO.OUT)
	GPIO.output(13, GPIO.HIGH)
	GPIO.output(19, GPIO.HIGH)
	time.sleep(1.0)
	GPIO.output(13, GPIO.LOW)
	GPIO.output(19, GPIO.LOW)

#import copy
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

def prepare_list_with_pseudorandom_values(memsize):
	data_list = [ d for d in range(memsize) ]
	for i in range(memsize):
		#pass
		#command_list[i] = random.randint(0,255)
		data_list[i] = random.randint(0,2**32-1)
		#data_list[i] = random.randint(0,2**31-1)
		#data_list[i] *= (1<<28) + (1<<24) + (1<<20) + (1<<16) + (1<<12) + (1<<8) + (1<<4) + 1
	#responses = [ set() for s in range(memsize) ]
#	for i in range(memsize):
		#data_list[i] &= 0xffffffff
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
#		if i<16:
#			data_list[i] = 0
#		else:
#			data_list[i] = i
	for i in range(1):
		data_list[i] = 0
	return data_list

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

def regularize_lists(length, command_list, address_list, data_list):
	for i in range(length):
		command_list[i] = int(command_list[i]) &       0xff
		address_list[i] = int(address_list[i])
		data_list[i]    = int(data_list[i])    & 0xffffffff
	return command_list, address_list, data_list

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

#class spi_internal(spidev.SpiDev):
#	def __init__(self, memsize):
#		self.memsize = memsize

class spi(spidev.SpiDev):
	def __init__(self, ce, spi_memory_size):
		#super().__init__(self)
		super(spi, self).__init__()
		#spi_ce0 = spidev.SpiDev()
		#spi_ce0 = spi_internal(spi_memory_size)
		#spi = spidev.SpiDev
		self.open(0, ce)
		self.max_speed_hz = int(6e6) # 11e6 works without errors; 12e6 fails often (BER=640e-3)
		self.mode = 0b00
		#spi_ce1 = spidev.SpiDev()
		#spi_ce1 = spi_internal(spi_ce1_size)
		#spi_ce1.open(0, 1)
		#spi_ce1.max_speed_hz = int(6e6) # 11e6 works without errors; 12e6 fails often (BER=640e-3)
		#spi_ce1.mode = 0b00
		self.memsize = spi_memory_size
		#return self

	def spi_send_command8_address16_data32(self, command, address, data):
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
	#	self.writebytes(to_send)
	#	self.xfer(to_send)
		#values = self.xfer2(copy.deepcopy(to_send_b))
		#to_send = to_send_b
	#	to_send = copy.deepcopy(to_send_b)
		if 7!=len(to_send):
			print "message to send is not length 7"
			sys.exit(2)
		values = self.xfer2(to_send)
	#	self.xfer3(to_send)
	#	time.sleep(0.001)
	#	self.writebytes2(to_send)
	#	result = self.readbytes(4)
	#	show_c8_a16_d32(values, " values spi_send_command8_address16_data32")
		return values

	def write_list_to_spi_pollable_memory_in_pseudorandom_order(self, length, command_list, address_list, data_list):
		global total_errors
		for i in random.sample(range(length), length):
			if 0<=address_list[i] and address_list[i]<self.memsize:
				response = self.spi_send_command8_address16_data32(command_list[i], address_list[i], data_list[i])
				if 7!=len(response):
					total_errors += 1
					print "function returned " + str(len(response)) + " words instead of 7"

	def write_list_to_spi_pollable_memory_in_pseudorandom_order_and_record_responses_for_each_one(self, length, command_list, address_list, data_list):
		global responses
		try:
			responses[i]
		except:
			responses = [ list() for s in range(self.memsize) ]
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
		for i in random.sample(range(length), length):
			if 0<=address_list[i] and address_list[i]<self.memsize:
				response = self.spi_send_command8_address16_data32(command_list[i], address_list[i], data_list[i])
				if 7!=len(response):
					total_errors += 1
					print "function returned " + str(len(response)) + " words instead of 7"
				total_transfers += 1
				responses[i].append(response[3:7])
			else:
				#total_errors += 1
				#responses[i].append([0,0,0,0])
				responses[i].append(unpack32(data_list[i])) # fake the response for addresses above self.memsize-1

	def verify_responses_match_input_data(self, length, data_list, address_list):
		global responses
		for i in range(length):
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
				try:
					total_errors += errors
				except:
					total_errors = errors
				print string

	def test_command8_address16_data32(self, number_of_passes):
		# 30k transfers per second on a rpi2 @ 10e6 Hz
		print "testing spi_command8_address16_data32 peripheral..."
		size = number_of_passes * self.memsize
		global total_transfers
		total_transfers = 0
		global total_errors
		total_errors = 0
		command_list = [ c for c in range(self.memsize) ]
		address_list = [ a for a in range(self.memsize) ]
		global responses
		responses = [ list() for s in range(self.memsize) ]
	#	for i in range(self.memsize):
	#		command_list[i] &= 0xff
	#		address_list[i] &= 0xffff
		data_list = prepare_list_with_pseudorandom_values(self.memsize)
		start = time.time()
		self.write_list_to_spi_pollable_memory_in_pseudorandom_order(self.memsize, command_list, address_list, data_list)
		for j in range(number_of_passes):
			self.write_list_to_spi_pollable_memory_in_pseudorandom_order_and_record_responses_for_each_one(self.memsize, command_list, address_list, data_list)
		end = time.time()
		diff = end - start
		per = diff / self.memsize
		transfers_per_sec = size / diff
		self.verify_responses_match_input_data(self.memsize, data_list, address_list)
	#	print "total_errors=" + str(total_errors)
	#	print "total_transfers=" + str(total_transfers)
		if (total_errors):
			BER = float(total_errors+1)/total_transfers
			print "BER<=" + eng(BER, "%.1f")
		else:
			print str(size) + " transfers completed successfully"
		print eng(transfers_per_sec) + " transfers per second"

	def write_list_to_pollable_memory_and_then_verify(self, length, command_list, address_list, data_list):
		command_list, address_list, data_list = regularize_lists(length, command_list, address_list, data_list)
		#print hex(address_list[0], 4) + ", " + hex(address_list[length-1], 4)
		self.write_list_to_spi_pollable_memory_in_pseudorandom_order(length, command_list, address_list, data_list)
		self.write_list_to_spi_pollable_memory_in_pseudorandom_order_and_record_responses_for_each_one(length, command_list, address_list, data_list)
		self.verify_responses_match_input_data(length, data_list, address_list)

	def write_pseudorandom_values_to_spi_pollable_memory_and_verify(self, length, offset=0):
		command_list = [ c for c in range(length) ]
		address_list = [ offset+a for a in range(length) ]
		data_list = prepare_list_with_pseudorandom_values(length)
		self.write_list_to_pollable_memory_and_then_verify(length, command_list, address_list, data_list)

	def write_zero_values_to_spi_pollable_memory_and_verify(self, length, offset=0):
		command_list = [ c for c in range(length) ]
		address_list = [ offset+a for a in range(length) ]
		data_list = [ 0 for d in range(length) ]
		self.write_list_to_pollable_memory_and_then_verify(length, command_list, address_list, data_list)

	def write_values_to_spi_pollable_memory_and_verify(self, length, data_list, offset=0):
		command_list = [ c for c in range(length) ]
		address_list = [ offset+a for a in range(length) ]
		#data_list = [ 0 for d in range(length) ]
		if len(data_list)<length:
			for i in range(len(data_list), length):
				data_list.append(0)
		self.write_list_to_pollable_memory_and_then_verify(length, command_list, address_list, data_list)

	def write_sequential_values_to_spi_pollable_memory_and_verify(self, length, offset=0):
		command_list = [ c for c in range(length) ]
		address_list = [ offset+a for a in range(length) ]
		data_list = [ d for d in range(length) ]
		self.write_list_to_pollable_memory_and_then_verify(length, command_list, address_list, data_list)

#class double_spi():

#class double_spi_sequencer():

