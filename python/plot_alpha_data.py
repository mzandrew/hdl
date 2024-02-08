#!/usr/bin/env python3

# written 2024-02-07 by mza and makiko
# with help from https://docs.python.org/3/library/csv.html
# last updated 2024-02-07 by mza and makiko

# tried this to get data directly from usb connection to oscilloscope...
# https://github.com/asvela/keyoscacquire
# https://keyoscacquire.readthedocs.io/en/latest/contents/overview.html#installation
# https://keyoscacquire.readthedocs.io/en/latest/contents/oscilloscope.html#osc-class
# pip install keyoscacquire
#import pyvisa as visa
#import keyoscacquire as koa
#scope = koa.Oscilloscope(address='USB0::1234::1234::MY53280216::INSTR') # MSO-X 2024A
# fails with ValueError: Could not locate a VISA implementation. Install either the IVI binary or pyvisa-py.
# tried pip installing ivi but that fails with ERROR: Command errored out with exit status 1
# so we rely on a usb stick and saving the D0-D7 data as "ASCII XY" with length=62500

NUMBER_OF_CHANNELS = 16
MAX_NUMBER_OF_SAMPLES_PER_WAVEFORM = 256
EXPECTED_DECIMATION_FACTOR = 3
NUMBER_OF_LINES_TO_PRINT = (NUMBER_OF_CHANNELS+9)*4*EXPECTED_DECIMATION_FACTOR

import sys
import os
import csv
import matplotlib.pyplot as plt

csv_filename = None
if len(sys.argv)>1:
	for arg in sys.argv[1:]:
		#print(arg)
		if os.path.exists(arg):
			csv_filename = arg

if csv_filename is None:
	print("usage: ")
	print(sys.argv[0] + " filename.csv")
	sys.exit(1)
else:
	print("using " + csv_filename)

row_number = 0
rows = []
with open(csv_filename) as csv_file:
	csv_reader = csv.reader(csv_file, delimiter=",")
	for row in csv_reader:
		#print(', '.join(row))
		if row_number>2:
			time = float(row[0])
			digital_bus_value = int(row[1])
			nybble = digital_bus_value & 0x0f
			most_significant_nybble = (digital_bus_value & 0x10) >> 4
			header_found = (digital_bus_value & 0x40) >> 6
			rows.append([time, header_found, most_significant_nybble, nybble])
		row_number += 1

print("found " + str(len(rows)) + " rows")

header_found_yet = False
number_of_lines_printed_so_far = 0
data_series = [ [] for i in range(NUMBER_OF_CHANNELS) ]
previous_most_significant_nybble = 0
print("time(us), header_found, most_significant_nybble, nybble")
we_are_on_actual_data_now = False
most_significant_nybble_counter = 0
channel_number = 0
value = 0
number_of_datapoints_gathered_for_channel_zero = 0
we_have_seen_omega_already = False

for row in rows:
	time = row[0]
	header_found = row[1]
	most_significant_nybble = row[2]
	nybble = row[3]
	if not header_found_yet:
		if header_found: # header_found
			header_found_yet = True
			decimation_counter = 0
			previous_most_significant_nybble = most_significant_nybble
			we_are_on_actual_data_now = False
			most_significant_nybble_counter = 0
			nybble_counter = 0
			should_append_some_new_data = False
	else:
		string = ""
		if most_significant_nybble and most_significant_nybble is not previous_most_significant_nybble: # resynchronization
			if we_are_on_actual_data_now and 3<=nybble_counter:
				should_append_some_new_data = True
				value_to_append = value
				if number_of_lines_printed_so_far<NUMBER_OF_LINES_TO_PRINT:
					print(str(value))
			decimation_counter = 0
			nybble_counter = 0
			value = 0
			if number_of_lines_printed_so_far<NUMBER_OF_LINES_TO_PRINT:
				print()
			most_significant_nybble_counter += 1
			if 7<most_significant_nybble_counter and not we_have_seen_omega_already:
				we_are_on_actual_data_now = True
		if decimation_counter==1:
			string = "*"
			if most_significant_nybble:
				channel_number = nybble
			if we_are_on_actual_data_now:
				if 0<nybble_counter:
					value |= nybble * 2**(4*(3-nybble_counter))
				string += "*"
			nybble_counter += 1
		if number_of_lines_printed_so_far<NUMBER_OF_LINES_TO_PRINT:
			print(str(int(1e9*time)/1000) + ", " + str(row[1]) + ", " + str(row[2]) + ", " + str(row[3]) + " " + string)
			number_of_lines_printed_so_far += 1
		if number_of_datapoints_gathered_for_channel_zero>=MAX_NUMBER_OF_SAMPLES_PER_WAVEFORM-1:
			if not we_have_seen_omega_already:
				print(str(int(1e9*time)/1000) + ", " + str(row[1]) + ", " + str(row[2]) + ", " + str(row[3]) + " " + string)
		if decimation_counter<EXPECTED_DECIMATION_FACTOR-1:
			decimation_counter += 1
		else:
			decimation_counter = 0
		previous_most_significant_nybble = most_significant_nybble
		if should_append_some_new_data:
			should_append_some_new_data = False
			if number_of_datapoints_gathered_for_channel_zero>=MAX_NUMBER_OF_SAMPLES_PER_WAVEFORM:
				if 0xfff==value_to_append or 0xe6a==value_to_append:
					we_are_on_actual_data_now = False
					we_have_seen_omega_already = True
			if not we_have_seen_omega_already:
				data_series[channel_number].append(value_to_append)
			if 0==channel_number:
				number_of_datapoints_gathered_for_channel_zero += 1

total = 0
for channel in range(NUMBER_OF_CHANNELS):
	num = len(data_series[channel])
	print(str(num) + " for channel " + str(channel))
	total += num
print("found " + str(total) + " values overall")

for channel in range(NUMBER_OF_CHANNELS):
	print("channel" + str(channel) + ": ", end="")
	for data_point in data_series[channel]:
		print(data_point, end=",")
	print()

SST_FREQUENCY_HZ = 100e6
#SST_FREQUENCY = 250e6
import numpy as np
t = np.arange(0.0, MAX_NUMBER_OF_SAMPLES_PER_WAVEFORM/SST_FREQUENCY_HZ, 1/SST_FREQUENCY_HZ)
s = np.array(data_series[0], dtype='float32')
fig, ax = plt.subplots()
ax.plot(t, s)
ax.set(xlabel='time (s)', ylabel='ADC value', title='')
ax.grid()
plt.show()

