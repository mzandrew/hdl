#!/usr/bin/env python3

import time # sleep, time
import random # randint
import fastgpio

def hex(number, width=1):
	return "%0*x" % (width, number)

gpio = [ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26 ] # althea revB
bits = len(gpio)
mask = 0
for i in gpio:
	if i:
		mask |= 1<<i
#print(hex(mask))
NUM = 20000
data = [ random.randint(0,2**32-1) for d in range(NUM) ]
#NUM = len(data)
fastgpio.setup_bus_as_outputs(mask)
start = time.time()
fastgpio.write(data, mask)
end = time.time()
diff = end - start
per = NUM / diff
#print(str(diff))
#print(str(bits*per) + " bits per second") # 237073479.53877458 bits per second
#print(str(bits*per/8.0) + " bytes per second") # 29691244.761581153 bytes per second
print(str(bits*per/8.0e6) + " MB per second") # 29.80263756252842 MB per second

