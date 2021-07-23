#!/usr/bin/env python3

# written 2020-06-20 by mza
# based on mza-test042.spi-pollable-memories-and-oserdes-function-generator.althea.py
# last updated 2021-04-16 by mza

import time # time.sleep
import sys # sys.exit
import random # randint
from generic import * # hex, eng
import althea

RF_buckets = 5120
scaling = 2
max_count = scaling*RF_buckets
date_string = "2019-11-15.075530"
size = RF_buckets/16
N = 10.0

#spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ 2, 0 ], 2) # test idelay inc/dec functionality

def read_frequency_counter_value(spi):
	value, = spi.read_values_from_spi_pollable_memory(1, 0xf)
	value = N * value / 1.0e6
	return value

def show_frequency_counter_value(spi):
	value = read_frequency_counter_value(spi)
	print(str(value))

def stop_ring_oscillator(spi):
	spi.write_values_to_spi_pollable_memory_and_verify(2, [ 0, 0 ], 2)

N_bits_coarse = 4
N_bits_medium = 4
N_bits_fine = 4
max_coarse = 2**N_bits_coarse
max_medium = 2**N_bits_medium
max_fine = 2**N_bits_fine

def set_ring_oscillator_values(spi, coarse, medium, fine):
	value = 0
	value |= coarse <<(N_bits_medium+N_bits_fine)
	value |= medium <<(N_bits_fine)
	value |= fine
	print("[" + str(coarse) + "," + str(medium) + "," + str(fine) + "] " + str(value) + " =",)
	spi.write_values_to_spi_pollable_memory_and_verify(2, [ 1, value ], 2) # test ring_oscillator functionality

def scan_ring_oscillator(spi, coarse=max_coarse, medium=max_medium, fine=max_fine):
	if coarse==max_coarse:
		coarses = [ c for c in range(max_coarse) ]
	else:
		coarses = [ coarse ]
	if medium==max_medium:
		mediums = [ m for m in range(max_medium) ]
	else:
		mediums = [ medium ]
	if fine==max_fine:
		fines = [ f for f in range(max_fine) ]
	else:
		fines = [ fine ]
	#print(str(coarses) + " " + str(mediums) + " " + str(fines))
	for coarse in coarses:
		for medium in mediums:
			for fine in fines:
				set_ring_oscillator_values(spi, coarse, medium, fine)
				time.sleep(1.0)
				show_frequency_counter_value(spi)

def old_continuously_scan_ring_oscillator(spi, min, max, s=1):
	while True:
		scan_ring_oscillator(min, max, s)

#scan_ring_oscillator(spi_ce0, 10)
#scan_ring_oscillator(spi_ce0)
#stop_ring_oscillator(spi_ce0)
#set_ring_oscillator_to(spi_ce0, 10.0)

def cycle(number_of_segments, segment_size):
	print("cycling...")
	i = 0
	while True:
		j = i % number_of_segments
		k = (i + 1) % number_of_segments
		if 0==k:
			k = number_of_segments
		#print(str(j) + " " + str(k))
		spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ j*segment_size,k*segment_size])
		i += 1
		time.sleep(0.1)

if 0:
	althea.set_this_gpio_as_an_input(2)
	#althea.set_this_gpio_as_an_output(2)

if 0:
	althea.set_all_gpio_as_inputs()

if 0:
	althea.setup_for_simple_parallel_bus()
	althea.test_writing_data_to_simple_parallel_bus()

if 0:
	althea.reset_pulse()
	time.sleep(0.1)

if 1:
	althea.setup_half_duplex_bus("test046")

if 0:
	althea.setup_half_duplex_bus("test049")

if 1:
	j = 2
	values = [ 0 for a in range(2**4) ]
	values[0] = 3 # bitslip_iserdes[2:0]
	values[1] = 1 # bitslip_oserdes1[2:0]
	values[2] = 1 # bitslip_oserdes1_again[2:0]
	values[3] = 3 # word_clock_sel[1:0]
	values[4] = 1 # oserdes_train [0]
	values[5] = 0b11001010 # oserdes_train_pattern [7:0]
	#values[5] = 0b11110000 # oserdes_train_pattern [7:0]
	values[6] = 0 # start_sample (3 LSBs ignored)
	values[7] = 16 # end_sample (3 LSBs ignored)
	values[8] = 0b10 # clear histogram and stop sampling
	althea.write_to_half_duplex_bus_and_then_verify(j * 2**12, values)
	#time.sleep(0.1)
	values[8] = 0b01 # start sampling histogram
	althea.write_to_half_duplex_bus_and_then_verify(j * 2**12, values)
	time.sleep(1)
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(j * 2**12, 2**4)
	for i in range(16):
		print(hex(readback[i], 8))
	#althea.test_writing_data_to_half_duplex_bus()

if 1:
#	for j in range(4):
#		print()
	j = 1
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(j * 2**12, 2**4)
	for i in range(2**4):
#	for i in range(8):
		print(hex(readback[i], 8))

if 1:
	#althea.write_data_to_pollable_memory_on_half_duplex_bus(0, [ random.randint(0, 2**32-1) for a in range(2**14) ])
	#values = [ random.randint(0, 2**32-1) for a in range(2**14) ]
	#values = [ 0 for a in range(2**14) ]
	values = [ 0 for a in range(2**12) ]
#	for i in range(125):
#		values[i] = 0xffffffff
	values[0]  = 0xc0000000
	values[1]  = 0x00000001
	values[2]  = 0x00000001
	values[3]  = 0x80000000
	values[4]  = 0x00000000
	values[5]  = 0x55555555
	values[6]  = 0x00005555
	values[7]  = 0x55550000
	values[8]  = 0x55005500
	values[9]  = 0x00000000
	values[10] = 0xff000000
	values[11] = 0x000000cc
	values[12] = 0x55000000
	values[13] = 0x000000ff
	values[14] = 0x00000000
	values[15] = 0xfff00000
	values[16] = 0x00000ccc
	values[17] = 0x55500000
	values[18] = 0x00000fff
	values[19] = 0x00000000
	values[20] = 0x01020304
	values[21] = 0x05060708
	values[22] = 0x0a0b0c0d
	values[23] = 0x0e0f0000
	values[24] = 0x00000000
	values[25] = 0x0103070f
	values[26] = 0x00000000
	values[27] = 0x1f3f7fff
	values[28] = 0x00000000
	#althea.write_data_to_pollable_memory_on_half_duplex_bus(0, values)
	althea.write_to_half_duplex_bus_and_then_verify(0, values)

if 0:
	#max_address_plus_one = 2**14
	max_address_plus_one = 8
	values = [ 0 for a in range(max_address_plus_one) ]
	for i in range(max_address_plus_one):
		#values[i] = 0x01234567
		values[i] = 0x076543210
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, values)

if 0:
	althea.test_writing_data_to_half_duplex_bus2()

if 0:
	values = [ 0 for a in range(2**14) ]
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, values)
	for i in range(9):
		time.sleep(0.1)
		althea.write_csv_values_to_pollable_memory_on_half_duplex_bus_and_verify(size, i*RF_buckets, max_count, "bcm.csv", date_string, i)

from function_generator_DAC import *

if 0:
	clear_DAC_waveform()

if 0:
	test_function_generator_DAC_1() # everything

if 0:
	test_function_generator_DAC_2() # single 8ns pulse (1.0V)

if 0:
	test_function_generator_DAC_3() # single 8ns pulse (1.3V) with some ringing

if 0:
	test_function_generator_DAC_4() # 2us baseline (0.7V) with a little blip in the middle that can fire the laser diode

if 0:
	test_function_generator_DAC_5() # 5us of 23.5ns on, 23.5ns off (1.65V)

if 0:
	test_function_generator_DAC_6() # whatever we were working on last

if 0:
	test_function_generator_DAC_7() # high all the time

if 0:
	test_function_generator_DAC_8() # series of 1us things (1.0V)

if 0:
	test_function_generator_DAC_9(10.0e-9) # double 8ns pulse (1.3V) with some ringing; configurable gap between

if 0:
	# continuously increases delay between two pulses until a maximum, then restarts
	clear_DAC_waveform(False)
	tau = 1.0e-9
	while True:
		for i in range(140):
			#time.sleep(0.01)
			test_function_generator_DAC_9((i+1)*tau) # double 8ns pulse (1.3V) with some ringing; configurable gap between
		time.sleep(1.0)

if 0:
	# continuously increases delay before a pulse until a maximum, then restarts
	clear_DAC_waveform(False)
	tau = 1.0e-9
	while True:
		for i in range(140):
			#time.sleep(0.01)
			test_function_generator_DAC_10((i+1)*tau) # single 8ns pulse (1.3V) with some ringing; configurable delay before
		for i in range(139, -1, -1):
			#time.sleep(0.01)
			test_function_generator_DAC_10((i+1)*tau) # single 8ns pulse (1.3V) with some ringing; configurable delay before
		time.sleep(0.1)

if 0:
	# 3 frames of 3 different amplitudes (0*, 1*, 2*) of a bcm waveform
	clear_DAC_waveform()
	offset = 25/64
	amplitude = 18/64
	for i in range(3):
		time.sleep(0.1)
		write_csv_DAC_values_to_pollable_memory_on_half_duplex_bus_and_verify(RF_buckets, i*RF_buckets, scaling, "bcm.csv", date_string, offset, i*amplitude)

if 0:
	# baseline (25/64) plus a frames a bcm waveform
	clear_DAC_waveform()
	offset = 23/64
	amplitude = 40/64
	write_csv_DAC_values_to_pollable_memory_on_half_duplex_bus_and_verify(RF_buckets, 0, scaling, "bcm.csv", date_string, offset, amplitude)

if 0:
	# 3 frames of a bcm waveform (for laser diode mounted in XY flexture mount)
	clear_DAC_waveform()
	offset = 25/64
	amplitude = 2*18/64
	for i in range(3):
		time.sleep(0.1)
		write_csv_DAC_values_to_pollable_memory_on_half_duplex_bus_and_verify(RF_buckets, i*RF_buckets, scaling, "bcm.csv", date_string, offset, amplitude)

if 0:
	# 3 frames of a bcm waveform (for laser diode mounted above the sensor)
	clear_DAC_waveform()
	#offset = 1.3/1.65
	offset = 0.625/1.65
	#amplitude = 0.35
	amplitude = 90.00/1.65
	for i in range(3):
		#time.sleep(0.1)
		write_csv_DAC_values_to_pollable_memory_on_half_duplex_bus_and_verify(RF_buckets, i*RF_buckets, scaling, "bcm.csv", date_string, offset, amplitude)

if 0:
	#print("asdf")
	althea.test()
	#print("fdsa")

if 0:
	althea.set_all_gpio_as_inputs()

#if 0:
#	althea.select_clock_and_reset_althea(0)
#else:
#	althea.select_clock_and_reset_althea(1)

if 0:
	#althea.test_speed_of_setting_gpios_individually()
	#althea.test_speed_of_setting_gpios_grouped()
	#althea.test_speed_of_setting_gpios_with_fastgpio_full_bus_width()
	althea.test_speed_of_setting_gpios_with_fastgpio_half_bus_width()
	#althea.test_speed_of_setting_gpios_with_fastgpio_half_duplex(4)  #  6.844 MB per second
	althea.test_speed_of_setting_gpios_with_fastgpio_half_duplex(8)   # 14.374 MB per second
	#althea.test_speed_of_setting_gpios_with_fastgpio_half_duplex(12) # 16.161 MB per second
	althea.test_speed_of_setting_gpios_with_fastgpio_half_duplex(16)  # 17.120 MB per second
	#althea.test_speed_of_setting_gpios_with_fastgpio_half_duplex(20) # 21.321 MB per second
	althea.set_all_gpio_as_inputs()
	#sys.exit(0)

if 0:
	althea.test_different_drive_strengths()
	althea.set_all_gpio_as_inputs()

if 0:
	spi_ce0 = althea.spi(0, 16) # 16 (32bit) words to control sequencer
	spi_ce1 = althea.spi_sequencer(1, 4096) # 4096 (32bit) words of sequencer memory

if 0:
	set_ring_oscillator_values(spi_ce0, 10, 5, 12)
	time.sleep(1.0)
	show_frequency_counter_value(spi_ce0)
	#sys.exit(0)

if 0:
	#spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ 11*RF_buckets, 12*RF_buckets ]) # show unused part of memory while we're writing into it
	#spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ 0, 16 ]) # show entire memory while we're writing into it
	#spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ 0, 12.7*RF_buckets ]) # show entire memory while we're writing into it
	#spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ 0, 9.0*RF_buckets ]) # show 9 revolutions while we're writing into it
	spi_ce1.write_zero_values_to_spi_pollable_memory_and_verify(2**12) # clear memory
	#spi_ce1.write_sequential_values_to_spi_pollable_memory_and_verify(2**12)
	#spi_ce1.write_pseudorandom_values_to_spi_pollable_memory_and_verify(2**12)
	# write pulses of increasing width to sequential parts of memory:
	#size = 2**12
	for i in range(9):
		spi_ce1.write_csv_values_to_spi_pollable_memory_and_verify(size, i*RF_buckets, max_count, "bcm.csv", date_string, i)
		time.sleep(0.1)
	spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ 0, 9.0*RF_buckets ]) # show 9 revolutions worth of the sequencer memory

if 0:
	cycle(9, RF_buckets)

