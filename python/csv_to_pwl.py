#!/usr/bin/env python3

# written 2021-05-30 by mza
# last updated 2021-05-30 by mza

import csv

frequency = 508887500.0
#timestep = 1.0/frequency
timestep = 1.0e-9
#print("%e" % timestep/2)
normalization = 25.0

with open("bcm.csv") as inputfile:
	time = 0.0
	csv_iterable = csv.reader(inputfile, delimiter=',')
	with open("bcm.pwl", "w") as outputfile:
		for row in csv_iterable:
			#print(",0,".join(row[1:]))
			for value in row[1:]:
				line = "%e %f" % (time, float(value)/normalization)
				#print(line)
				outputfile.write(line + "\n")				
				time += timestep

