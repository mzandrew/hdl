#!/usr/bin/env python3

# written 2020-06-05 by mza
# based on example code from https://realpython.com/build-python-c-extension-module/
# last updated 2024-02-13 by mza

from distutils.core import setup, Extension

def main():
	setup(
		name="print_string",
		version="1.0.0",
		description="python interface for printf",
		author="mza",
		author_email="mza@scammerz.gmail.com",
		zip_safe = False,
		ext_modules=[Extension("print_string", ["print_string.c"])])

if __name__ == "__main__":
	main()

