#!/usr/bin/env python3

# written 2020-06-05 by mza
# based on example code from https://realpython.com/build-python-c-extension-module/
# last updated 2024-02-13 by mza

from distutils.core import setup, Extension

def main():
	setup(
		name="fastgpio",
		version="1.0.0",
		description="python interface for fast gpio interface",
		author="mza",
		author_email="mza@scammerz.gmail.com",
		zip_safe = False,
		ext_modules=[Extension("fastgpio", ["fastgpio.c", "../../contrib/DebugInfoWarningError.c"],
			extra_compile_args=['-Wno-missing-braces', '-std=gnu99'],
			include_dirs=['/opt/vc/include', '../../contrib'],
			library_dirs=['/opt/vc/lib', '../../contrib'],
			libraries=['bcm_host']
		)])

if __name__ == "__main__":
	main()

