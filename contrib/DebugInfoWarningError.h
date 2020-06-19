// written 2012-08-16 by mza
// taken from https://github.com/mzandrew/idlab-daq/blob/bd6df66c71e8a7c31ea97fc1838c69db0a533926/iTOP-DSP_FIN-COPPER-FINESSE/branches/crt-nov2012/acquisition/src/lib/DebugInfoWarningError.h
// last updated 2020-06-18 by mza

extern unsigned short int verbosity;

#include <stdio.h>
extern FILE *debug;
extern FILE *debug2;
extern FILE *info;
extern FILE *warning;
extern FILE *errorr; // unfortunate clash with system builtin

void setup_DebugInfoWarningError(void);
void setup_DebugInfoWarningError_if_needed(void);
unsigned short int change_verbosity(unsigned short int new_verbosity);
void diwe_flush_all_streams(void);

