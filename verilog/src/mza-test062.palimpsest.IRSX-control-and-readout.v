// written 2023-10-09 by mza
// based on mza-test058.palimpsest.protodune-LBLS-DAQ.althea.revBLM.v
// last updated 2024-11-25 by mza

// WARNING:Xst:638 - in unit altheaIRSXtest Conflict on KEEP property on signal IRSXtest/reset127_wait4pll/pipesync/cdc and IRSXtest/status12_copy/async_cdc<2> IRSXtest/status12_copy/async_cdc<2> signal will be lost.
// filtered Xst:1710 "FF/Latch riwri_bank1/mem_0_370 (without init value) has a constant value of 0 in block altheaIRSXtest. This FF/Latch will be trimmed during the optimization process."

`define althea_revBLM
`include "lib/generic.v"
//`include "lib/RAM8.v"
//`include "lib/fifo.v"
//`include "lib/RAM.sv" // ise does not and will not support systemverilog
`include "lib/plldcm.v"
`include "lib/serdes_pll.v"
`include "lib/half_duplex_rpi_bus.v"
//`include "lib/sequencer.v"
`include "lib/reset.v"
//`include "lib/edge_to_pulse.v"
//`include "lib/frequency_counter.v"
`include "lib/irsx.v"

module IRSXtest #(
	parameter TESTBENCH = 0,
	parameter NUMBER_OF_CHANNELS = 8,
	parameter COUNTER_WIDTH = 32,
	parameter SCALER_WIDTH = 16,
	// ----------------------------------------------------------------------
	parameter DCM_INPUT_PERIOD = 7.861, // 127.221875 MHz
	parameter DCM_MULTIPLY = 4, // 508.8875 MHz
	parameter DCM_DIVIDE = 24, // 21.203646 MHz
	parameter DCM_FREQUENCY = 1e9 * DCM_MULTIPLY / DCM_DIVIDE / DCM_INPUT_PERIOD, // 21.203646 MHz (SST)
	parameter PLL_INPUT_PERIOD = DCM_INPUT_PERIOD * DCM_DIVIDE / DCM_MULTIPLY,
	parameter PLL_MULTIPLY = 48, // 1017.775 MHz
	parameter PLL_OVERALL_DIVIDE = 1, // 1017.775 MHz
	parameter PLL_FREQUENCY = DCM_FREQUENCY * PLL_MULTIPLY / PLL_OVERALL_DIVIDE, // 1017.775 MHz (everything else is derived from this)
	// ----------------------------------------------------------------------
	parameter EXTRA_FACTOR_OF_TWO = 2,
	parameter EYE_DIAGRAM_CAPTURE_POINTS = 3,
	// ----------------------------------------------------------------------
	parameter WORD_CLOCK_DIVIDE = 8, //  1017.775/8 = 127.221875 MHz
	// ----------------------------------------------------------------------
	parameter SST_CLK_DIVIDE = 48, // 1017/48 = 21.203646 MHz
	parameter WR_DAT_BIT_DEPTH = 8,
	parameter WR_BIT_CLK_DIVIDE = SST_CLK_DIVIDE / WR_DAT_BIT_DEPTH / EXTRA_FACTOR_OF_TWO, // 1017/3 = 339 MHz (EXTRA_FACTOR_OF_TWO because it's twice the speed that's strictly needed so we can oserdes the wr_clk out of phase with the wr_dat edges; could alternately use an ODDR with bits inverted to get the same effect)
	parameter WR_WORD_CLK_DIVIDE = WR_BIT_CLK_DIVIDE * WR_DAT_BIT_DEPTH, // 1017/3/8 = 42 MHz
	parameter TRG_BIT_DEPTH = 4,
	parameter TRG_WORD_CLK_DIVIDE = SST_CLK_DIVIDE, // 1017/48 = 21 MHz
	parameter TRG_BIT_CLK_DIVIDE = TRG_WORD_CLK_DIVIDE / TRG_BIT_DEPTH, // 1017/12 = 84.814583 MHz
	parameter HS_BIT_CLK_DIVIDE = 2, // hs_bit_clk_raw: 1017/1 = 1017 MHz
	//parameter HS_DAT_BIT_DEPTH = EYE_DIAGRAM_CAPTURE_POINTS + 1, // 3 or 6 (needs approprate gearboxen)
	parameter HS_DAT_BIT_DEPTH = 4,
	parameter HS_WORD_CLK_DIVIDE = HS_BIT_CLK_DIVIDE * HS_DAT_BIT_DEPTH, // hs_clk: 1017/8 = 127 MHz; 1017/6 = 169 MHz; 1017/4 = 254 MHz; 1017/3 = 339 MHz (BRAM can only do 320 MHz on a spartan6...)
	parameter GCC_BIT_DEPTH = 4,
	parameter GCC_BIT_CLK_DIVIDE = 1, // 1017/1 = 1017 MHz
	parameter GCC_WORD_CLK_DIVIDE = GCC_BIT_CLK_DIVIDE * GCC_BIT_DEPTH, // 1017/4 = 254 MHz
	// ----------------------------------------------------------------------
	parameter HS_CLK_OSERDES_MODE = 0, // ODDR mode otherwise
	parameter LOG2_OF_HS_DAT_BIT_DEPTH = $clog2(HS_DAT_BIT_DEPTH),
	parameter HS_DATA_INTENDED_NUMBER_OF_BITS = 24, // this is 12 bits for the real data and 12 bits for the test pattern generator (tpg)
	parameter LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH = 5, // 2**5 = 32
	// ----------------------------------------------------------------------
	parameter BUS_WIDTH = 16,
	parameter LOG2_OF_BUS_WIDTH = $clog2(BUS_WIDTH),
	parameter TRANSACTIONS_PER_DATA_WORD = 2,
	parameter LOG2_OF_TRANSACTIONS_PER_DATA_WORD = $clog2(TRANSACTIONS_PER_DATA_WORD),
	parameter OSERDES_DATA_WIDTH = 8,
	parameter TRANSACTIONS_PER_ADDRESS_WORD = 1,
	parameter BANK_ADDRESS_DEPTH = 13,
	parameter LOG2_OF_NUMBER_OF_BANKS = BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD - BANK_ADDRESS_DEPTH, // 3
	parameter NUMBER_OF_BANKS = 1<<LOG2_OF_NUMBER_OF_BANKS, // 2^3 = 8
	parameter LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH = $clog2(64),
	parameter ADDRESS_DEPTH_OSERDES = BANK_ADDRESS_DEPTH + LOG2_OF_BUS_WIDTH + LOG2_OF_TRANSACTIONS_PER_DATA_WORD - LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH, // 13 - 4 + 1 - 6 = 4
	parameter ADDRESS_AUTOINCREMENT_MODE = 1,
	parameter COUNTER127_BIT_PICKOFF = TESTBENCH ? 5 : 23,
	parameter COUNTERWORD_BIT_PICKOFF = TESTBENCH ? 5 : 23
) (
	input clock127_p, clock127_n,
	input button,
	inout [5:0] coax,
//	input [2:0] rot,
	inout [23:4] rpi_gpio,
	output sin, sclk, pclk, regclr, convert, spgin, ss_incr,
	output sstclk_p, sstclk_n, hs_clk_p, hs_clk_n, gcc_clk_p, gcc_clk_n, wr_clk_p, wr_clk_n, wr_dat_p, wr_dat_n,
	input shout, done_out, wr_syncmon, montiming2,
	input data_p, data_n, trg01_p, trg01_n, trg23_p, trg23_n, trg45_p, trg45_n, trg67_p, trg67_n, montiming1_p, montiming1_n,
//	output other,
	output regen, // regulator enable
	output [7:0] led,
	output [3:0] coax_led
);
	genvar i;
	localparam ERROR_COUNT_PICKOFF = 3;
	// ----------------------------------------------------------------------
	wire reset = ~button;
	// ----------------------------------------------------------------------
	wire word_clock_raw, word_clock, reset_word;
	// WORD_CLOCK is the clock governing the raspberry pi interface
	// just need a single BUFG (1 clock total)
	wire first_pll_locked, second_pll_locked, third_pll_locked, all_plls_locked;
	assign all_plls_locked = first_pll_locked && second_pll_locked && third_pll_locked;
	BUFG wrd (.I(word_clock_raw), .O(word_clock));
	// ----------------------------------------------------------------------
	wire always_clock, always_clock_reset;
	// always_clock is the board-level oscillator and only needs to get to the PLL's input
	IBUFGDS mybuf0 (.I(clock127_p), .IB(clock127_n), .O(always_clock));
	reset_wait #(.COUNTER_BIT_PICKOFF(COUNTER127_BIT_PICKOFF)) reset127_wait (.reset_input(reset), .clock_input(always_clock), .reset_output(always_clock_reset));
	wire all_plls_locked_clock127;
	slow_asynchronizer all_plls_locked_synch1 (.clock(always_clock), .async_in(all_plls_locked),  .sync_out(all_plls_locked_clock127));
	// ----------------------------------------------------------------------
	wire all_plls_locked_word;
	pipeline_synchronizer all_plls_locked_synch2 (.clock1(always_clock), .clock2(word_clock), .in1(all_plls_locked_clock127), .out2(all_plls_locked_word));
	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset1_input(always_clock_reset), .pll_locked1_input(all_plls_locked_clock127), .clock1_input(always_clock), .clock2_input(word_clock), .reset2_output(reset_word));
	// ----------------------------------------------------------------------
//	wire [3:0] status4;
	reg [7:0] status8 = 0, status8_copy_on_word_clock_domain = 0;
	reg [7:0] pll_status8_buffered = 0;
	wire [7:0] pll_status8;
	wire [11:0] status12, status12_copy_on_word_clock_domain;
	always @(posedge always_clock) begin
		pll_status8_buffered <= pll_status8;
	end
	always @(posedge word_clock) begin
		status8_copy_on_word_clock_domain <= ~status8;
		status8 <= pll_status8_buffered;
	end
	if (0) begin
		//assign status8_copy_on_word_clock_domain = 0;
		assign status12_copy_on_word_clock_domain = 0;
	end else begin
		//slow_asynchronizer #(.WIDTH(8))  status8_copy  (.clock(word_clock), .async_in(~status8),  .sync_out(status8_copy_on_word_clock_domain));
		slow_asynchronizer #(.WIDTH(12)) status12_copy (.clock(word_clock), .async_in(status12), .sync_out(status12_copy_on_word_clock_domain));
	end
	assign status12[11:2] = 0;
	// ----------------------------------------------------------------------
	// SST is the sampling clock; each edge starts the sampling of 128 samples in the IRSX
	// this is aligned to the accelerator clock and should have low jitter
	// need an ODDR pair for this (2 clocks total)
	wire sstclk_raw, sstclk180_raw, sstclk, sstclk180;
//	wire regen_copy_on_sstclk;
	BUFG sstraw (.I(sstclk_raw), .O(sstclk));
	BUFG sst180 (.I(sstclk180_raw), .O(sstclk180));
	//reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetsst_wait4pll (.reset1_input(reset_word), .pll_locked1_input(all_plls_locked_word), .clock1_input(word_clock), .clock2_input(sstclk), .reset2_output(reset_sst));
//	pipeline_synchronizer regen_copy_sstclk (.clock1(word_clock), .clock2(sstclk), .in1(regen), .out2(regen_copy_on_sstclk));
	clock_ODDR_out_diff sstclk_ODDR  (.clock_in_p(sstclk), .clock_in_n(sstclk180), .clock_enable(1'b1), .clock_out_p(sstclk_p), .clock_out_n(sstclk_n));
	// ----------------------------------------------------------------------
	// WR is the clock feeding new write addresses to the IRSX to direct the storage of analog samples
	// each bit we give out for the WR_DAT needs a corresponding clock
	// but only needs to be about 2x as fast as 8*SST so the address is updated in time and with known phase to SST
	// WR_CLK_f needs to be 8*SST_f; WR_DAT_f needs to be 8*SST_f
	// it is convenient if this runs at a multiple of 8*SST (need to write a new 8 bit address for each SST)
	wire wr_dat, wr_clk;
	wire wr_word_clk_raw, wr_word_clk, reset_wr;
	BUFG wr_raw (.I(wr_word_clk_raw), .O(wr_word_clk));
	OBUFDS wr_clk_obufds (.I(wr_clk), .O(wr_clk_p), .OB(wr_clk_n));
	OBUFDS wr_dat_obufds (.I(wr_dat), .O(wr_dat_p), .OB(wr_dat_n));
//	wire regen_copy_on_wr_clk;
//	pipeline_synchronizer regen_copy_wr_clk (.clock1(word_clock), .clock2(wr_word_clk), .in1(regen), .out2(regen_copy_on_wr_clk));
	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetwr_wait4pll (.reset1_input(reset_word), .pll_locked1_input(all_plls_locked_word), .clock1_input(word_clock), .clock2_input(wr_word_clk), .reset2_output(reset_wr));
	wire wr_pll_is_locked_and_strobe_is_aligned;
	// ----------------------------------------------------------------------
	// GCC is the Gray code clock for doing the duration timer part of the wilkinson conversion in the IRSX
	// need an ODDR pair for this (2 clocks total)
	wire gcc_clk_raw, gcc_clk180_raw, gcc_clk, gcc_clk180, reset_gcc;
//	wire regen_copy_on_gcc_clk;
	BUFG gccraw (.I(gcc_clk_raw), .O(gcc_clk));
	BUFG gcc180 (.I(gcc_clk180_raw), .O(gcc_clk180));
//	pipeline_synchronizer regen_copy_gcc_clk (.clock1(word_clock), .clock2(gcc_clk), .in1(regen), .out2(regen_copy_on_gcc_clk));
	clock_ODDR_out_diff gcc_clk_ODDR (.clock_in_p(gcc_clk), .clock_in_n(gcc_clk180), .clock_enable(1'b1), .clock_out_p(gcc_clk_p), .clock_out_n(gcc_clk_n));
	wire should_start_wilkinson_conversion_now;
	wire should_start_wilkinson_conversion_now_copy_on_gcc_clk;
	pipeline_synchronizer should_start_wilkinson_conversion_now_copy_gcc_clk (.clock1(word_clock), .clock2(gcc_clk), .in1(should_start_wilkinson_conversion_now), .out2(should_start_wilkinson_conversion_now_copy_on_gcc_clk));
	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetgcc_wait4pll (.reset1_input(reset_word), .pll_locked1_input(all_plls_locked_word), .clock1_input(word_clock), .clock2_input(gcc_clk), .reset2_output(reset_gcc));
	// ----------------------------------------------------------------------
	// HS is the high speed data out from the IRSX; need to find the center of the eye for this to work well
	// each time we want a new HS_DAT bit, we must give another HS_CLK (system synchronous)
	wire hs_bit_clk_raw, hs_pll_is_locked_and_strobe_is_aligned;
	wire hs_word_clock_raw, hs_word_clock, hs_word_reset;
	wire hs_word_clock180_raw, hs_word_clock180;
	wire hs_data;
	IBUFDS hs_data_buf (.I(data_p), .IB(data_n), .O(hs_data));
	BUFG hsraw (.I(hs_word_clock_raw), .O(hs_word_clock));
	BUFG hsraw180 (.I(hs_word_clock180_raw), .O(hs_word_clock180));
	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) reseths_wait4pll (.reset1_input(reset_word), .pll_locked1_input(all_plls_locked_word), .clock1_input(word_clock), .clock2_input(hs_word_clock), .reset2_output(hs_word_reset));
	wire hs_clk_OSERDES;
//	wire regen_copy_on_hs_word_clk;
//	pipeline_synchronizer regen_copy_hs_word_clk (.clock1(word_clock), .clock2(hs_word_clock), .in1(regen), .out2(regen_copy_on_hs_word_clk));
	if (HS_CLK_OSERDES_MODE) begin // ODDR mode
		OBUFDS hs_clk_buf (.I(hs_clk_OSERDES), .O(hs_clk_p), .OB(hs_clk_n));
	end else begin // OSERDES mode
		//slow_asynchronizer regen_copy_hs_clk (.clock(hs_clk), .async_in(regen), .sync_out(regen_copy_on_hs_word_clk)); // this changes slowly/rarely from the gui or command-line, so can effectively treat regen as an asynchronous input for timing purposes
		//fast_asynchronizer regen_copy_hs_clk (.clock(hs_clk), .async_in(regen), .sync_out(regen_copy_on_hs_word_clk)); // this changes slowly/rarely from the gui or command-line, so can effectively treat regen as an asynchronous input for timing purposes
		clock_ODDR_out_diff hs_clk_ODDR (.clock_in_p(hs_word_clock),  .clock_in_n(hs_word_clock180), .clock_enable(1'b1), .clock_out_p(hs_clk_p),  .clock_out_n(hs_clk_n));
	end
	// ----------------------------------------------------------------------
	// MONTIMING1 and MONTIMING2 are copies of internal timing strobes from the IRSX for debugging/troubleshooting
	wire montiming1;
	IBUFDS montiming1_buf (.I(montiming1_p), .IB(montiming1_n), .O(montiming1));
	wire [31:0] frequency_of_montiming1, frequency_of_montiming2;
	localparam FREQUENCY_OF_WORD_CLOCK = 127221875;
	frequency_counter #(.FREQUENCY_OF_REFERENCE_CLOCK(FREQUENCY_OF_WORD_CLOCK), .N(1000), .LOG2_OF_DIVIDE_RATIO(17)) m1 (.reference_clock(word_clock), .unknown_clock(montiming1), .frequency_of_unknown_clock(frequency_of_montiming1), .valid(status12[0]));
	frequency_counter #(.FREQUENCY_OF_REFERENCE_CLOCK(FREQUENCY_OF_WORD_CLOCK), .N(1000), .LOG2_OF_DIVIDE_RATIO(17)) m2 (.reference_clock(word_clock), .unknown_clock(montiming2), .frequency_of_unknown_clock(frequency_of_montiming2), .valid(status12[1]));
	// ----------------------------------------------------------------------
	// TRG is for capturing the trigger bits streaming from the IRSX
	// it is convenient if this is captured on a multiple of SST so the downstream processing knows precisely where to look in the window
	wire trg_word_clock_raw, trg_word_clock;
	BUFG trgraw (.I(trg_word_clock_raw), .O(trg_word_clock));
	wire trg01, trg23, trg45, trg67;
	IBUFDS trg01_buf (.I(trg01_p), .IB(trg01_n), .O(trg01));
	IBUFDS trg23_buf (.I(trg23_p), .IB(trg23_n), .O(trg23));
	IBUFDS trg45_buf (.I(trg45_p), .IB(trg45_n), .O(trg45)); // pins swapped on PCB
	IBUFDS trg67_buf (.I(trg67_p), .IB(trg67_n), .O(trg67)); // pins swapped on PCB
	wire trg_reset = 0;
	// clip from here and shove into trg module
	wire [3:0] trg_inversion_mask;
	wire trg0123 = trg_inversion_mask[0] ^ trg01 || trg_inversion_mask[1] ^ trg23;
	wire trg4567 = trg_inversion_mask[2] ^ trg45 || trg_inversion_mask[3] ^ trg67;
	wire trgall = trg0123 || trg4567;
	wire trg_pll_is_locked_and_strobe_is_aligned1, trg_pll_is_locked_and_strobe_is_aligned2;
	wire trg_bit_clock1_raw, trg_bit_clock1;
	wire trg_bit_clock2_raw, trg_bit_clock2;
	wire trg_bit_strobe1, trg_bit_strobe2;
	wire [TRG_BIT_DEPTH-1:0] trg01_word, trg23_word, trg45_word, trg67_word;
	BUFPLL #(
		.ENABLE_SYNC("TRUE"), // synchronizes strobe to gclk input
		.DIVIDE(TRG_BIT_DEPTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
	) trg_bufpll_inst1 (
		.PLLIN(trg_bit_clock1_raw), // PLL Clock input
		.GCLK(trg_word_clock), // Global Clock input
		.LOCKED(third_pll_locked), // Clock0 locked input
		.IOCLK(trg_bit_clock1), // Output PLL Clock
		.LOCK(trg_pll_is_locked_and_strobe_is_aligned1), // BUFPLL Clock and strobe locked
		.SERDESSTROBE(trg_bit_strobe1) // Output SERDES strobe
	);
	BUFPLL #(
		.ENABLE_SYNC("TRUE"), // synchronizes strobe to gclk input
		.DIVIDE(TRG_BIT_DEPTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
	) trg_bufpll_inst2 (
		.PLLIN(trg_bit_clock2_raw), // PLL Clock input
		.GCLK(trg_word_clock), // Global Clock input
		.LOCKED(third_pll_locked), // Clock0 locked input
		.IOCLK(trg_bit_clock2), // Output PLL Clock
		.LOCK(trg_pll_is_locked_and_strobe_is_aligned2), // BUFPLL Clock and strobe locked
		.SERDESSTROBE(trg_bit_strobe2) // Output SERDES strobe
	);
	// if TRG_BIT_DEPTH==8:
//	iserdes_single8_inner #(.BIT_RATIO(TRG_BIT_DEPTH), .PINTYPE("p")) trg01_iserdes (.bit_clock(trg_bit_clock1), .bit_strobe(trg_bit_strobe1), .word_clock(trg_word_clock), .reset(trg_reset), .data_in(trg01), .word_out(trg01_word));
//	iserdes_single8_inner #(.BIT_RATIO(TRG_BIT_DEPTH), .PINTYPE("p")) trg23_iserdes (.bit_clock(trg_bit_clock1), .bit_strobe(trg_bit_strobe1), .word_clock(trg_word_clock), .reset(trg_reset), .data_in(trg23), .word_out(trg23_word));
//	iserdes_single8_inner #(.BIT_RATIO(TRG_BIT_DEPTH), .PINTYPE("p")) trg45_iserdes (.bit_clock(trg_bit_clock2), .bit_strobe(trg_bit_strobe2), .word_clock(trg_word_clock), .reset(trg_reset), .data_in(trg45), .word_out(trg45_word));
//	iserdes_single8_inner #(.BIT_RATIO(TRG_BIT_DEPTH), .PINTYPE("p")) trg67_iserdes (.bit_clock(trg_bit_clock2), .bit_strobe(trg_bit_strobe2), .word_clock(trg_word_clock), .reset(trg_reset), .data_in(trg67), .word_out(trg67_word));
	// else:
	iserdes_single4_inner #(.BIT_RATIO(TRG_BIT_DEPTH)) trg01_iserdes (.bit_clock(trg_bit_clock1), .bit_strobe(trg_bit_strobe1), .word_clock(trg_word_clock), .reset(trg_reset), .data_in(trg01), .word_out(trg01_word));
	iserdes_single4_inner #(.BIT_RATIO(TRG_BIT_DEPTH)) trg23_iserdes (.bit_clock(trg_bit_clock1), .bit_strobe(trg_bit_strobe1), .word_clock(trg_word_clock), .reset(trg_reset), .data_in(trg23), .word_out(trg23_word));
	iserdes_single4_inner #(.BIT_RATIO(TRG_BIT_DEPTH)) trg45_iserdes (.bit_clock(trg_bit_clock2), .bit_strobe(trg_bit_strobe2), .word_clock(trg_word_clock), .reset(trg_reset), .data_in(trg45), .word_out(trg45_word));
	iserdes_single4_inner #(.BIT_RATIO(TRG_BIT_DEPTH)) trg67_iserdes (.bit_clock(trg_bit_clock2), .bit_strobe(trg_bit_strobe2), .word_clock(trg_word_clock), .reset(trg_reset), .data_in(trg67), .word_out(trg67_word));
	// clip to here
	// ----------------------------------------------------------------------
	dcm_pll_pll #(
		.DCM_PERIOD(DCM_INPUT_PERIOD), .DCM_MULTIPLY(DCM_MULTIPLY), .DCM_DIVIDE(DCM_DIVIDE),
		.PLL_PERIOD(PLL_INPUT_PERIOD), .PLL_MULTIPLY(PLL_MULTIPLY), .PLL_OVERALL_DIVIDE(PLL_OVERALL_DIVIDE),
		.PLL_DIVIDE0(WR_BIT_CLK_DIVIDE), .PLL_DIVIDE1(TRG_BIT_CLK_DIVIDE),
		.PLL_DIVIDE2(WR_WORD_CLK_DIVIDE), .PLL_DIVIDE3(48),
		.PLL_DIVIDE4(GCC_WORD_CLK_DIVIDE), .PLL_DIVIDE5(GCC_WORD_CLK_DIVIDE),
		.PLL_DIVIDE6(HS_BIT_CLK_DIVIDE), .PLL_DIVIDE7(TRG_BIT_CLK_DIVIDE),
		.PLL_DIVIDE8(TRG_WORD_CLK_DIVIDE), .PLL_DIVIDE9(WORD_CLOCK_DIVIDE),
		.PLL_DIVIDE10(HS_WORD_CLK_DIVIDE), .PLL_DIVIDE11(HS_WORD_CLK_DIVIDE),
		.PLL_PHASE0(0.0),  .PLL_PHASE1(0.0),
		.PLL_PHASE2(0.0),  .PLL_PHASE3(0.0),
		.PLL_PHASE4(0.0),  .PLL_PHASE5(180.0),
		.PLL_PHASE6(0.0),  .PLL_PHASE7(0.0),
		.PLL_PHASE8(0.0),  .PLL_PHASE9(0.0),
		.PLL_PHASE10(0.0), .PLL_PHASE11(180.0)
	) my_dcm_pll (
		.clockin(always_clock), .reset(always_clock_reset),
		.clockintermediate(), .clockintermediate_raw(sstclk_raw),  .clockintermediate_raw180(sstclk180_raw),
		.dcm_locked(first_pll_locked), .pll1_locked(second_pll_locked), .pll2_locked(third_pll_locked),
		.clock0out(wr_bit_clk_raw), .clock1out(trg_bit_clock1_raw),
		.clock2out(wr_word_clk_raw), .clock3out(),
		.clock4out(gcc_clk_raw), .clock5out(gcc_clk180_raw),
		.clock6out(hs_bit_clk_raw), .clock7out(trg_bit_clock2_raw),
		.clock8out(trg_word_clock_raw), .clock9out(word_clock_raw),
		.clock10out(hs_word_clock_raw), .clock11out(hs_word_clock180_raw)
	);
	// ----------------------------------------------------------------------
	wire [BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD-1:0] address_word_full;
	wire [BANK_ADDRESS_DEPTH-1:0] address_word_narrow = address_word_full[BANK_ADDRESS_DEPTH-1:0];
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] write_data_word;
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] read_data_word [NUMBER_OF_BANKS-1:0];
	wire [LOG2_OF_NUMBER_OF_BANKS-1:0] bank;
	wire [NUMBER_OF_BANKS-1:0] write_strobe;
//	wire [NUMBER_OF_BANKS-1:0] read_strobe;
	wire [ERROR_COUNT_PICKOFF:0] hdrb_read_errors;
	wire [ERROR_COUNT_PICKOFF:0] hdrb_write_errors;
	wire [ERROR_COUNT_PICKOFF:0] hdrb_address_errors;
	half_duplex_rpi_bus #(
		.BUS_WIDTH(BUS_WIDTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE),
		.ERROR_COUNT_PICKOFF(ERROR_COUNT_PICKOFF)
	) hdrb (
		.register_select(rpi_gpio[23]), // 0=address;  1=data
		      .ack_valid(rpi_gpio[22]),
		            .bus(rpi_gpio[21:6]),
		           .read(rpi_gpio[5]),  // 0=write;    1=read
		         .enable(rpi_gpio[4]),  // 0=inactive; 1=active
		.write_strobe(write_strobe), .read_strobe(), .bank(bank), .clock(word_clock), .reset(reset_word),
		.write_data_word(write_data_word), .read_data_word(read_data_word[bank]), .address_word_reg(address_word_full),
		.read_errors(hdrb_read_errors), .write_errors(hdrb_write_errors), .address_errors(hdrb_address_errors)
	);
//	wire [ADDRESS_DEPTH_OSERDES-1:0] read_address; // in 8-bit words
	// ----------------------------------------------------------------------
	wire [31:0] bank0 [15:0]; // general settings
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank0 (.clock(word_clock), .reset(reset_word),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[0]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[0]),
		.data_out_b_0(bank0[0]),  .data_out_b_1(bank0[1]),  .data_out_b_2(bank0[2]),  .data_out_b_3(bank0[3]),
		.data_out_b_4(bank0[4]),  .data_out_b_5(bank0[5]),  .data_out_b_6(bank0[6]),  .data_out_b_7(bank0[7]),
		.data_out_b_8(bank0[8]),  .data_out_b_9(bank0[9]),  .data_out_b_a(bank0[10]), .data_out_b_b(bank0[11]),
		.data_out_b_c(bank0[12]), .data_out_b_d(bank0[13]), .data_out_b_e(bank0[14]), .data_out_b_f(bank0[15]));
	wire [7:0] clock_divider_initial_value_for_register_transactions = bank0[0][7:0];
	wire [7:0] max_retries = bank0[1][7:0];
	wire verify_with_shout = bank0[2][0];
	assign spgin = bank0[3][0];
	assign trg_inversion_mask = bank0[4][3:0]; // should be 0xc because the trg45 p/n pair is swapped on the PCB (also trg67)
	wire [LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH-1:0] dual_channel_trigger_width = bank0[5][LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH-1:0];
	wire [LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH-1:0] even_channel_trigger_width = bank0[6][LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH-1:0];
	wire [4:0] hs_data_ss_incr = bank0[7][4:0];
	wire [4:0] hs_data_capture = bank0[8][4:0];
	wire [31:0] timeout = bank0[9];
	wire [LOG2_OF_HS_DAT_BIT_DEPTH-1:0] hs_data_offset = bank0[10][LOG2_OF_HS_DAT_BIT_DEPTH-1:0];
	wire [4:0] hs_data_counter_clear = bank0[11][4:0];
	assign regen = bank0[12][0]; // regulator enable
	wire [7:0] min_tries = bank0[13][7:0];
	wire [7:0] start_address = bank0[14][7:0];
	wire [7:0] end_address   = bank0[15][7:0];
	// ----------------------------------------------------------------------
	wire [31:0] bank1 [15:0]; // status
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank1 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[1]),
		.data_in_b_0(bank1[0]),  .data_in_b_1(bank1[1]),  .data_in_b_2(bank1[2]),  .data_in_b_3(bank1[3]),
		.data_in_b_4(bank1[4]),  .data_in_b_5(bank1[5]),  .data_in_b_6(bank1[6]),  .data_in_b_7(bank1[7]),
		.data_in_b_8(bank1[8]),  .data_in_b_9(bank1[9]),  .data_in_b_a(bank1[10]), .data_in_b_b(bank1[11]),
		.data_in_b_c(bank1[12]), .data_in_b_d(bank1[13]), .data_in_b_e(bank1[14]), .data_in_b_f(bank1[15]),
		.write_strobe_b(1'b1));
	wire [31:0] number_of_register_transactions;
	wire [31:0] number_of_readback_errors;
	wire [19:0] last_erroneous_readback;
	wire [HS_DAT_BIT_DEPTH*(HS_DATA_INTENDED_NUMBER_OF_BITS+1)-1:0] buffered_hs_data_stream;
	wire [7:0] wr_address, wr_address_copy_on_word_clock, wr_address_copy_on_trg_word_clock;
	wire [HS_DATA_INTENDED_NUMBER_OF_BITS-1:0] hs_data_word_decimated;
	assign bank1[0] = { status12_copy_on_word_clock_domain, hdrb_read_errors, hdrb_write_errors, hdrb_address_errors, status8_copy_on_word_clock_domain };
	assign bank1[1] = number_of_register_transactions;
	assign bank1[2] = number_of_readback_errors;
	assign bank1[3][19:0] = last_erroneous_readback; assign bank1[3][31:20] = 0;
	if (5<HS_DAT_BIT_DEPTH && HS_DAT_BIT_DEPTH<9) begin
		assign bank1[4]       = buffered_hs_data_stream[127:96];
		assign bank1[5]       = buffered_hs_data_stream[95:64];
	end else if (HS_DAT_BIT_DEPTH==5) begin
		assign bank1[4][28:0] = buffered_hs_data_stream[124:96]; assign bank1[4][31:29] = 0;
		assign bank1[5]       = buffered_hs_data_stream[95:64];
	end else if (HS_DAT_BIT_DEPTH==4) begin
		assign bank1[4][3:0]  = buffered_hs_data_stream[99:96]; assign bank1[4][31:4] = 0;
		assign bank1[5]       = buffered_hs_data_stream[95:64];
	end else if (HS_DAT_BIT_DEPTH==3) begin
		assign bank1[4]       = 0;
		assign bank1[5][10:0] = buffered_hs_data_stream[74:64]; assign bank1[5][31:11] = 0;
	end
	assign bank1[6] = buffered_hs_data_stream[63:32];
	assign bank1[7] = buffered_hs_data_stream[31:0];
	assign bank1[8][HS_DATA_INTENDED_NUMBER_OF_BITS-1:0] = hs_data_word_decimated[HS_DATA_INTENDED_NUMBER_OF_BITS-1:0]; assign bank1[8][31:HS_DATA_INTENDED_NUMBER_OF_BITS] = 0;
	wire [31:0] convert_counter, done_out_counter;
	wire [31:0] convert_counter_copy_on_word_clock, done_out_counter_copy_on_word_clock;
	assign bank1[9] = convert_counter_copy_on_word_clock;
	assign bank1[10] = done_out_counter_copy_on_word_clock;
	assign bank1[11][7:0] = wr_address_copy_on_word_clock; assign bank1[11][31:8] = 0;
	assign bank1[12] = frequency_of_montiming1;
	assign bank1[13] = frequency_of_montiming2;
	assign bank1[14] = 0;
	assign bank1[15] = 0;
	// ----------------------------------------------------------------------
	wire [15:0] bank2; // things that just need a pulse for 1 clock cycle
	memory_bank_interface_with_pulse_outputs #(.ADDR_WIDTH(4)) pulsed_things_bank2 (.clock(word_clock),
		.address(address_word_full[3:0]), .strobe(write_strobe[2]), .pulse_out(bank2));
	wire clear_channel_counters = bank2[0];
	wire force_write_registers_again = bank2[1];
	assign should_start_wilkinson_conversion_now = bank2[2];
	assign read_data_word[2] = 0;
	// ----------------------------------------------------------------------
	wire [31:0] bank3 [15:0]; // 
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank3 (.clock(word_clock), .reset(reset_word),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[3]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[3]),
		.data_out_b_0(bank3[0]),  .data_out_b_1(bank3[1]),  .data_out_b_2(bank3[2]),  .data_out_b_3(bank3[3]),
		.data_out_b_4(bank3[4]),  .data_out_b_5(bank3[5]),  .data_out_b_6(bank3[6]),  .data_out_b_7(bank3[7]),
		.data_out_b_8(bank3[8]),  .data_out_b_9(bank3[9]),  .data_out_b_a(bank3[10]), .data_out_b_b(bank3[11]),
		.data_out_b_c(bank3[12]), .data_out_b_d(bank3[13]), .data_out_b_e(bank3[14]), .data_out_b_f(bank3[15]));
	// ----------------------------------------------------------------------
	// bank4 = trigger memory
	wire t0, t1, t2, t3, t4, t5, t6, t7;
	irsx_trig_bit_memory_mapper #(.RATIO_OF_TRIG_WORD_CLOCK_TO_SST_CLOCK(4)) trigz (
		.trigword_clock(trg_word_clock), .trigword_reset(trg_reset),
		.t0(t0), .t1(t1), .t2(t2), .t3(t3), .t4(t4), .t5(t5), .t6(t6), .t7(t7),
		.sst_write_address(wr_address_copy_on_trg_word_clock),
		.readout_clock(word_clock), .read_address(address_word_full[9:0]), .data_out(read_data_word[4][7:0]));
	assign read_data_word[4][31:8] = 0;
	// ----------------------------------------------------------------------
	// bank5 = data to read out
	assign read_data_word[5][31:12] = 0;
//	wire [7:0] hs_data_offset_copy_on_hs_clock;
//	pipeline_synchronizer #(.WIDTH(8)) hs_data_offset_copy_on_hs_clock_sync (.clock1(word_clock), .clock2(hs_word_clock), .in1(hs_data_offset), .out2(hs_data_offset_copy_on_hs_clock));
	wire beginning_of_hs_data, beginning_of_hs_data_memory;
	irsx_read_hs_data_from_storage #(.BIT_DEPTH(HS_DAT_BIT_DEPTH), .HS_DATA_INTENDED_NUMBER_OF_BITS(HS_DATA_INTENDED_NUMBER_OF_BITS), .HS_CLK_OSERDES_MODE(HS_CLK_OSERDES_MODE)) hsdo (
		.hs_bit_clk_raw(hs_bit_clk_raw), .hs_word_clock(hs_word_clock), .hs_word_reset(hs_word_reset), .input_pll_locked(third_pll_locked),
		.hs_data_offset(hs_data_offset), .hs_data(hs_data), .beginning_of_hs_data(beginning_of_hs_data), .beginning_of_hs_data_memory(beginning_of_hs_data_memory),
		.hs_data_ss_incr(hs_data_ss_incr), .hs_data_capture(hs_data_capture), .ss_incr(ss_incr), .hs_data_counter_clear(hs_data_counter_clear),
		.hs_clk(hs_clk_OSERDES),
		.hs_pll_is_locked_and_strobe_is_aligned(hs_pll_is_locked_and_strobe_is_aligned),
		.data_out_clock(word_clock),
		.read_address(address_word_full[8:0]), .data_out(read_data_word[5][11:0]),
		.buffered_hs_data_stream(buffered_hs_data_stream),
		.hs_data_word_decimated(hs_data_word_decimated));
	// ----------------------------------------------------------------------
	wire [31:0] bank6 [15:0]; // counter and scalers
	wire scaler_valid, scaler_valid_copy_on_word_clock;
	pipeline_synchronizer scaler_valid_copy_on_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(scaler_valid), .out2(scaler_valid_copy_on_word_clock));
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank6 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[6]),
		.data_in_b_0(bank6[0]),  .data_in_b_1(bank6[1]),  .data_in_b_2(bank6[2]),  .data_in_b_3(bank6[3]),
		.data_in_b_4(bank6[4]),  .data_in_b_5(bank6[5]),  .data_in_b_6(bank6[6]),  .data_in_b_7(bank6[7]),
		.data_in_b_8(bank6[8]),  .data_in_b_9(bank6[9]),  .data_in_b_a(bank6[10]), .data_in_b_b(bank6[11]),
		.data_in_b_c(bank6[12]), .data_in_b_d(bank6[13]), .data_in_b_e(bank6[14]), .data_in_b_f(bank6[15]),
		.write_strobe_b(scaler_valid_copy_on_word_clock));
	wire [COUNTER_WIDTH-1:0] c0, c1, c2, c3, c4, c5, c6, c7;
	wire [COUNTER_WIDTH-1:0] c0_wc, c1_wc, c2_wc, c3_wc, c4_wc, c5_wc, c6_wc, c7_wc;
	wire [SCALER_WIDTH-1:0] sc0, sc1, sc2, sc3, sc4, sc5, sc6, sc7;
	wire [SCALER_WIDTH-1:0] sc0_wc, sc1_wc, sc2_wc, sc3_wc, sc4_wc, sc5_wc, sc6_wc, sc7_wc;
	assign bank6[0][COUNTER_WIDTH-1:0] = c0_wc;
	assign bank6[1][COUNTER_WIDTH-1:0] = c1_wc;
	assign bank6[2][COUNTER_WIDTH-1:0] = c2_wc;
	assign bank6[3][COUNTER_WIDTH-1:0] = c3_wc;
	assign bank6[4][COUNTER_WIDTH-1:0] = c4_wc;
	assign bank6[5][COUNTER_WIDTH-1:0] = c5_wc;
	assign bank6[6][COUNTER_WIDTH-1:0] = c6_wc;
	assign bank6[7][COUNTER_WIDTH-1:0] = c7_wc;
	assign bank6[8][SCALER_WIDTH-1:0]  = sc0_wc; assign bank6[8][31:SCALER_WIDTH]  = 0;
	assign bank6[9][SCALER_WIDTH-1:0]  = sc1_wc; assign bank6[9][31:SCALER_WIDTH]  = 0;
	assign bank6[10][SCALER_WIDTH-1:0] = sc2_wc; assign bank6[10][31:SCALER_WIDTH] = 0;
	assign bank6[11][SCALER_WIDTH-1:0] = sc3_wc; assign bank6[11][31:SCALER_WIDTH] = 0;
	assign bank6[12][SCALER_WIDTH-1:0] = sc4_wc; assign bank6[12][31:SCALER_WIDTH] = 0;
	assign bank6[13][SCALER_WIDTH-1:0] = sc5_wc; assign bank6[13][31:SCALER_WIDTH] = 0;
	assign bank6[14][SCALER_WIDTH-1:0] = sc6_wc; assign bank6[14][31:SCALER_WIDTH] = 0;
	assign bank6[15][SCALER_WIDTH-1:0] = sc7_wc; assign bank6[15][31:SCALER_WIDTH] = 0;
	wire [31:0] timeout_copy_on_trg_word_clock;
	wire clear_channel_counters_copy_on_trg_word_clock;
	wire [LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH-1:0] even_channel_trigger_width_copy_on_trg_word_clock, dual_channel_trigger_width_copy_on_trg_word_clock;
	pipeline_synchronizer #(.WIDTH(32)) timeout_copy_on_trg_word_clock_sync (.clock1(word_clock), .clock2(trg_word_clock), .in1(timeout), .out2(timeout_copy_on_trg_word_clock));
	pipeline_synchronizer clear_channel_counters_copy_on_trg_word_clock_sync (.clock1(word_clock), .clock2(trg_word_clock), .in1(clear_channel_counters), .out2(clear_channel_counters_copy_on_trg_word_clock));
	pipeline_synchronizer #(.WIDTH(LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH)) even_channel_trigger_width_copy_on_trg_word_clock_sync (.clock1(word_clock), .clock2(trg_word_clock), .in1(even_channel_trigger_width), .out2(even_channel_trigger_width_copy_on_trg_word_clock));
	pipeline_synchronizer #(.WIDTH(LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH)) dual_channel_trigger_width_copy_on_trg_word_clock_sync (.clock1(word_clock), .clock2(trg_word_clock), .in1(dual_channel_trigger_width), .out2(dual_channel_trigger_width_copy_on_trg_word_clock));
	irsx_scaler_counter_dual_trigger_interface #(.ISERDES_WIDTH(TRG_BIT_DEPTH), .LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH(LOG2_OF_TRUNCATED_TRIGSTREAM_LENGTH), .COUNTER_WIDTH(COUNTER_WIDTH), .SCALER_WIDTH(SCALER_WIDTH)) irsx_scaler_counter (
		.clock(trg_word_clock), .reset(trg_reset), .clear_channel_counters(clear_channel_counters_copy_on_trg_word_clock), .timeout(timeout_copy_on_trg_word_clock), .scaler_valid(scaler_valid),
//		.trigin0(trig01), .trigin1(trig23), .trigin2(trig45), .trigin3(trig67),
		.iserdes_word_in0(trg01_word), .iserdes_word_in1(trg23_word), .iserdes_word_in2(trg45_word), .iserdes_word_in3(trg67_word),
		.even_channel_trigger_width(even_channel_trigger_width_copy_on_trg_word_clock), .dual_channel_trigger_width(dual_channel_trigger_width_copy_on_trg_word_clock),
		.sc0(sc0), .sc1(sc1), .sc2(sc2), .sc3(sc3), .sc4(sc4), .sc5(sc5), .sc6(sc6), .sc7(sc7),
		.c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7),
		.t0(t0), .t1(t1), .t2(t2), .t3(t3), .t4(t4), .t5(t5), .t6(t6), .t7(t7));
	pipeline_synchronizer #(.WIDTH(COUNTER_WIDTH)) c0_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(c0), .out2(c0_wc));
	pipeline_synchronizer #(.WIDTH(COUNTER_WIDTH)) c1_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(c1), .out2(c1_wc));
	pipeline_synchronizer #(.WIDTH(COUNTER_WIDTH)) c2_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(c2), .out2(c2_wc));
	pipeline_synchronizer #(.WIDTH(COUNTER_WIDTH)) c3_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(c3), .out2(c3_wc));
	pipeline_synchronizer #(.WIDTH(COUNTER_WIDTH)) c4_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(c4), .out2(c4_wc));
	pipeline_synchronizer #(.WIDTH(COUNTER_WIDTH)) c5_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(c5), .out2(c5_wc));
	pipeline_synchronizer #(.WIDTH(COUNTER_WIDTH)) c6_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(c6), .out2(c6_wc));
	pipeline_synchronizer #(.WIDTH(COUNTER_WIDTH)) c7_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(c7), .out2(c7_wc));
	pipeline_synchronizer #(.WIDTH(SCALER_WIDTH)) sc0_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(sc0), .out2(sc0_wc));
	pipeline_synchronizer #(.WIDTH(SCALER_WIDTH)) sc1_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(sc1), .out2(sc1_wc));
	pipeline_synchronizer #(.WIDTH(SCALER_WIDTH)) sc2_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(sc2), .out2(sc2_wc));
	pipeline_synchronizer #(.WIDTH(SCALER_WIDTH)) sc3_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(sc3), .out2(sc3_wc));
	pipeline_synchronizer #(.WIDTH(SCALER_WIDTH)) sc4_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(sc4), .out2(sc4_wc));
	pipeline_synchronizer #(.WIDTH(SCALER_WIDTH)) sc5_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(sc5), .out2(sc5_wc));
	pipeline_synchronizer #(.WIDTH(SCALER_WIDTH)) sc6_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(sc6), .out2(sc6_wc));
	pipeline_synchronizer #(.WIDTH(SCALER_WIDTH)) sc7_word_clock_sync (.clock1(trg_word_clock), .clock2(word_clock), .in1(sc7), .out2(sc7_wc));
	// ----------------------------------------------------------------------
	// bank7 is the register interface
	irsx_register_interface irsx_reg (.clock(word_clock), .reset(reset_word),
		.intended_data_in(write_data_word[11:0]), .intended_data_out(read_data_word[7][11:0]), .readback_data_out(read_data_word[7][23:12]),
		.number_of_transactions(number_of_register_transactions), .force_write_registers_again(force_write_registers_again),
		.number_of_readback_errors(number_of_readback_errors), .last_erroneous_readback(last_erroneous_readback),
		.clock_divider_initial_value_for_register_transactions(clock_divider_initial_value_for_register_transactions),
		.max_retries(max_retries), .min_tries(min_tries), .verify_with_shout(verify_with_shout),
		.address(address_word_full[7:0]), .write_enable(write_strobe[7]),
		.sin(sin), .sclk(sclk), .pclk(pclk), .regclr(regclr), .shout(shout));
	assign read_data_word[7][31:24] = 0;
	// ----------------------------------------------------------------------
	irsx_wilkinson_convert wilkie (.gcc_clock(gcc_clk), .reset(reset_gcc), .should_start_wilkinson_conversion_now(should_start_wilkinson_conversion_now_copy_on_gcc_clk), .convert(convert), .done_out(done_out), .convert_counter(convert_counter), .done_out_counter(done_out_counter));
	pipeline_synchronizer #(.WIDTH(32)) convert_counter_copy_on_word_clock_sync (.clock1(gcc_clk), .clock2(word_clock), .in1(convert_counter), .out2(convert_counter_copy_on_word_clock));
	pipeline_synchronizer #(.WIDTH(32)) done_out_counter_copy_on_word_clock_sync (.clock1(gcc_clk), .clock2(word_clock), .in1(done_out_counter), .out2(done_out_counter_copy_on_word_clock));
	// ----------------------------------------------------------------------
	wire [7:0] start_address_copy_on_wr_clock, end_address_copy_on_wr_clock;
	pipeline_synchronizer #(.WIDTH(8)) start_address_copy_on_wr_clock_sync (.clock1(word_clock), .clock2(wr_word_clk), .in1(start_address), .out2(start_address_copy_on_wr_clock));
	pipeline_synchronizer #(.WIDTH(8)) end_address_copy_on_wr_clock_sync (.clock1(word_clock), .clock2(wr_word_clk), .in1(end_address), .out2(end_address_copy_on_wr_clock));
	irsx_write_to_storage wright (
		.wr_word_clk(wr_word_clk), .wr_bit_clk_raw(wr_bit_clk_raw), .reset(reset_wr), .input_pll_locked(second_pll_locked),
		.revo(1'b0), .wr_syncmon(wr_syncmon), .hold(1'b0), .start_address(start_address_copy_on_wr_clock), .end_address(end_address_copy_on_wr_clock),
		.wr_clk(wr_clk), .wr_dat(wr_dat), .wr_address(wr_address), .wr_pll_is_locked_and_strobe_is_aligned(wr_pll_is_locked_and_strobe_is_aligned));
	pipeline_synchronizer #(.WIDTH(8)) wr_address_copy_on_word_clock_sync (.clock1(wr_word_clk), .clock2(word_clock), .in1(wr_address), .out2(wr_address_copy_on_word_clock));
	pipeline_synchronizer #(.WIDTH(8)) wr_address_copy_on_trg_word_clock_sync (.clock1(wr_word_clk), .clock2(trg_word_clock), .in1(wr_address), .out2(wr_address_copy_on_trg_word_clock));
	// ----------------------------------------------------------------------
	if (0) begin
		assign coax[0] = shout;
		assign coax[1] = pclk;
		assign coax[2] = sclk;
		assign coax[3] = sin;
	end else if (0) begin
		assign coax[0] = wr_syncmon;
		assign coax[1] = 0;//oddr_double_period;
		assign coax[2] = montiming2;
		assign coax[3] = montiming1;
	end else if (0) begin // for tuning wbiases and trg capture parameters
		assign coax[0] = t4;
		assign coax[1] = t5;
		assign coax[2] = trg45;//trg0123;
		assign coax[3] = trg4567;
	end else if (1) begin // to tune parameters to capture hs_data out
		assign coax[0] = beginning_of_hs_data_memory;
		//clock_ODDR_out hs_clk_ODDR_copy (.clock_in_p(hs_word_clock),  .clock_in_n(hs_word_clock180), .clock_enable(1'b1), .clock_out(coax[0]));
		assign coax[1] = beginning_of_hs_data;
		assign coax[2] = ss_incr;
		assign coax[3] = hs_data;
	end else if (1) begin
		//assign coax[0] = ;
		clock_ODDR_out sstclk_ODDR_second_copy  (.clock_in_p(sstclk),  .clock_in_n(sstclk180), .clock_enable(1'b1), .clock_out(coax[0]));
		assign coax[1] = wr_syncmon;
		assign coax[2] = ss_incr;
		assign coax[3] = hs_data;
	end else if (1) begin
		assign coax[0] = wr_syncmon; // this is a 10.6 ns long pulse that repeats with SST (controlled by WR_SYNC_LE/WR_SYNC_TE)
		assign coax[1] = montiming1;
		assign coax[2] = ss_incr;
		assign coax[3] = hs_data;
	end
	//assign coax[4] = shout;
	//assign coax[5] = sclk;
	clock_ODDR_out sstclk_ODDR_second_copy  (.clock_in_p(sstclk),  .clock_in_n(sstclk180), .clock_enable(1'b1), .clock_out(coax[4]));
	assign coax[5] = trgall;
//	assign coax[4] = convert;
//	assign coax[5] = done_out;
	// ----------------------------------------------------------------------
	assign pll_status8[7] = first_pll_locked;
	assign pll_status8[6] = second_pll_locked;
	assign pll_status8[5] = third_pll_locked;
	assign pll_status8[4] = all_plls_locked;
	assign pll_status8[3] = wr_pll_is_locked_and_strobe_is_aligned;
	assign pll_status8[2] = hs_pll_is_locked_and_strobe_is_aligned;
	assign pll_status8[1] = trg_pll_is_locked_and_strobe_is_aligned2;
	assign pll_status8[0] = trg_pll_is_locked_and_strobe_is_aligned1;
	// ----------------------------------------------------------------------
//	assign status4[3] = ~first_pll_locked;
//	assign status4[2] = ~second_pll_locked;
//	assign status4[1] = ~always_clock_reset;
//	assign status4[0] = ~reset_word;
	// -------------------------------------
	assign coax_led = 0;
	assign led = 0;
	initial begin
		#100;
		$display("%d = %d + %d + %d - %d", ADDRESS_DEPTH_OSERDES, BANK_ADDRESS_DEPTH, LOG2_OF_BUS_WIDTH, LOG2_OF_TRANSACTIONS_PER_DATA_WORD, LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH);
		$display("BUS_WIDTH=%d, TRANSACTIONS_PER_DATA_WORD=%d, TRANSACTIONS_PER_ADDRESS_WORD=%d", BUS_WIDTH, TRANSACTIONS_PER_DATA_WORD, TRANSACTIONS_PER_ADDRESS_WORD);
		$display("NUMBER_OF_BANKS=%d", NUMBER_OF_BANKS);
		$display("WR_DAT_BIT_DEPTH=%d", WR_DAT_BIT_DEPTH);
		$display("WR_BIT_CLK_DIVIDE=%d", WR_BIT_CLK_DIVIDE);
		$display("WR_WORD_CLK_DIVIDE=%d", WR_WORD_CLK_DIVIDE);
		$display("TRG_BIT_DEPTH=%d", TRG_BIT_DEPTH);
		$display("TRG_BIT_CLK_DIVIDE=%d", TRG_BIT_CLK_DIVIDE);
		$display("TRG_WORD_CLK_DIVIDE=%d", TRG_WORD_CLK_DIVIDE);
		$display("HS_DAT_BIT_DEPTH=%d", HS_DAT_BIT_DEPTH);
		$display("HS_BIT_CLK_DIVIDE=%d", HS_BIT_CLK_DIVIDE);
		$display("HS_WORD_CLK_DIVIDE=%d", HS_WORD_CLK_DIVIDE);
		$display("GCC_BIT_DEPTH=%d", GCC_BIT_DEPTH);
		$display("GCC_BIT_CLK_DIVIDE=%d", GCC_BIT_CLK_DIVIDE);
		$display("GCC_WORD_CLK_DIVIDE=%d", GCC_WORD_CLK_DIVIDE);
		//$display("=%d", );
	end
endmodule

module TESTBENCH_IRSXtest_tb;
	localparam HALF_PERIOD_OF_CONTROLLER = 1;
	localparam HALF_PERIOD_OF_PERIPHERAL = 10;
	localparam NUMBER_OF_PERIODS_OF_CONTROLLER_IN_A_DELAY = 1;
	localparam NUMBER_OF_PERIODS_OF_CONTROLLER_WHILE_WAITING_FOR_ACK = 2000;
	reg clock = 0;
	localparam BUS_WIDTH = 16;
	localparam ADDRESS_DEPTH = 13;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	reg clock127_p = 0;
	reg clock127_n = 1;
	reg button = 1;
	wire [5:0] coax;
	wire [3:0] coax_led;
	wire [7:0] led;
	reg pre_register_select = 0;
	reg register_select = 0;
	reg pre_read = 0;
	reg read = 0;
	reg [BUS_WIDTH-1:0] pre_bus = 0;
	wire [BUS_WIDTH-1:0] bus;
	reg [BUS_WIDTH-1:0] eye_center = 0;
	reg pre_enable = 0;
	reg enable = 0;
	wire a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p, b_n, b_p, e_n, e_p;
	wire m_p, m_n, l_p, l_n, j_p, j_n, g_p, g_n, k_p, k_n, h_p, h_n;
	wire z, y, x, w, v, u;
	wire n, p, q, r, s, t;
	reg [TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH-1:0] wdata = 0;
	reg [TRANSACTIONS_PER_DATA_WORD*BUS_WIDTH-1:0] rdata = 0;
	bus_entry_3state #(.WIDTH(BUS_WIDTH)) my3sbe (.I(pre_bus), .O(bus), .T(~read)); // we are controller
	IRSXtest #(.BUS_WIDTH(BUS_WIDTH), .ADDRESS_DEPTH(ADDRESS_DEPTH), .TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD), .TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD), .ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE), .TESTBENCH(1)) tbIRSXtest (
		.clock127_p(clock127_p), .clock127_n(clock127_n),
		// .button(button),
		.coax(coax),
		.diff_pair_left({ a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p, b_n, b_p, e_n, e_p }),
		.diff_pair_right({ m_p, m_n, l_p, l_n, j_p, j_n, g_p, g_n, k_p, k_n, h_p, h_n }),
		.single_ended_left({ z, y, x, w, v, u }),
		.single_ended_right({ n, p, q, r, s, t }),
		.bus(bus), .register_select(register_select), .read(read), .enable(enable), .ack_valid(ack_valid),
		.led(led), .coax_led(coax_led)
	);
	task automatic peripheral_clock_delay;
		input integer number_of_cycles;
		integer j;
		begin
			for (j=0; j<2*number_of_cycles; j=j+1) begin : delay_thing_s
				#HALF_PERIOD_OF_PERIPHERAL;
			end
		end
	endtask
	task automatic controller_clock_delay;
		input integer number_of_cycles;
		integer j;
		begin
			for (j=0; j<2*number_of_cycles; j=j+1) begin : delay_thing_m
				#HALF_PERIOD_OF_CONTROLLER;
			end
		end
	endtask
	task automatic delay;
		controller_clock_delay(NUMBER_OF_PERIODS_OF_CONTROLLER_IN_A_DELAY);
	endtask
	task automatic pulse_enable;
		integer i;
		integer j;
		begin
			i = 0;
			//delay();
			//eye_center <= 0;
			pre_enable <= 1;
			for (j=0; j<2*NUMBER_OF_PERIODS_OF_CONTROLLER_WHILE_WAITING_FOR_ACK; j=j+1) begin : delay_thing_1
				if (ack_valid) begin
					//if (0==i) begin
					//	$display("ack_valid seen after %d half-periods", j); // 421, 423, 427
					//end
					if (2==i) begin
						eye_center <= bus;
						//$display("%t bus=%08x", $time, bus);
					end
					i = i + 1;
					j = 2*NUMBER_OF_PERIODS_OF_CONTROLLER_WHILE_WAITING_FOR_ACK - 100;
				end
				if (64<i) begin
					pre_enable <= 0;
				end
				#HALF_PERIOD_OF_CONTROLLER;
			end
			//$display("ending i: %d", i); // 480
			if (pre_enable==1) begin
				//$display(“pre_enable is still 1”);
				$finish;
			end
		end
	endtask
	task automatic a16_d32_controller_write_transaction;
		input [15:0] address16;
		input [31:0] data32;
		begin
			controller_set_address16(address16);
			controller_write_data32(data32);
		end
	endtask
	task automatic a16_controller_read_transaction;
		input [15:0] address16;
		integer j;
		begin
			controller_set_address16(address16);
		end
	endtask
	task automatic controller_set_address16;
		input [15:0] address16;
		integer j;
		begin
			delay();
			// set each part of address
			pre_read <= 0;
			pre_register_select <= 0; // register_select=0 is address
//			if (1<TRANSACTIONS_PER_ADDRESS_WORD) begin : set_address_multiple
//				pre_bus <= address16[2*BUS_WIDTH-1:BUS_WIDTH];
//				pulse_enable();
//			end
			pre_bus <= address16[BUS_WIDTH-1:0];
			pulse_enable();
			delay();
			$display("%t address: %04x", $time, address16);
		end
	endtask
	task automatic controller_write_data32;
		input [31:0] data32;
		integer j;
		begin
			//wdata <= 0;
			delay();
			//wdata <= data32;
			// write each part of data
			pre_read <= 0;
			pre_register_select <= 1; // register_select=1 is data
			if (3<TRANSACTIONS_PER_DATA_WORD) begin
				pre_bus <= data32[4*BUS_WIDTH-1:3*BUS_WIDTH];
				pulse_enable();
				wdata[4*BUS_WIDTH-1:3*BUS_WIDTH] <= eye_center;
			end
			if (2<TRANSACTIONS_PER_DATA_WORD) begin
				pre_bus <= data32[3*BUS_WIDTH-1:2*BUS_WIDTH];
				pulse_enable();
				wdata[3*BUS_WIDTH-1:2*BUS_WIDTH] <= eye_center;
			end
			if (1<TRANSACTIONS_PER_DATA_WORD) begin
				pre_bus <= data32[2*BUS_WIDTH-1:BUS_WIDTH];
				pulse_enable();
				wdata[2*BUS_WIDTH-1:BUS_WIDTH] <= eye_center;
			end
			pre_bus <= data32[BUS_WIDTH-1:0];
			pulse_enable();
			wdata[BUS_WIDTH-1:0] <= eye_center;
			delay();
			$display("%t wdata: %08x", $time, wdata);
		end
	endtask
	task automatic controller_read_data32;
		integer j;
		begin
			//rdata <= 0;
			delay();
			// read each part of data
			pre_read <= 1;
			pre_register_select <= 1; // register_select=1 is data
			for (j=TRANSACTIONS_PER_DATA_WORD-1; j>=0; j=j-1) begin : read_data_multiple_2
				pulse_enable();
				if (3==j) begin
					rdata[4*BUS_WIDTH-1:3*BUS_WIDTH] <= eye_center;
					//$display("%d %08x %08x", j, eye_center, rdata);
				end else if (2==j) begin
					rdata[3*BUS_WIDTH-1:2*BUS_WIDTH] <= eye_center;
					//$display("%d %08x %08x", j, eye_center, rdata);
				end else if (1==j) begin
					rdata[2*BUS_WIDTH-1:BUS_WIDTH] <= eye_center;
					//$display("%d %08x %08x", j, eye_center, rdata);
				end else begin
					rdata[BUS_WIDTH-1:0] <= eye_center;
					//$display("%d %08x %08x", j, eye_center, rdata);
				end
			end
			delay();
			//pre_read <= 0;
			$display("%t rdata: %08x", $time, rdata);
		end
	endtask
	initial begin
		// inject global reset
		#300; button <= 0; #300; button <= 1;
		#512; // wait for always_clock_reset
		#512; // wait for reset125
		//#300; button <= 0; #300; button <= 1;
		//#512; // wait for always_clock_reset
		//#512; // wait for reset125
		// test the interface
		if (ADDRESS_AUTOINCREMENT_MODE) begin
			// write some data to some addresses
			controller_clock_delay(64);
			peripheral_clock_delay(64);
			controller_set_address16(16'h_2b4c);
			controller_write_data32(32'h_3123_1507);
			controller_write_data32(32'h_3123_1508);
			controller_write_data32(32'h_3123_1509);
			controller_write_data32(32'h_3123_150a);
			// read back from those addresses
			controller_clock_delay(64);
			peripheral_clock_delay(64);
			controller_set_address16(16'h_2b4c);
			controller_read_data32();
			controller_read_data32();
			controller_read_data32();
			controller_read_data32();
		end else begin
			// write some data to some addresses
			controller_clock_delay(64);
			peripheral_clock_delay(64);
			a16_d32_controller_write_transaction(.address16(16'h2b4c), .data32(32'h3123_1507));
			controller_read_data32();
			a16_d32_controller_write_transaction(.address16(16'h2b4d), .data32(32'h3123_1508));
			controller_read_data32();
			a16_d32_controller_write_transaction(.address16(16'h2b4e), .data32(32'h3123_1509));
			controller_read_data32();
			a16_d32_controller_write_transaction(.address16(16'h2b4f), .data32(32'h3123_150a));
			controller_read_data32();
			// read back from those addresses
			controller_clock_delay(64);
			peripheral_clock_delay(64);
			a16_controller_read_transaction(.address16(16'h2b4c));
			a16_controller_read_transaction(.address16(16'h2b4d));
			a16_controller_read_transaction(.address16(16'h2b4e));
			a16_controller_read_transaction(.address16(16'h2b4f));
		end
		// write the two checksum words to the memory
		//controller_clock_delay(64);
		//peripheral_clock_delay(64);
		//a16_d32_controller_write_transaction(.address16(16'h1234), .data32(32'h3123_1507));
		//controller_read_data32();
		//a16_d32_controller_write_transaction(.address16(16'h3412), .data32(32'h0000_1507));
		//controller_read_data32();
		//pre_register_select <= 0;
		// now mess things up
		// inject read error:
		controller_clock_delay(64);
		peripheral_clock_delay(64);
		pre_register_select <= 1;
		pre_read <= 1;
		pre_bus <= 8'h33;
		pulse_enable();
		controller_set_address16(16'h1b4f);
		controller_read_data32();
		// inject write error:
		controller_clock_delay(64);
		peripheral_clock_delay(64);
		pre_register_select <= 1;
		pre_read <= 0;
		pre_bus <= 8'h66;
		pulse_enable();
		controller_set_address16(16'h4f1b);
		controller_write_data32(32'h3123_2d78);
		// inject address error:
		controller_clock_delay(64);
		peripheral_clock_delay(64);
		pre_register_select <= 0; // register_select=0 is address
		pre_read <= 0;
		pre_bus <= 8'h99;
		pulse_enable();
		controller_set_address16(16'h1b4f);
		controller_read_data32();
		// clear all signals
		pre_register_select <= 0;
		pre_read <= 0;
		pre_enable <= 0;
		// inject global reset
		controller_clock_delay(64);
		peripheral_clock_delay(64);
		#300; button <= 0; #300; button <= 1;
		#300;
		//$finish;
	end
	always @(posedge clock) begin
		register_select <= #1 pre_register_select;
		read <= #1 pre_read;
		enable <= #1 pre_enable;
	end
	always begin
		#HALF_PERIOD_OF_PERIPHERAL;
		clock127_p <= #1.5 ~clock127_p;
		clock127_n <= #2.5 ~clock127_n;
	end
	always begin
		#HALF_PERIOD_OF_CONTROLLER;
		clock <= #0.625 ~clock;
	end
endmodule

module altheaIRSXtest #(
	parameter NOTHING = 0
) (
	input clock127_p, clock127_n,
	inout [5:0] coax,
	// other IOs:
	inout [23:4] rpi_gpio,
	// toupee connectors:
	input
	a_p, b_p, g_p, j_p, k_p, m_p,
	a_n, b_n, g_n, j_n, k_n, m_n, 
	n, p, q, w,
//	z, v, // copies of sda and scl
	output
	c_p, c_n, d_p, d_n, e_p, e_n, f_p, f_n, h_p, h_n, l_p, l_n,
	r, s, t, x, y,
	u, // regen = regulator enable
	//input [2:0] rot
//	input scl, sda,
//	output dummy1, dummy2,
	input button, // reset
//	output other, // goes to PMOD connector
	output [7:0] led,
	output [3:0] coax_led
);
	localparam BUS_WIDTH = 16;
	localparam BANK_ADDRESS_DEPTH = 13;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	wire regen;
	// irsx pin names:
	wire sclk, sin, pclk, shout, regclr;
	wire montiming2, done_out, wr_syncmon, spgin, ss_incr, convert;
	// irsx pin mapping:
	assign y = sclk;
	assign x = regclr;
	assign shout = w;
	assign c_n = sin;
	assign c_p = pclk;
	assign montiming2 = n;
	assign done_out = p;
	assign wr_syncmon = q;
	assign r = spgin;
	assign s = ss_incr;
	assign t = convert;
	assign u = regen; // regulator enable
//	assign dummy1 = sda;
//	assign dummy2 = scl;
	IRSXtest #(
		.TESTBENCH(0),
		.BUS_WIDTH(BUS_WIDTH), .BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) IRSXtest (
		.clock127_p(clock127_p), .clock127_n(clock127_n),
		.button(button),
		.coax(coax),
		.sin(sin), .sclk(sclk), .pclk(pclk), .regclr(regclr), .shout(shout),
		.sstclk_p(l_p), .hs_clk_p(h_p), .gcc_clk_p(f_p), .wr_clk_p(d_p), .wr_dat_p(e_p),
		.sstclk_n(l_n), .hs_clk_n(h_n), .gcc_clk_n(f_n), .wr_clk_n(d_n), .wr_dat_n(e_n),
		.data_p(g_p), .trg01_p(m_p), .trg23_p(k_p), .trg45_p(a_p), .trg67_p(b_p), // pins are swapped on PCB for trg45 and trg67
		.data_n(g_n), .trg01_n(m_n), .trg23_n(k_n), .trg45_n(a_n), .trg67_n(b_n), // pins are swapped on PCB for trg45 and trg67
		.convert(convert), .done_out(done_out), .ss_incr(ss_incr), .wr_syncmon(wr_syncmon), .spgin(spgin),
		.montiming1_p(j_p), .montiming1_n(j_n), .montiming2(montiming2),
		.regen(regen),
		.rpi_gpio(rpi_gpio[23:4]),
//		.rot(rot),
//		.other(other),
		.led(led),
		.coax_led(coax_led)
	);
endmodule

