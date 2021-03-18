# written 2021-03-17 by mza
# last updated 2021-03-18 by mza

import althea
import math
import sys
pi = 4.0*math.atan(45.0)
sampling_frequency = 1.0e9
DAC_bits = 6
DAC_MAX = 2**DAC_bits
default_offset = 0.5
default_amplitude = 0.5
default_duty_cycle = 50.0
default_pulse_duration = 1.0e-9

def prepare_waveform_for_upload_to_DAC(values):
	extra = len(values) % 8
	if not 0==extra:
		for i in range(extra):
			values.pop()
		#print("must be multiple of 8")
		#sys.exit(1)
	#print("len(values) = " + str(len(values)))
	for i in range(len(values)):
		if values[i]>=DAC_MAX:
			values[i] = DAC_MAX - 1
		elif values[i]<0.0:
			values[i] = 0.0
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
	d = pi/number_of_samples
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
	number_of_samples_for_pulse = 1.0e-9 / pulse_duration
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
	#print(str(number_of_samples_for_rising))
	number_of_samples_for_falling = falltime * sampling_frequency
	number_of_samples_for_falling = int(number_of_samples_for_falling)
	#print(str(number_of_samples_for_falling))
	amplitude *= DAC_MAX
	offset *= DAC_MAX
	values = [ 0 for i in range(number_of_samples) ]
	a = (amplitude-offset) / math.sqrt(number_of_samples_for_rising)
	tau = number_of_samples_for_falling / math.exp(1.0)
	#print(str(tau))
	peak = offset
	for i in range(number_of_samples_for_rising):
		values[i] = int(offset + a * math.sqrt(i))
		peak = values[i]
	for i in range(number_of_samples_for_rising, number_of_samples_for_rising+number_of_samples_for_falling):
		j = i - number_of_samples_for_rising
		values[i] = int(offset + (peak-offset)*math.exp(-j/tau))
		#print("[" + str(i) + "] " + str(values[i]))
	for i in range(number_of_samples_for_rising+number_of_samples_for_falling, number_of_samples):
		values[i] = int(offset)
	#print(str(values))
	return prepare_waveform_for_upload_to_DAC(values)

def clear_DAC_waveform():
	values = [ 0 for a in range(2**14) ]
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, prepare_waveform_for_upload_to_DAC(values))

def test_function_generator_DAC():
	clear_DAC_waveform()
	everything = []
	f = 1.0e6
	waveform = prepare_sine_waveform_for_upload_to_DAC(f, 0.5, 0.5)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_pulse_waveform_for_upload_to_DAC(f, 0.375, 0.125, 1.0e-9)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_sawtooth_waveform_for_upload_to_DAC(f, 0.4375, 0.5625, 25.0)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_DC_waveform_for_upload_to_DAC(f, 0.4)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_square_waveform_for_upload_to_DAC(f, 0.3125, 0.125, 42.0)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_sine_waveform_for_upload_to_DAC(f, 0.25, 0.5)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	waveform = prepare_RAMP_waveform_for_upload_to_DAC(f, 0.25, 0.75)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	#waveform = prepare_PMT_waveform_for_upload_to_DAC(f, 3.8e-9, 10e-9, 0.9, 0.1)
	waveform = prepare_PMT_waveform_for_upload_to_DAC(f, 30.0e-9, 80.0e-9, 0.9, 0.1)
	everything.extend(waveform)
	everything.extend(waveform)
	everything.extend(waveform)
	#print("len(everything) = " + str(len(everything)))
	althea.write_data_to_pollable_memory_on_half_duplex_bus(0, everything)

