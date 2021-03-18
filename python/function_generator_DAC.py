# written 2021-03-17 by mza
# last updated 2021-03-17 by mza

import althea
import math
import sys
pi = 4.0*math.atan(45.0)
sampling_frequency = 1.0e9
DAC_bits = 5
DAC_MAX = 2**DAC_bits
default_offset = DAC_MAX / 2.0
default_amplitude = DAC_MAX / 2.0
default_duty_cycle = 50.0
default_pulse_duration = 1.0e-9

def prepare_waveform_for_upload_to_DAC(values):
	if not 0==len(values)%8:
		print("must be multiple of 8")
		sys.exit(1)
	#print("len(values) = " + str(len(values)))
	waveform = []
	for i in range(len(values)):
		if 0==i%8:
			word64 = 0
		partial = (values[i]%DAC_MAX)<<(8-DAC_bits+8*(i%8))
		#print(hex(partial, 16))
		word64 |= partial
		if 7==i%8:
			#print(" " + hex(word64, 16))
			waveform.append(word64>>32)
			waveform.append(word64&0xffffffff)
	#print("len(waveform) = " + str(len(waveform)))
	return waveform

def prepare_sine_waveform_for_upload_to_DAC(frequency, amplitude=default_amplitude, offset=default_offset):
	number_of_samples = sampling_frequency / frequency
	#print(str(number_of_samples))
	number_of_samples = int(number_of_samples)
	d = pi/number_of_samples
	values = [ 0 for a in range(number_of_samples) ]
	#values = [ 0 for a in range(2**14) ]
	for i in range(number_of_samples):
		values[i] = int(offset+amplitude*math.sin(d*i))
	return prepare_waveform_for_upload_to_DAC(values)

def prepare_square_waveform_for_upload_to_DAC(frequency, amplitude=default_amplitude, offset=default_offset, duty_cycle=default_duty_cycle):
	number_of_samples = sampling_frequency / frequency
	#print(str(number_of_samples))
	number_of_samples = int(number_of_samples)
	number_of_samples_on = duty_cycle * number_of_samples / 100.0
	number_of_samples_on = int(number_of_samples_on)
	values = [ int(offset) for a in range(number_of_samples) ]
	for i in range(number_of_samples_on):
		values[i] = int(offset+amplitude)
	return prepare_waveform_for_upload_to_DAC(values)

def prepare_pulse_waveform_for_upload_to_DAC(frequency, amplitude=default_amplitude, offset=default_offset, pulse_duration=default_pulse_duration):
	number_of_samples = sampling_frequency / frequency
	number_of_samples = int(number_of_samples)
	#print(str(number_of_samples))
	number_of_samples_for_pulse = 1.0e-9 / pulse_duration
	number_of_samples_for_pulse = int(number_of_samples_for_pulse)
	#print(str(number_of_samples_for_pulse))
	values = [ int(offset) for a in range(number_of_samples) ]
	for i in range(number_of_samples_for_pulse):
		values[i] = int(offset+amplitude)
	return prepare_waveform_for_upload_to_DAC(values)

def prepare_sawtooth_waveform_for_upload_to_DAC(frequency, amplitude=default_amplitude, offset=default_offset, duty_cycle=default_duty_cycle):
	a = duty_cycle / 100.0
	b = 1.0 - a
	number_of_samples = sampling_frequency / frequency
	number_of_samples_for_rising = number_of_samples * a
	number_of_samples = int(number_of_samples)
	#print(str(number_of_samples))
	number_of_samples_for_rising = int(number_of_samples_for_rising)
	#print(str(number_of_samples_for_rising))
	number_of_samples_for_falling = number_of_samples - number_of_samples_for_rising
	#print(str(number_of_samples_for_falling))
	values = [ 0 for a in range(number_of_samples) ]
	peak = offset
	if number_of_samples_for_rising:
		for i in range(number_of_samples_for_rising):
			values[i] = int(offset+amplitude*i/number_of_samples_for_rising)
			peak = values[i]
			#print(str(values[i]))
	if number_of_samples_for_falling:
		for i in range(number_of_samples_for_rising, number_of_samples):
			values[i] = int(peak-amplitude*(i-number_of_samples_for_rising)/number_of_samples_for_falling)
	return prepare_waveform_for_upload_to_DAC(values)

def test_function_generator_DAC():
	everything = []
	waveform = prepare_sine_waveform_for_upload_to_DAC(1.0e6, 16.0, 16.0)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_pulse_waveform_for_upload_to_DAC(1.0e6, 12.0, 4.0, 1.0e-9)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(1.0e6, 14.0, 18.0, 25.0)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_square_waveform_for_upload_to_DAC(1.0e6, 10.0, 4.0, 42.0)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_sine_waveform_for_upload_to_DAC(1.0e6, 8.0, 16.0)
	everything.extend(waveform)
	everything.extend(waveform)
	#print("len(everything) = " + str(len(everything)))
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

