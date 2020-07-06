#!/usr/bin/env python3

# written 2020-06-20 by mza
# based on mza-test042.spi-pollable-memories-and-oserdes-function-generator.althea.py
# last updated 2020-07-06 by mza

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
	althea.setup_half_duplex_bus()
	althea.write_data_from_pollable_memory_on_half_duplex_bus(0, [ random.randint(0, 2**32-1) for a in range(2**14) ])
	althea.read_data_from_pollable_memory_on_half_duplex_bus(0, 2**14)
	althea.test_writing_data_to_half_duplex_bus()

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

