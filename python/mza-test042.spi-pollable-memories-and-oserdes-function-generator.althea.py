#!/usr/bin/env python

# written 2020-05-11 by mza
# based on mza-test041.spi-pollable-memory.althea.py
# last updated 2020-05-23 by mza

import time # time.sleep
from generic import * # hex, eng
import althea

RF_buckets = 5120
scaling = 2
max_count = scaling*RF_buckets
date_string = "2019-11-15.075530"
size = RF_buckets/16

althea.reset()
spi_ce0 = althea.spi(0, 16)
spi_ce1 = althea.spi_sequencer(1, 4096)

spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ 11*RF_buckets, 12*RF_buckets ]) # show unused part of memory while we're writing into it
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

def cycle(number_of_segments, segment_size):
	print "cycling..."
	i = 0
	while True:
		j = i % number_of_segments
		k = (i + 1) % number_of_segments
		if 0==k:
			k = number_of_segments
		#print str(j) + " " + str(k)
		spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ j*segment_size,k*segment_size])
		i += 1
		time.sleep(0.1)

cycle(9, RF_buckets)

#spi_ce0.write_values_to_spi_pollable_memory_and_verify(2, [ 2, 0 ], 2) # test idelay inc/dec functionality

