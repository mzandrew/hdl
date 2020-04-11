#!/bin/bash -e

data2mem -bm verilog/src/mza-test036.bram-init.bmm -bt ise-projects/mza_test036_function_generator_althea/althea.bit -bd verilog/src/mza-test036.bram-init.mem -ob ise-projects/mza_test036_function_generator_althea/althea-bram-init.bit
ls -lart ise-projects/mza_test036_function_generator_althea/althea.bit verilog/src/mza-test036.bram-init.mem ise-projects/mza_test036_function_generator_althea/althea-bram-init.bit

