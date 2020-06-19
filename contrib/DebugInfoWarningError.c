// written 2012-08-16 by mza
// taken from https://github.com/mzandrew/idlab-daq/blob/bd6df66c71e8a7c31ea97fc1838c69db0a533926/iTOP-DSP_FIN-COPPER-FINESSE/branches/crt-nov2012/acquisition/src/lib/DebugInfoWarningError.cpp
// last updated 2020-06-18 by mza

// gcc -std=c99 -c DebugInfoWarningError.c -o DebugInfoWarningError.o
// gcc -std=gnu99 -c DebugInfoWarningError.c -o DebugInfoWarningError.o

/* usage:
	change_verbosity(4);
	fprintf(errorr,  "this is the error message\n");
	fprintf(warning, "this is the warning message\n");
	fprintf(info,    "this is the info message\n");
	fprintf(debug,   "this is the debug message\n");
	fprintf(debug2,  "this is the debug2 message\n");
*/

#include <fcntl.h>
#include <stdio.h>
#include <stdbool.h>
#include "DebugInfoWarningError.h"

unsigned short int verbosity = 3;
bool has_been_run_through = false;
FILE *debug   = 0;
FILE *debug2  = 0;
FILE *info    = 0;
FILE *warning = 0;
FILE *errorr  = 0;

void setup_DebugInfoWarningError(void) {
//	printf("got here 2\n");
//	if (has_been_run_through) {
//		return;
//	}
//	static int stdout_fd, stderr_fd, devnull_fd;
	static FILE *stderr_FILE = 0;
	static FILE *stdout_FILE = 0;
	static FILE *devnull_FILE = 0;
	if (!has_been_run_through) {
//		stderr_fd  = open("/dev/stderr", O_WRONLY);
//		stdout_fd  = open("/dev/stdout", O_WRONLY);
//		devnull_fd = open("/dev/null",   O_WRONLY);
		stderr_FILE  = fopen("/dev/stderr", "w");
		stdout_FILE  = fopen("/dev/stdout", "w");
		devnull_FILE = fopen("/dev/null",   "w");
	}
//	printf("got here 3 %d %d %d\n", stderr_fd, stdout_fd, devnull_fd);
//	printf("got here 3\n");
//	if (!errorr) {
//		printf("no errorr\n");
//	}
//	if (!devnull_FILE) {
//		printf("no devnull\n");
//	}
//	printf("got here 3\n");
	if (verbosity >= 1) {
//		errorr = fdopen(stderr_fd, "w");
		errorr = stderr_FILE;
	} else {
//		errorr = fdopen(devnull_fd, "w");
		errorr = devnull_FILE;
	}
//	printf("got here 4\n");
//	fflush(stdout);
//	fflush(stderr);
	if (verbosity >= 2) {
//		warning = fdopen(stderr_fd, "w");
		warning = stderr_FILE;
	} else {
//		warning = fdopen(devnull_fd, "w");
		warning = devnull_FILE;
	}
	if (verbosity >= 3) {
//		info = fdopen(stdout_fd, "w");
		info = stdout_FILE;
	} else {
//		info = fdopen(devnull_fd, "w");
		info = devnull_FILE;
	}
	if (verbosity >= 4) {
//		debug = fdopen(stdout_fd, "w");
		debug = stdout_FILE;
	} else {
//		debug = fdopen(devnull_fd, "w");
		debug = devnull_FILE;
	}
	if (verbosity >= 5) {
//		debug2 = fdopen(stdout_fd, "w");
		debug2 = stdout_FILE;
	} else {
//		debug2 = fdopen(devnull_fd, "w");
		debug2 = devnull_FILE;
	}
//	printf("got here 5\n");
	if (0) {
		fprintf(errorr,  "this is the error message\n");
		fprintf(warning, "this is the warning message\n");
		fprintf(info,    "this is the info message\n");
		fprintf(debug,   "this is the debug message\n");
		fprintf(debug2,  "this is the debug2 message\n");
	}
//	printf("got here 6\n");
	has_been_run_through = true;
}

void setup_DebugInfoWarningError_if_needed(void) {
//	printf("got here 1\n");
	if (!has_been_run_through) {
		setup_DebugInfoWarningError();
	}
}

unsigned short int change_verbosity(unsigned short int new_verbosity) {
	unsigned short int old_verbosity = verbosity;
	verbosity = new_verbosity;
	setup_DebugInfoWarningError();
	return old_verbosity;
}

void diwe_flush_all_streams(void) {
	fflush(debug2);
	fflush(debug);
	fflush(info);
	fflush(warning);
	fflush(errorr);
}

