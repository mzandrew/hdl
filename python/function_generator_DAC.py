# written 2021-03-17 by mza
# last updated 2021-04-18 by mza

import althea
import math
import sys
import os
import re
pi = 4.0*math.atan(1.0)
#print(str(pi))
sampling_frequency = 1.0e9
DAC_bits = 6
DAC_MAX = 2**DAC_bits
default_offset = 0.5
default_amplitude = 0.5
default_duty_cycle = 50.0
default_pulse_duration = 1.0e-9

def prepare_waveform_for_upload_to_DAC(values):
	if None==values:
		print("empty array")
		sys.exit(2)
	extra = len(values) % 8
	if not 0==extra:
		for i in range(extra):
			values.pop()
		#print("must be multiple of 8")
		#sys.exit(1)
	#print("len(values) = " + str(len(values)))
	for i in range(len(values)):
		if values[i]>=DAC_MAX:
			values[i] = DAC_MAX-1
		elif values[i]<0:
			values[i] = 0
	waveform = []
	for i in range(len(values)):
		if 0==i%8:
			word64 = 0
		partial = values[i]<<(8-DAC_bits+8*(7-i%8))
		#print(hex(partial, 16))
		word64 |= partial
		if 7==i%8:
			#print(" " + hex(word64, 16))
			waveform.append(word64&0xffffffff)
			waveform.append(word64>>32)
	#print("len(waveform) = " + str(len(waveform)))
	return waveform

def prepare_sine_waveform_for_upload_to_DAC(desired_frequency, amplitude=default_amplitude, offset=default_offset):
	number_of_samples = sampling_frequency / desired_frequency
	#print(str(number_of_samples))
	number_of_samples = int(number_of_samples)
	d = 2.0 * pi / number_of_samples
	values = [ 0 for a in range(number_of_samples) ]
	#values = [ 0 for a in range(2**14) ]
	amplitude *= DAC_MAX
	offset *= DAC_MAX
	for i in range(number_of_samples):
		values[i] = int(offset+amplitude*math.sin(d*i))
	return prepare_waveform_for_upload_to_DAC(values)

def prepare_square_waveform_for_upload_to_DAC(desired_frequency, amplitude=default_amplitude, offset=default_offset, duty_cycle=default_duty_cycle):
	number_of_samples = sampling_frequency / desired_frequency
	#print(str(number_of_samples))
	number_of_samples = int(number_of_samples)
	number_of_samples_on = duty_cycle * number_of_samples / 100.0
	number_of_samples_on = int(number_of_samples_on)
	amplitude *= DAC_MAX
	offset *= DAC_MAX
	values = [ int(offset) for a in range(number_of_samples) ]
	for i in range(number_of_samples_on):
		values[i] = int(offset+amplitude)
	return prepare_waveform_for_upload_to_DAC(values)

def prepare_pulse_waveform_for_upload_to_DAC(desired_frequency, amplitude=default_amplitude, offset=default_offset, pulse_duration=default_pulse_duration):
	number_of_samples = sampling_frequency / desired_frequency
	number_of_samples = int(number_of_samples)
	#print(str(number_of_samples))
	number_of_samples_for_pulse = pulse_duration * sampling_frequency
	number_of_samples_for_pulse = int(number_of_samples_for_pulse)
	#print(str(number_of_samples_for_pulse))
	amplitude *= DAC_MAX
	offset *= DAC_MAX
	values = [ int(offset) for a in range(number_of_samples) ]
	for i in range(number_of_samples_for_pulse):
		values[i] = int(offset+amplitude)
	return prepare_waveform_for_upload_to_DAC(values)

def prepare_RAMP_waveform_for_upload_to_DAC(desired_frequency, start=default_offset, end=default_offset):
	number_of_samples = sampling_frequency / desired_frequency
	number_of_samples = int(number_of_samples)
	#print(str(number_of_samples))
	values = [ 0 for a in range(number_of_samples) ]
	amplitude = end - start
	amplitude *= DAC_MAX
	offset = start
	offset *= DAC_MAX
	for i in range(number_of_samples):
		values[i] = int(offset+amplitude*i/number_of_samples)
	return prepare_waveform_for_upload_to_DAC(values)

def prepare_DC_waveform_for_upload_to_DAC(desired_frequency, offset=default_offset):
	return prepare_RAMP_waveform_for_upload_to_DAC(desired_frequency, offset, offset)

def prepare_sawtooth_waveform_for_upload_to_DAC(desired_frequency, amplitude=default_amplitude, offset=default_offset, duty_cycle=default_duty_cycle):
	a = duty_cycle / 100.0
	b = 1.0 - a
	number_of_samples = sampling_frequency / desired_frequency
	number_of_samples_for_rising = number_of_samples * a
	number_of_samples = int(number_of_samples)
	#print(str(number_of_samples))
	number_of_samples_for_rising = int(number_of_samples_for_rising)
	#print(str(number_of_samples_for_rising))
	number_of_samples_for_falling = number_of_samples - number_of_samples_for_rising
	#print(str(number_of_samples_for_falling))
	values = [ 0 for a in range(number_of_samples) ]
	peak = offset
	amplitude *= DAC_MAX
	offset *= DAC_MAX
	if number_of_samples_for_rising:
		for i in range(number_of_samples_for_rising):
			values[i] = int(offset+amplitude*i/number_of_samples_for_rising)
			peak = values[i]
			#print(str(values[i]))
	if number_of_samples_for_falling:
		for i in range(number_of_samples_for_rising, number_of_samples):
			values[i] = int(peak-amplitude*(i-number_of_samples_for_rising)/number_of_samples_for_falling)
	return prepare_waveform_for_upload_to_DAC(values)

def prepare_PMT_waveform_for_upload_to_DAC(desired_frequency, risetime, falltime, amplitude=default_amplitude, offset=default_offset):
	number_of_samples = sampling_frequency / desired_frequency
	number_of_samples = int(number_of_samples)
	#print(str(number_of_samples))
	number_of_samples_for_rising = risetime * sampling_frequency
	number_of_samples_for_rising = int(number_of_samples_for_rising)
	#print("number_of_samples_for_rising: " + str(number_of_samples_for_rising))
	number_of_samples_for_falling = falltime * sampling_frequency
	number_of_samples_for_falling = int(number_of_samples_for_falling)
	#print(str(number_of_samples_for_falling))
	amplitude *= DAC_MAX
	offset *= DAC_MAX
	values = [ 0 for i in range(number_of_samples) ]
	peak = offset
	if number_of_samples_for_rising:
		a = (amplitude-offset) / math.sqrt(number_of_samples_for_rising)
		for i in range(number_of_samples_for_rising):
			values[i] = int(offset + a * math.sqrt(i+1))
			peak = values[i]
	tau = number_of_samples_for_falling / math.exp(1.0)
	#print(str(tau))
	for i in range(number_of_samples_for_rising, number_of_samples_for_rising+number_of_samples_for_falling):
		j = i - number_of_samples_for_rising
		values[i] = int(offset + (peak-offset)*math.exp(-j/tau))
		#print("[" + str(i) + "] " + str(values[i]))
	for i in range(number_of_samples_for_rising+number_of_samples_for_falling, number_of_samples):
		values[i] = int(offset)
	#print(str(values))
	return prepare_waveform_for_upload_to_DAC(values)

def read_csv_file(input_filename, amplitude=default_amplitude, offset=default_offset):
	values = []
	if os.path.isfile(input_filename):
		input_file = open(input_filename)
		lines = input_file.readlines()
		for line in lines:
			match = re.search("^([0-9]+),([.\-E0-9]+),([.\-E0-9]+)", line)
			if match:
				instance = match.group(1)
				valuestring = match.group(2)
				timestring = match.group(3)
				#print(instance + " " + valuestring + " " + timestring)
				values.append(float(valuestring))
	min_value = 1.0
	max_value = -1.0
	if len(values)==0:
		print("no data found in file")
		return
	for i in range(len(values)):
		min_value = min(min_value, values[i])
		max_value = max(max_value, values[i])
	#print("min_value: " + str(min_value))
	#print("max_value: " + str(max_value))
	diff = max_value - min_value
	epsilon = 1.0e-7
	if diff<epsilon:
#		warning("no data found in file")
		return
	#print("diff: " + str(diff))
	amplitude *= DAC_MAX
	offset *= DAC_MAX
	normalization = - 1.0 / diff
	#print("normalization: " + str(normalization))
	for i in range(len(values)):
		values[i] = values[i] - min_value
	#print(str(values))
	for i in range(len(values)):
		values[i] = 1.0 + values[i] * normalization
	#print(str(values))
	for i in range(len(values)):
		values[i] = int(offset + amplitude * values[i])
	#print(str(values))
	return values

def read_file_PMT_waveform_for_upload_to_DAC(desired_frequency, amplitude=default_amplitude, offset=default_offset):
	number_of_samples = sampling_frequency / desired_frequency
	number_of_samples = int(number_of_samples)
	values = read_csv_file("../contrib/pulse.csv", amplitude, offset)
	offset *= DAC_MAX
	for i in range(len(values), number_of_samples):
		values.append(int(offset))
	#print(len(values))
	#print(str(values))
	return prepare_waveform_for_upload_to_DAC(values)

def clear_DAC_waveform(should_print=True):
	values = [ 0 for a in range(2**15) ]
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, prepare_waveform_for_upload_to_DAC(values), should_print)

def fill_up_the_rest_with(everything, waveform):
	#big_waveform = []
	chunks = int(2.0*(2**13 - len(everything)) / (sampling_frequency / len(waveform)))
	print(str(chunks))
	for i in range(chunks):
		everything.extend(waveform)
	return everything

def generate_DAC_waveform_from_csv_values(length, scaling, input_filename, date_string, offset, amplitude):
	# scaling is the number of samples per RF_bucket (usually 2)
	length = int(length)
	data_list = [ 0 for d in range(scaling*length) ]
	csv_list = althea.read_csv(input_filename, date_string, length) # the bcm files are fixed format, having 5120 values on each line
	csv_list = althea.normalize_csv_data(csv_list, DAC_MAX)
	# csv_list has an integer entry for each RF_bucket as a time series
	offset *= DAC_MAX
	for i in range(len(data_list)):
		data_list[i] = int(offset + amplitude * csv_list[i])
	#print(str(data_list))
	return prepare_waveform_for_upload_to_DAC(data_list)

def write_csv_DAC_values_to_pollable_memory_on_half_duplex_bus_and_verify(length, offset, scaling, input_filename, date_string, DAC_offset, DAC_amplitude):
	waveform = generate_DAC_waveform_from_csv_values(length, scaling, input_filename, date_string, DAC_offset, DAC_amplitude)
	offset = offset//2
	althea.write_data_to_pollable_memory_on_half_duplex_bus(offset, waveform)

def test_function_generator_DAC_1():
	clear_DAC_waveform()
	#sys.exit(0)
	everything = []
	f = 1.0e6
	waveform = prepare_sine_waveform_for_upload_to_DAC(f, 0.5, 0.5)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_pulse_waveform_for_upload_to_DAC(f, 0.875, 0.125, 1.0e-9)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, 0.4375, 0.5625, 25.0)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.4)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_square_waveform_for_upload_to_DAC(f, 0.3125, 0.125, 42.0)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_sine_waveform_for_upload_to_DAC(f, 0.25, 0.5)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = read_file_PMT_waveform_for_upload_to_DAC(f, 0.9, 0.1)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(f, 0.25, 0.75)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(f, 0.0, 1.00)
	everything.extend(waveform)
	everything.extend(waveform)
	#waveform = prepare_PMT_waveform_for_upload_to_DAC(f, 3.8e-9, 10e-9, 0.9, 0.1)
	waveform = prepare_PMT_waveform_for_upload_to_DAC(f, 30.0e-9, 80.0e-9, 0.9, 0.1)
	everything.extend(waveform)
	everything.extend(waveform)
	#print("len(everything) = " + str(len(everything)))
	#waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.6)
	#everything = fill_up_the_rest_with(everything, waveform)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

def test_function_generator_DAC_2():
	clear_DAC_waveform()
	everything = []
	f = 1.0e8
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, 1.00, 0.0, 35.0)
	everything.extend(waveform)
	everything = fill_up_the_rest_with(everything, prepare_DC_waveform_for_upload_to_DAC(f, 0.0))
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

def test_function_generator_DAC_3():
	clear_DAC_waveform()
	everything = []
	f = 1.0e6
	waveform = prepare_PMT_waveform_for_upload_to_DAC(f, 1.0e-9, 2.0e-9, 1.0, 0.0)
	everything.extend(waveform)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

def test_function_generator_DAC_4():
	#clear_DAC_waveform()
	everything = []
	f = 1.0e6
	#offset = 0.435 # 0.44 causes it to lase constantly
	offset = 27/64 # 28/64 causes it to lase constantly
	#amplitude = 1.0 - offset
	amplitude = 6/64 # can see a definite pulse at the end of a fiber at 2/64, but 1/64 looks like nothing; 6/64 has a S:N of 1:1
	duration = 1.0e-9
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, offset)
	everything.extend(waveform)
	waveform = prepare_pulse_waveform_for_upload_to_DAC(f, amplitude, offset, duration)
	everything.extend(waveform)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

def test_function_generator_DAC_5():
	clear_DAC_waveform()
	#sys.exit(0)
	everything = []
	f = 42.5e6
	samples = sampling_frequency / f
	N = 5*int(2.0**12 / samples)
	offset = 0.625/1.65
	amplitude = 1.0 - offset
	waveform1 = prepare_sawtooth_waveform_for_upload_to_DAC(f, offset, amplitude, 25.0)
	waveform2 = prepare_DC_waveform_for_upload_to_DAC(f, offset)
	for i in range(N):
		everything.extend(waveform1)
		everything.extend(waveform2)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

def test_function_generator_DAC_6():
	clear_DAC_waveform()
	everything = []
	f = 100.0e6
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.125)
	everything.extend(waveform)
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, 0.125, 0.875, 25.0)
#	waveform = prepare_pulse_waveform_for_upload_to_DAC(f, 0.875, 0.125, 1.0e-9)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.125)
	everything.extend(waveform)
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, 0.125, 0.875, 25.0)
	everything.extend(waveform)
	#waveform = prepare_pulse_waveform_for_upload_to_DAC(f, 0.875, 0.125, 1.0e-9)
	#everything.extend(waveform)
	#waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.125)
	#everything.extend(waveform)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

def test_function_generator_DAC_7():
	clear_DAC_waveform()
	everything = []
	f = 1.0e6
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 1.0)
	for i in range(31):
		everything.extend(waveform)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

def test_function_generator_DAC_8():
	clear_DAC_waveform()
	everything = []
	f = 1.0e6
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, 1.0, 0.0, 35.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, 1.0, 0.0, 1.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_pulse_waveform_for_upload_to_DAC(f, 1.0, 0.0, 1.0e-6)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(f, 0.0, 1.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(f, 1.0, 0.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, 1.0, 0.0, 35.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, 1.0, 0.0, 1.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_pulse_waveform_for_upload_to_DAC(f, 1.0, 0.0, 1.0e-6)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(f, 0.0, 1.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(f, 1.0, 0.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(f, 1.0, 0.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_pulse_waveform_for_upload_to_DAC(f, 1.0, 0.0, 1.0e-6)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(f, 1.0, 0.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_pulse_waveform_for_upload_to_DAC(f, 1.0, 0.0, 1.0e-6)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	waveform = prepare_pulse_waveform_for_upload_to_DAC(f, 1.0, 0.0, 1.0e-6)
	everything.extend(waveform)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

def test_function_generator_DAC_9(delay=1.0e-6):
	#clear_DAC_waveform(False)
	everything = []
	rising_edge = 1.0e-9
	falling_edge = 2.0e-9
	pulse_duration = rising_edge + falling_edge
	f = 1.0/(delay+pulse_duration)
	#print(str(f))
	waveform = prepare_PMT_waveform_for_upload_to_DAC(f, rising_edge, falling_edge, 1.0, 0.0)
	everything.extend(waveform)
	waveform = prepare_PMT_waveform_for_upload_to_DAC(f, rising_edge, falling_edge, 1.0, 0.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.0)
	everything.extend(waveform)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything, False)

def test_function_generator_DAC_10(delay=1.0e-6):
	#clear_DAC_waveform(False)
	everything = []
	rising_edge = 1.0e-9
	falling_edge = 2.0e-9
	pulse_duration = rising_edge + falling_edge + 5.0e-9
	f1 = 1.0/(pulse_duration)
	f2 = 1.0/(delay)
	#print(str(f1))
	#print(str(f2))
	waveform = prepare_DC_waveform_for_upload_to_DAC(f2, 0.0)
	everything.extend(waveform)
	waveform = prepare_PMT_waveform_for_upload_to_DAC(f1, rising_edge, falling_edge, 1.0, 0.0)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f2/2.0, 0.0)
	everything.extend(waveform)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything, False)

def test_function_generator_DAC_11():
	#clear_DAC_waveform(False)
	everything = []
	DC_level = 0.5
	peak_level = 1.0
	delay = 1.0e-6
	ramp_rise_time = 1.0e-6
#	waveform = prepare_DC_waveform_for_upload_to_DAC(1.0/delay, DC_level)
#	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(1.0/ramp_rise_time, DC_level, peak_level)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(1.0/delay, DC_level)
	everything.extend(waveform)
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything, False)

def test_function_generator_DAC_12():
	#clear_DAC_waveform()
	everything = []
	f = 7.5e6
	DC_level = 0.5
	peak_level = 1.0
	delay = 1.0e-7
	waveform = prepare_DC_waveform_for_upload_to_DAC(1.0/delay, DC_level)
	everything.extend(waveform)
	#waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, peak_level, DC_level, 35.0)
	waveform = prepare_DC_waveform_for_upload_to_DAC(1.0/delay, peak_level)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(1.0/delay, DC_level)
	everything.extend(waveform)
	#everything = fill_up_the_rest_with(everything, prepare_DC_waveform_for_upload_to_DAC(f, 0.0))
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

