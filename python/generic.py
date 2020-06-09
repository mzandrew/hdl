# written 2020-05-23 by mza
# based on ./mza-test042.spi-pollable-memories-and-oserdes-function-generator.althea.py
# last updated 2020-06-09 by mza

import math # floor, ceil, log10

epsilon = 1.0e-6

def hex(number, width=1):
	return "%0*x" % (width, number)

def dec(number, width=1):
	return "%0*d" % (width, number)

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

def bit(word, bitnumber):
	return (word >> bitnumber) & 1

def buildmask(gpios):
	mask = 0
	for i in gpios:
		if i:
			mask |= 1<<i
	#print(hex(mask))
	return mask

# modified from run_length_encode_gap() in suh svn repo / xrm.py
def run_lenth_encode_monotonicity(numbers):
	rle = []
	current_value = -1
	old_value = -1
	old_value_index = -1
	current_count = 0
	if len(numbers):
		for i in range(len(numbers)):
			current_value = numbers[i]
			if 0==i:
				old_value = current_value
				old_value_index = i
			if current_value==old_value+(i-old_value_index):
				current_count += 1
			else:
				rle.append([old_value, current_count])
				old_value = current_value
				old_value_index = i
				current_count = 1
		rle.append([old_value, current_count])
	string = dec(0, 5) + ": "
	count = 0
	i = 0
	for kv in rle:
		k, v = kv
#		count += v
#		i += v
		string += "[" + str(k) + "," + str(v) + "],"
#		if 11<v:
#			lcm_result = int(lcm([count, 8], 0)/8)
#			string += " (" + str(count) + "," + str(lcm_result) + ")\n" + dec(i+1, 5) + ":"
#			count = 0
	string = string[:-1]
	#print(string)
	return rle

def get_longest_run(rle_numbers):
	max_run_length = 0
	for kv in rle_numbers:
		max_run_length = max(max_run_length, kv[1])
	return max_run_length

def show_longest_run(rle_numbers):
	max_run_length = get_longest_run(rle_numbers)
	print("the longest run is " + str(max_run_length))

