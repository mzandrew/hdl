# written 2020-05-23 by mza
# based on ./mza-test042.spi-pollable-memories-and-oserdes-function-generator.althea.py
# last updated 2020-06-09 by mza

import time
import time # time.sleep
import random # randint
import sys # sys.exit
import math
import os # os.path.isfile
import re # re.search
import RPi.GPIO as GPIO
#import pigpio # the daemon causes conflicts the way we were using it
import spidev
from generic import * # hex, eng
import fastgpio # fastgpio.bus

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)

# ---------------------------------------------------------------------------

def set_all_gpio_as_inputs():
	gpios = [ g for g in range(2, 26+1) ]
	for gpio in gpios:
		GPIO.setup(gpio, GPIO.IN)

def pulse(gpio, duration):
	GPIO.setup(gpio, GPIO.OUT)
	GPIO.output(gpio, GPIO.HIGH)
	time.sleep(duration)
	GPIO.output(gpio, GPIO.LOW)

def reset_pulse(gpio=19):
	pulse(gpio, 0.1)
	time.sleep(0.1)

def test_some_gpios():
	GPIO.setup(13, GPIO.OUT)
	GPIO.output(13, GPIO.HIGH)
	time.sleep(1.0)
	GPIO.output(13, GPIO.LOW)

def gpio_state(gpio):
	GPIO.setup(gpio, GPIO.IN)
	time.sleep(0.05)
	state = GPIO.input(gpio)
	if state:
		state = True
	else:
		state = False
	return state

#def setup_gpios():
#	fastgpio.setup_gpios()

# ---------------------------------------------------------------------------

def wait_for_ready():
	while 0==gpio_state(5):
		time.sleep(0.1)

def clock_select(which):
	GPIO.setup(13, GPIO.OUT)
	if which:
		GPIO.output(13, GPIO.HIGH)
	else:
		GPIO.output(13, GPIO.LOW)

# this requires pigpiod be run beforehand
def enable_clock(frequency_in_MHz):
	print("ERROR: pigpio no longer used; you must use the config/setup_clock.sh script instead")
	#GPIO.setup(6, GPIO.ALT0)
	gpio=6
	#os.system("sudo pigpiod")
#	pi = pigpio.pi()
#	frequency = int(frequency_in_MHz * 1.0e6)
#	pi.hardware_clock(gpio, frequency)
#	pi.set_mode(gpio, pigpio.ALT0)
	#value = pi.get_mode(gpio)
	#print(str(value))
#	GPIO.setup(6, GPIO.OUT)
#	GPIO.output(6, GPIO.LOW)

def disable_clock():
	gpio=6
	GPIO.setup(gpio, GPIO.OUT)
	GPIO.output(gpio, GPIO.LOW)
	#GPIO.setup(gpio, GPIO.IN)

def select_clock_and_reset_althea(choice=0):
	if choice:
		enable_clock(10.0) # rpi_gpio6_gpclk2 = 10.0 MHz
		clock_select(1) # built-in osc (0) or output from rpi_gpio6_gpclk2 (1)
	else:
		clock_select(0) # built-in osc (0) or output from rpi_gpio6_gpclk2 (1)
		disable_clock() # rpi_gpio6_gpclk2 no longer set to gpclk mode
	reset_pulse()
	wait_for_ready() # wait for oserdes pll to lock

# ---------------------------------------------------------------------------

gpio_all = [ i for i in range(27+1) ] # all possible gpios on a raspberry pi 40 pin header
gpio_used_for_spi = [ 7, 8, 9, 10, 11 ] # CE1, CE0, MISO, MOSI, SCLK
#gpio_used_for_jtag = [ 12, 16, 17, 18, 22, 27 ] # DONE, TRST, TDI, TCK, TMS, TDO
gpio_used_for_jtag = [ 16, 17, 18, 19, 22, 27 ] # TRST, TDI, DONE, TCK, TMS, TDO (swap 12 and 19)
gpio_used_for_i2c_eeprom = [ 0, 1 ] # SDA, SCL
def althea_revB_gpios():
	gpio = [ gpio_all[i] for i in range(len(gpio_all)) ]
	if 1:
		for g in gpio_used_for_jtag:
			gpio.remove(g)
	if 0:
		for g in gpio_used_for_spi:
			gpio.remove(g)
	if 0:
		for g in gpio_used_for_i2c_eeprom:
			gpio.remove(g)
	return gpio
gpio = althea_revB_gpios()
rle_gpio = run_lenth_encode_monotonicity(gpio)
#print(str(rle_gpio))
show_longest_run(rle_gpio)

# https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/
def test_speed_of_setting_gpios_individually():
	time.sleep(0.1)
	print("setting up for individual gpio mode...")
	bits = len(gpio)
	print(str(gpio))
	#print(sorted(gpio))
	#print(len(gpio))
	for g in gpio:
		GPIO.setup(g, GPIO.OUT)
	number_of_transfers = 0
	NUM = 7729
	#start = time.time()
	data = [ random.randint(0,2**bits-1) for d in range(NUM) ]
	#end = time.time()
	#diff = end - start
	#print(str(diff))
	#if diff>epsilon:
	#	per_sec = NUM / diff
	#	#print(str(per_sec))
	#	print(eng(per_sec) + " randint() per second" # "60.1e3 randint() per second" on a rpi2)
	print("running...")
	start = time.time()
	for i in range(NUM):
		for j in range(bits):
			#GPIO.output(gpio[j], data[i][j] ? GPIO.HIGH : GPIO.LOW)
			if bit(data[i], j):
				bitstate = GPIO.HIGH
			else:
				bitstate = GPIO.LOW
			GPIO.output(gpio[j], bitstate)
		number_of_transfers += 1
	end = time.time()
	diff = end - start
	#print("%.3f"%diff + " seconds")
	per_sec = number_of_transfers / diff
	#print(eng(per_sec) + " transfers per second") # "9.9e3 transfers per second" on a rpi2
	per_sec *= bits
	#print(eng(per_sec) + " bits per second") # "246.2e3 transfers per second" on a rpi2
	print("%.3f"%(per_sec/8.0e6) + " MB per second") # 0.024 MB per second on an rpi2
	#GPIO.cleanup()
	#GPIO.setwarnings(False)
	#GPIO.setmode(GPIO.BCM)
	time.sleep(0.1)

# https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/
def test_speed_of_setting_gpios_grouped():
	print("setting up for grouped gpio mode...")
	time.sleep(0.1)
	bits = len(gpio)
	print(str(gpio))
	#print(len(gpio))
	for g in gpio:
		GPIO.setup(g, GPIO.OUT)
	number_of_transfers = 0
	NUM = 7729
	#start = time.time()
	data = [ random.randint(0,2**bits-1) for d in range(NUM) ]
	#end = time.time()
	#diff = end - start
	#print(str(diff))
	#if diff>epsilon:
	#	per_sec = NUM / diff
	#	#print(str(per_sec))
	#	print(eng(per_sec) + " randint() per second" # "60.1e3 randint() per second" on a rpi2)
	print("running...")
	start = time.time()
	for i in range(NUM):
		mylist = []
		for j in range(bits):
			#GPIO.output(gpio[j], data[i][j] ? GPIO.HIGH : GPIO.LOW)
			if bit(data[i], j):
				bitstate = GPIO.HIGH
			else:
				bitstate = GPIO.LOW
			mylist.append(bitstate)
		GPIO.output(gpio, mylist)
		number_of_transfers += 1
	end = time.time()
	diff = end - start
	#print("%.3f"%diff + " seconds")
	per_sec = number_of_transfers / diff
	#print(eng(per_sec) + " transfers per second") # "9.9e3 transfers per second" on a rpi2
	per_sec *= bits
	#print(eng(per_sec) + " bits per second") # "246.2e3 transfers per second" on a rpi2
	print("%.3f"%(per_sec/8.0e6) + " MB per second") # 0.032 MB per second on an rpi2
	#GPIO.cleanup()
	#GPIO.setwarnings(False)
	#GPIO.setmode(GPIO.BCM)
	time.sleep(0.1)

def test_speed_of_setting_gpios_with_fastgpio_full_bus_width():
	print("setting up for fastgpio mode...")
	time.sleep(0.1)
	bits = len(gpio)
	print("this bus is " + str(bits) + " bits wide") # this bus is 20 bits wide
	print(str(gpio))
	NUM = 100000
	data = [ random.randint(0,2**32-1) for d in range(NUM) ]
	#NUM = len(data)
	mask = buildmask(gpio)
	output_bus = fastgpio.bus(mask, 1, 0)
	print("running...")
	start = time.time()
	output_bus.write(data)
	end = time.time()
	diff = end - start
	per_sec = NUM / diff
	#print("%.3f"%diff + " seconds")
	per_sec *= bits
	#print(str(per_sec) + " bits per second") # 237073479.53877458 bits per second
	#print(str(per_sec/8.0) + " bytes per second") # 29691244.761581153 bytes per second
	print("%.3f"%(per_sec/8.0e6) + " MB per second") # 26.878 MB per second on an rpi2
	time.sleep(0.1)

def test_speed_of_setting_gpios_with_fastgpio_half_bus_width():
	print("setting up for fastgpio mode...")
	time.sleep(0.1)
	half = len(gpio)//2
	print(str(half))
	gpio_in = [ gpio[i] for i in range(0, half) ] # althea revB
	gpio_out = [ gpio[i] for i in range(half, len(gpio)) ] # althea revB
	print(str(gpio_in))
	print(str(gpio_out))
	bits_in = len(gpio_in)
	bits_out = len(gpio_out)
	NUM = 10000
	#data = [ random.randint(0,2**32-1) for d in range(NUM) ]
	if 1:
		data = [ random.randint(0,2**bits_out-1) for d in range(NUM) ]
	else:
		data = [ d for d in range(NUM) ]
		for i in range(NUM):
			value = i%2
			for j in range(bits_out-1):
				value |= value<<1
			data[i] = value
			#print(hex(value, 8))
	#NUM = len(data)
	#mask_in = buildmask(gpio_in)
	#input_bus = fastgpio.bus(mask_in, 0, 2)
	mask_out = buildmask(gpio_out)
	#output_bus = fastgpio.bus(mask_out, 1, 0)
	output_bus = fastgpio.bus(mask_out, 1, 14)
	print("running...")
	start = time.time()
	output_bus.write(data)
	end = time.time()
	diff = end - start
	per_sec = NUM / diff
	#print("%.3f"%diff + " seconds")
	per_sec *= bits_out
	#print(str(per_sec) + " bits per second") # 237073479.53877458 bits per second
	#print(str(per_sec/8.0) + " bytes per second") # 29691244.761581153 bytes per second
	print("%.3f"%(per_sec/8.0e6) + " MB per second") # 14.976 MB per second on an rpi2
	time.sleep(0.1)

def test_speed_of_setting_gpios_with_fastgpio_half_duplex(bus_width=16):
	print("setting up for fastgpio mode...")
	time.sleep(0.1)
	gpio_bus = [ gpio[i] for i in range(bus_width) ]
	print(str(gpio_bus))
	bits_bus = len(gpio_bus)
	print("this bus is " + str(bits_bus) + " bits wide")
	NUM = 10000
	#data = [ random.randint(0,2**32-1) for d in range(NUM) ]
	if 1:
		data = [ random.randint(0,2**bits_bus-1) for d in range(NUM) ]
	else:
		data = [ d for d in range(NUM) ]
		for i in range(NUM):
			value = i%2
			for j in range(bits_bus-1):
				value |= value<<1
			data[i] = value
			#print(hex(value, 8))
	#NUM = len(data)
	mask_bus = buildmask(gpio_bus)
	output_bus = fastgpio.bus(mask_bus, 1, 2)
	print("running...")
	start = time.time()
	output_bus.write(data)
	end = time.time()
	diff = end - start
	per_sec = NUM / diff
	#print("%.3f"%diff + " seconds")
	per_sec *= bits_bus
	#print(str(per_sec) + " bits per second") # 237073479.53877458 bits per second
	#print(str(per_sec/8.0) + " bytes per second") # 29691244.761581153 bytes per second
	print("%.3f"%(per_sec/8.0e6) + " MB per second") # 14.596 MB per second on an rpi2
	time.sleep(0.1)

# ---------------------------------------------------------------------------

#import copy
def unpack32(data):
#	string = "unpack32(" + hex(data, 8) + ")="
#	print(string)
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
#	print(string)
	if 4!=len(datum):
		print("error: len()!=4")
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
		#print(hex(data_list[i], 8))
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
		print("blah")
	else:
		#print(hex(c8_a16_d32[0],2))
		#print(hex(c8_a16_d32[1],2) + " " + hex(c8_a16_d32[2],2))
		print(hex(c8_a16_d32[3],2) + " " + hex(c8_a16_d32[4],2) + " " + hex(c8_a16_d32[5],2) + " " + hex(c8_a16_d32[6],2) + suffix_string)

def show_d8_4(datum, suffix_string=""):
	if 4!=len(datum):
		print("blah_datum")
		sys.exit(1)
	else:
		print(hex(datum[0],2) + " " + hex(datum[1],2) + " " + hex(datum[2],2) + " " + hex(datum[3],2) + suffix_string)

def show_d32(d32, suffix_string=""):
	print(hex((d32>>24)&0xff,2) + " " + hex((d32>>16)&0xff,2) + " " + hex((d32>>8)&0xff,2) + " " + hex((d32>>0)&0xff,2) + suffix_string)

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

MAX_SPEED_HZ = 4e6 # 4e6 works without errors

# ---------------------------------------------------------------------------

class spi(spidev.SpiDev):
	def __init__(self, ce, spi_memory_size):
		#super().__init__(self)
		super(spi, self).__init__()
		self.open(0, ce)
		self.max_speed_hz = int(MAX_SPEED_HZ)
		self.mode = 0b00
		self.memsize = spi_memory_size
		self.total_transfers = 0
		self.total_errors = 0
		self.responses = [ list() for a in range(self.memsize) ]
		if 0:
			gpios = [ 7, 8, 9, 10, 11 ]
			pi = pigpio.pi()
			for gpio in gpios:
				# https://elinux.org/RPi_BCM2835_GPIOs
				pi.set_mode(gpio, pigpio.ALT0)
				#GPIO.setup(gpio, GPIO.SPI)

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
		#print(hex(datum[0], 2))
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
			print("message to send is not length 7")
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
					print("function returned " + str(len(response)) + " words instead of 7")

	def write_list_to_spi_pollable_memory_in_pseudorandom_order_and_record_responses_for_each_one(self, length, command_list, address_list, data_list):
		for i in random.sample(range(length), length):
			if 0<=address_list[i] and address_list[i]<self.memsize:
				response = self.spi_send_command8_address16_data32(command_list[i], address_list[i], data_list[i])
				if 7!=len(response):
					self.total_errors += 1
					print("function returned " + str(len(response)) + " words instead of 7")
				else:
					#print("i=" + str(i))
					#print("len=" + str(len(response)))
					self.responses[i].append(response[3:7])
				self.total_transfers += 1
			else:
				#total_errors += 1
				#self.responses[i].append([0,0,0,0])
				self.responses[i].append(unpack32(data_list[i])) # fake the response for addresses above self.memsize-1

	def verify_responses_match_input_data(self, length, data_list, address_list):
		for i in range(length):
			#print(str(responses[i]))
			string = "[" + hex(address_list[i], 4) + "]"
			#temp = pack32(unpack32(data_list[i]))
			#if temp!=data_list[i]:
			#	print("whoa!")
			#string += " value_written=" + hex(temp, 8)
			string += " value_written=" + hex(data_list[i], 8) + " read:"
			j = 0
			errors = 0
			values = {}
			for response in self.responses[i]:
	#			print(response)
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
					self.total_errors += errors
				except:
					self.total_errors = errors
				print(string)

	def read_values_from_spi_pollable_memory(self, length, offset):
		command_list = [ c for c in range(length) ]
		address_list = [ offset+a for a in range(length) ]
		data_list = [ 0 for d in range(length) ]
		values = [ 0 for v in range(length) ]
		for i in random.sample(range(length), length):
			if 0<=address_list[i] and address_list[i]<self.memsize:
				response = self.spi_send_command8_address16_data32(command_list[i], address_list[i], data_list[i])
				if 7!=len(response):
					self.total_errors += 1
					print("function returned " + str(len(response)) + " words instead of 7")
				else:
					value_read = pack32(response[3:7])
					#print(str(value_read))
					values[i] = value_read
				self.total_transfers += 1
		return values

	def test_command8_address16_data32(self, number_of_passes):
		# 30k transfers per second on a rpi2 @ 10e6 Hz
		print("testing spi_command8_address16_data32 peripheral...")
		size = number_of_passes * self.memsize
		self.total_transfers = 0
		self.total_errors = 0
		command_list = [ c for c in range(self.memsize) ]
		address_list = [ a for a in range(self.memsize) ]
		self.responses = [ list() for s in range(self.memsize) ]
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
	#	print("total_errors=" + str(self.total_errors))
	#	print("total_transfers=" + str(self.total_transfers))
		if (self.total_errors):
			BER = float(self.total_errors+1)/self.total_transfers
			print("BER<=" + eng(BER, "%.1f"))
		else:
			print(str(size) + " transfers completed successfully")
		print(eng(transfers_per_sec) + " transfers per second")

	def write_list_to_pollable_memory_and_then_verify(self, length, command_list, address_list, data_list):
		command_list, address_list, data_list = regularize_lists(length, command_list, address_list, data_list)
		#print(hex(address_list[0], 4) + ", " + hex(address_list[length-1], 4))
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
		self.responses = [ list() for a in range(self.memsize) ]
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

# borrowed from xrm.py in uh-svn-repo; reads from csv files generated by xrm.py
def read_csv(input_filename, date_string, max_count):
	print("loading csv timeseries from file...")
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
				if not count==max_count:
					#warning("read in " + str(count) + " datapoints")
					pass
	else:
		print("can't open file \"" + input_filename + "\"")
		sys.exit(1)
	return values

def normalize_csv_data(values, max_for_normalization):
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
	normalization = max_for_normalization / max_value
	#info("normalization: " + str(normalization))
	for i in range(len(values)):
		values[i] = int(values[i]*normalization)
	return values

class spi_sequencer(spi):
	def __init__(self, ce, spi_memory_size):
		#super().__init__(self)
		super(spi_sequencer, self).__init__(ce, spi_memory_size)

	def write_csv_values_to_spi_pollable_memory_and_verify(self, length, offset, max_count, input_filename, date_string, max_for_normalization=6.0):
		offset = int(offset/16.0)
		max_for_normalization = float(max_for_normalization)
		length = int(length)
		command_list = [ c for c in range(length) ]
		address_list = [ offset+a for a in range(length) ]
		data_list = [ 0 for d in range(length) ]
		if 1:
			csv_list = read_csv(input_filename, date_string, max_count)
			csv_list = normalize_csv_data(csv_list, max_for_normalization)
		else:
			csv_list = [ 
				1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
				1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
				1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1  ]
		# csv_list has an integer entry for each RF_bucket as a time series
		# data_list has an entry for each group of 32 RF_buckets
		k = 0
		value_low = 0
		for i in range(0, len(csv_list), 32):
			value = value_low<<32
			for j in range(32):
				if csv_list[i+j]:
					#pulse_width = 2
					pulse_width = csv_list[i+j]
					index = 31-j-pulse_width+32 # fill the high part of a 64-bit word
					value |= (2**pulse_width-1)<<index
			#print(hex(value, 8))
			value_low = value & 0xffffffff # save what spilled over into the low 32 bits for next time
			value_high = value - value_low
			data_list[k] = value_high>>32
			k += 1
		#print(k)
		#print(len(data_list))
		if len(data_list)<length:
			for i in range(len(data_list), length):
				data_list.append(0)
	#	for i in range(length):
	#		if i<64:
	#			data_list[i] = 0
	#	print(len(data_list))
		print("uploading csv timeseries to device...")
		self.write_list_to_pollable_memory_and_then_verify(length, command_list, address_list, data_list)

# 10240 samples per revolution
# 1 address per 8 samples
# 10240/8=1280 addresses per revolution
# 9*10240/8=9*1280 addresses per revo9
# updated firmware so that the start/end limits are in units of RF_buckets
# but keep in mind that the 2 least significant bits are discarded
#write_values_to_spi_pollable_memory_and_verify(spi_ce0, 2**4, [ 0, 1*RF_buckets ])
#write_values_to_spi_pollable_memory_and_verify(spi_ce0, 2**4, [ 0.5*RF_buckets, 3.2*RF_buckets ])
#write_values_to_spi_pollable_memory_and_verify(spi_ce0, 2**4, [ 0, 9*RF_buckets ])
#if 0:
#	while True:
#		for i in range(0, 640, 16):
#			j = i + 640
#			#for j in range(640, 1280, 16):
#			#	print(str(i) + "," + str(j))
#			spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ i, j ])
#			time.sleep(0.01)

#test_command8_address16_data32(spi_ce0, 2**4, 40)
#test_command8_address16_data32(spi_ce1, 2**12, 10)

# ---------------------------------------------------------------------------

