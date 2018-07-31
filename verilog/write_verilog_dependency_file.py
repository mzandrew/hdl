#!/usr/bin/env python
# written 2018-07-31 by mza

import os # os.path.isfile()
import sys # sys.argv
import re # re.search()

src = "src"
work = "work"
input_dirname = src
output_dirname = work

def run_file(filename):
	includes = []
	#includes.append(filename)
	match = re.search(src + "/(.*)\.v", filename)
	if match:
		basename = match.group(1)
	else:
		return # not a .v file
	depfilename = "work/" + basename + ".d"
	#print depfilename
	binfilename = "work/" + basename + ".bin"
	for line in open(filename):
		#line = line.rstrip("\n\r")
		match = re.search("`include \"(.*)\"", line)
		if match:
			#print match.group(1)
			includes.append(input_dirname + "/" + match.group(1))
	#includes.append(depfilename)
	depfile = open(depfilename, 'w')
	string = binfilename + " " + depfilename + " : " + filename
	for include in includes:
		string += " " + include
	string += "\n"
	#print string
	#print(depfilename, file=depfile)
	print >>depfile, string

if __name__ == "__main__":
	if not os.path.isdir(output_dirname):
		os.mkdir(output_dirname)
	argc = len(sys.argv)
	if argc>=2:
		for filename in sys.argv[1:]:
			if os.path.isfile(filename):
				run_file(filename)
	else:
		for basename in os.listdir(input_dirname):
			filename = os.path.join(input_dirname, basename)
			if os.path.isfile(filename):
				run_file(filename)

