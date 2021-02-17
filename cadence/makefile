list_of_all_verilog_files := $(wildcard ../verilog/src/*.v)
list_of_all_lib_files := $(wildcard ../verilog/src/lib/*.v)

default :
	@#echo $(list_of_all_verilog_files)
	@#echo $(list_of_all_lib_files)
	$(MAKE) all

all :
	@$(MAKE) libs
	@$(MAKE) projects
	@#$(MAKE) xcelium
	@#$(MAKE) imc

xcelium.d/lib% : ../verilog/src/lib/%.v
	xrun -v2001 -incdir ../verilog/src/lib -compile -makelib $@ $<

libs :
	@$(MAKE) $(list_of_all_lib_files:../verilog/src/lib/%.v=xcelium.d/lib%)

projects :
	@$(MAKE) $(list_of_all_verilog_files:../verilog/src/%.v=blah)

xcelium : ../verilog/src/%.v
	#@xrun ../verilog/src/mza-test048.simple-counter-again.v -access +rwc -covfile mza048.ccf -coverage all -covoverwrite
	#@xrun ../verilog/src/mza-test048.simple-counter-again.v -access +rwc -covfile mza048.ccf -coverage all -covoverwrite
	#@xrun ../verilog/src/mza-test040.spi-pollable-memory.v -access +rwc -covfile mza040.ccf -coverage all -covoverwrite -incdir ../verilog/src/lib
	#@xrun -incdir ../verilog/src ../verilog/src/mza-test040.spi-pollable-memory.v -access +rwc -covfile mza040.ccf -coverage all -covoverwrite -bbcell SB_RAM40_4K
	#@xrun -incdir ../verilog/src ../verilog/src/mza-test040.spi-pollable-memory.v -access +rwc -bbcell SB_RAM40_4K
	#@xrun -incdir ../verilog/src -reflib xcelium.d/libsuperkekb ../verilog/src/mza-test048.simple-counter-again.v -access +rwc
	xrun -incdir ../verilog/src $< -access +rwc
	#@xrun -access +rwc -incdir ../verilog/src ../verilog/src/lib/frequency_counter.v -top frequency_counter_tb
	#@xrun ../verilog/src/lib/axi4lite.v -access +rwc -gui -top spi_slave_axi4lite_master__pollable_memory_axi4list_slave__tb
	#@xrun -incdir ../verilog/src/ ../verilog/src/lib/axi4.sv -access +rwc -gui -top spi_slave_axi4_master__pollable_memory_axi4_slave__tb

imc :
	#imc -exec mza048.tcl
	imc -exec mza040.tcl

clean :
	rm -rf .simvision waves.shm xcelium.d xrun.history xrun.key xrun.log *.log cov_work imc.key report irun.history INCA_libs

