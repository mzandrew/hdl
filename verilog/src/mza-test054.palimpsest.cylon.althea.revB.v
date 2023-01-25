// written 2021-12-14 by mza
// based on mza-test053.simple-parallel-interface-and-pollable-memory.6bit-oserdes-R2R-ladder-DAC.althea.revB.v
// and based on mza-test056.palimpsest.cylon.althea.revA.v
// last updated 2022-12-02 by mza

`define althea_revB
`include "lib/generic.v"
`include "lib/RAM8.v"
//`include "lib/RAM.sv" // ise does not and will not support systemverilog
`include "lib/plldcm.v"
`include "lib/serdes_pll.v"
`include "lib/half_duplex_rpi_bus.v"
`include "lib/sequencer.v"
`include "lib/reset.v"
`include "lib/edge_to_pulse.v"

module top #(
	parameter BUS_WIDTH = 16,
	parameter LOG2_OF_BUS_WIDTH = $clog2(BUS_WIDTH),
	parameter TRANSACTIONS_PER_DATA_WORD = 2,
	parameter LOG2_OF_TRANSACTIONS_PER_DATA_WORD = $clog2(TRANSACTIONS_PER_DATA_WORD),
	parameter OSERDES_DATA_WIDTH = 8,
	parameter LOG2_OF_OSERDES_DATA_WIDTH = $clog2(OSERDES_DATA_WIDTH),
	parameter TRANSACTIONS_PER_ADDRESS_WORD = 1,
	parameter BANK_ADDRESS_DEPTH = 13,
	parameter LOG2_OF_NUMBER_OF_BANKS = BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD - BANK_ADDRESS_DEPTH,
	parameter NUMBER_OF_BANKS = 1<<LOG2_OF_NUMBER_OF_BANKS,
	parameter LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH = $clog2(64),
	parameter ADDRESS_DEPTH_OSERDES = BANK_ADDRESS_DEPTH + LOG2_OF_BUS_WIDTH + LOG2_OF_TRANSACTIONS_PER_DATA_WORD - LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH,
	parameter ADDRESS_AUTOINCREMENT_MODE = 1,
//	parameter RIGHT_DAC_OUTER = 1,
//	parameter LEFT_DAC_OUTER = 1,
//	parameter LEFT_DAC_ROTATED = 0,
//	parameter RIGHT_DAC_INNER = 1,
//	parameter LEFT_DAC_INNER = 1,
	parameter TESTBENCH = 0,
	parameter COUNTER_PICKOFF = TESTBENCH ? 6 : $clog2(2500000) - LOG2_OF_OSERDES_DATA_WIDTH, // 25 MHz / 2^23 ~ 23 Hz
	parameter COUNTER_SIZE = COUNTER_PICKOFF + 3,
	parameter COUNTER100_BIT_PICKOFF = TESTBENCH ? 5 : 23,
	parameter COUNTERWORD_BIT_PICKOFF = TESTBENCH ? 5 : 23
) (
	input clock50_p, clock50_n,
	input clock10,
	input button,
	inout [5:0] coax,
//	input [2:0] rot,
	inout [BUS_WIDTH-1:0] bus,
	input read, // 0=write; 1=read
	input register_select, // 0=address; 1=data
	input enable, // 1=active; 0=inactive
	output ack_valid,
	output [12:1] signal,
	output [12:1] indicator,
//	output [5:0] diff_pair_left,
//	output [5:0] diff_pair_right_p,
//	output [5:0] diff_pair_right_n,
//	output [5:0] single_ended_left,
//	output [5:0] single_ended_right,
//	output [7-LEFT_DAC_OUTER*4:4-LEFT_DAC_OUTER*4] led,
	output [3:0] coax_led
);
	// PLL_ADV VCO range is 400 MHz to 1080 MHz
	localparam PERIOD = 10.0;
	//localparam MULTIPLY = 9; // 900 MHz
	//localparam DIVIDE = 1; // 900 MHz
	//localparam EXTRA_DIVIDE = 3; // 300 MHz
	//localparam MULTIPLY = 8; // 800 MHz
	//localparam DIVIDE = 2; // 400 MHz
	//localparam EXTRA_DIVIDE = 16; // 25 MHz
	localparam MULTIPLY = 8; // 800 MHz bit_clock
	localparam DIVIDE = 2; // 400 MHz bit_clock; 50 MHz word_clock
	//localparam EXTRA_DIVIDE = 7; // 142.857143 MHz (7ns bit time); 
	//localparam EXTRA_DIVIDE = 16; // 25 MHz bit_clock (40ns bit time); 3.125 MHz word_clock
	localparam EXTRA_DIVIDE = 3; // 133.33 MHz bit_clock (7.5ns bit time); 16.67 MHz word_clock
	//localparam EXTRA_DIVIDE = 2; // 200 MHz bit_clock (5ns bit time); 25 MHz word_clock
	localparam SCOPE = "BUFPLL"; // "GLOBAL" (400 MHz), "BUFIO2" (525 MHz), "BUFPLL" (1080 MHz)
	reg [7:0] pattern [12:1];
	wire [7:0] null = 0;
	//wire [7:0] pat [COUNTER_SIZE-COUNTER_PICKOFF-1:0] = { 8'b11111111, 8'b11111110, 8'b11111100, 8'b11111000, 8'b11110000, 8'b11100000, 8'b11000000, 8'b10000000 };
	wire [7:0] pat [COUNTER_SIZE-COUNTER_PICKOFF-1:0] = { 8'b11111111, 8'b11111111, 8'b11111111, 8'b11111111, 8'b11111111, 8'b11111111, 8'b11111111, 8'b11111111 };
	wire [3:0] status4;
	wire [7:0] status8;
	wire reset;
	reg [7:0] sync_out_word_alternate = 0;
	genvar i;
	reg [COUNTER_SIZE:0] counter = 0;
	wire word_clock;
	wire reset_word;
	always @(posedge word_clock) begin
		if (reset_word) begin
			counter <= 0;
		end else begin
			counter <= counter + 1'b1;
		end
	end
	always @(posedge word_clock) begin
//		for (i=1; i<13; i=i+1) begin : clear_pattern
		pattern[1] <= null;
		pattern[2] <= null;
		pattern[3] <= null;
		pattern[4] <= null;
		pattern[5] <= null;
		pattern[6] <= null;
		pattern[7] <= null;
		pattern[8] <= null;
		pattern[9] <= null;
		pattern[10] <= null;
		pattern[11] <= null;
		pattern[12] <= null;
		sync_out_word_alternate <= null;
//		end
		if (reset_word) begin
		end else begin
			if (counter[COUNTER_PICKOFF:0]==1) begin
				sync_out_word_alternate <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
				pattern[1] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==2) begin
				pattern[2] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==3) begin
				pattern[3] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==4) begin
				pattern[4] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==5) begin
				pattern[5] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==6) begin
				pattern[6] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==7) begin
				pattern[7] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==8) begin
				pattern[8] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==9) begin
				pattern[9] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==10) begin
				pattern[10] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==11) begin
				pattern[11] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
//			end else if (counter[COUNTER_PICKOFF:0]==12) begin
				pattern[12] <= pat[counter[COUNTER_SIZE:COUNTER_PICKOFF+1]];
			end
		end
	end
	wire pll_oserdes_locked;
	// ----------------------------------------------------------------------
	wire clock100;
	wire clock50_locked;
	wire reset100;
	if (1) begin // on boards with 50 MHz oscillator
		wire clock50_raw;
		IBUFGDS mybuf50_raw1 (.I(clock50_p), .IB(clock50_n), .O(clock50_raw));
		wire clock100_raw;
		simpledcm_CLKGEN #(.MULTIPLY(2), .DIVIDE(1), .PERIOD(20.0)) mydcm50 (.clockin(clock50_raw), .reset(reset), .clockout(clock100_raw), .clockout180(), .locked(clock50_locked));
		BUFG mybuf50_raw2 (.I(clock100_raw), .O(clock100));
		reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset100_wait4pll (.reset_input(reset), .pll_locked_input(clock50_locked), .clock_input(clock100), .reset_output(reset100));
	end else begin // on boards with 100 MHz oscillator
		wire clock100_locked;
//		IBUFGDS mybuf0 (.I(clock100_p), .IB(clock100_n), .O(clock100));
		dummy_dcm_diff_input lollipop (.clock_p(clock100_p), .clock_n(clock100_n), .reset(reset), .clock_out(clock100), .clock_locked(clock100_locked));
		reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset100_wait4pll (.reset_input(reset), .pll_locked_input(clock100_locked), .clock_input(clock100), .reset_output(reset100));
	end
	// ----------------------------------------------------------------------
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset_input(reset100), .pll_locked_input(pll_oserdes_locked), .clock_input(word_clock), .reset_output(reset_word));
	// ----------------------------------------------------------------------
	wire [BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD-1:0] address_word_full;
	wire [BANK_ADDRESS_DEPTH-1:0] address_word_narrow = address_word_full[BANK_ADDRESS_DEPTH-1:0];
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] write_data_word;
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] read_data_word [NUMBER_OF_BANKS-1:0];
	wire [LOG2_OF_NUMBER_OF_BANKS-1:0] bank;
	wire [LOG2_OF_NUMBER_OF_BANKS-1:0] write_strobe;
	localparam ERROR_COUNT_PICKOFF = 7;
	wire [ERROR_COUNT_PICKOFF:0] hdrb_read_errors;
	wire [ERROR_COUNT_PICKOFF:0] hdrb_write_errors;
	wire [ERROR_COUNT_PICKOFF:0] hdrb_address_errors;
	half_duplex_rpi_bus #(
		.BUS_WIDTH(BUS_WIDTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) hdrb (
		.clock(word_clock),
		.reset(reset_word),
		.bus(bus),
		.read(read), // 0=write; 1=read
		.register_select(register_select), // 0=address; 1=data
		.enable(enable), // 1=active; 0=inactive
		.ack_valid(ack_valid),
		.write_strobe(write_strobe),
		.write_data_word(write_data_word),
		.read_data_word(read_data_word[bank]),
		.address_word_reg(address_word_full),
		.read_errors(hdrb_read_errors),
		.write_errors(hdrb_write_errors),
		.address_errors(hdrb_address_errors),
		.bank(bank)
	);
	wire [OSERDES_DATA_WIDTH-1:0] potential_oserdes_word [NUMBER_OF_BANKS-1:0];
	wire [OSERDES_DATA_WIDTH-1:0] oserdes_word [NUMBER_OF_BANKS-1:0];
	wire [ADDRESS_DEPTH_OSERDES-1:0] read_address; // in 8-bit words
	wire [31:0] a_c_;
	wire [31:0] _b_d;
	RAM_s6_8k_16bit_32bit mem0 (.reset(reset_word),
		.clock_a(word_clock), .address_a(address_word_narrow), .data_in_a(write_data_word[15:0]), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0][15:0]),
		.clock_b(word_clock), .address_b(read_address), .data_out_b(_b_d));
	RAM_s6_8k_16bit_32bit mem1 (.reset(reset_word),
		.clock_a(word_clock), .address_a(address_word_narrow), .data_in_a(write_data_word[31:16]), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0][31:16]),
		.clock_b(word_clock), .address_b(read_address), .data_out_b(a_c_));
	wire [63:0] oserdes_word64;
	assign oserdes_word64[63:48] = a_c_[31:16];
	assign oserdes_word64[47:32] = _b_d[31:16];
	assign oserdes_word64[31:16] = a_c_[15:0];
	assign oserdes_word64[15:0 ] = _b_d[15:0];
	wire [OSERDES_DATA_WIDTH-1:0] preDACbit [7:0]; // preDACbit[i] is an 8 bit word giving the next 8 timeseries values [7 downto 0] for bit i of the DAC output
	for (i=0; i<8; i=i+1) begin : preDACbit_mapping
		// bit0 -> 56, 48, 40, 32, 24, 16, 8, 0
		// bit7 -> 63, 55, 47, 39, 31, 23, 15, 7
		assign preDACbit[i] = { oserdes_word64[8*7+i], oserdes_word64[8*6+i], oserdes_word64[8*5+i], oserdes_word64[8*4+i],
		                        oserdes_word64[8*3+i], oserdes_word64[8*2+i], oserdes_word64[8*1+i], oserdes_word64[8*0+i] };
	end
	wire [OSERDES_DATA_WIDTH-1:0] DACvalue [7:0]; // DACvalue[i] for i=7 downto 0 is a timeseries of 8 bit DAC values
	wire [OSERDES_DATA_WIDTH-1:0] DACvaluePRIME [7:0]; // delayed version of DACvalue
	for (i=0; i<8; i=i+1) begin : DACvalue_mapping
		assign DACvalue[i] = {
			preDACbit[7][i], preDACbit[6][i], preDACbit[5][i], preDACbit[4][i], 
			preDACbit[3][i], preDACbit[2][i], preDACbit[1][i], preDACbit[0][i] };
	end
	wire [OSERDES_DATA_WIDTH-1:0] minuend;
	wire [OSERDES_DATA_WIDTH-1:0] difference [7:0];
	localparam DEPTH = 4;
	for (i=0; i<8; i=i+1) begin : arithmetic_pipeline_mapping
		arithmetic_pipeline #(.WIDTH(OSERDES_DATA_WIDTH), .DEPTH(DEPTH)) ap (.clock(word_clock), .minuend(minuend), .subtrahend(DACvalue[i]), .difference(difference[i]));
		pipeline #(.WIDTH(OSERDES_DATA_WIDTH), .DEPTH(DEPTH)) pl (.clock(word_clock), .in(DACvalue[i]), .out(DACvaluePRIME[i]));
	end
	wire [OSERDES_DATA_WIDTH-1:0] DACbit [7:0];
	wire [OSERDES_DATA_WIDTH-1:0] DACbitN [7:0];
	for (i=0; i<8; i=i+1) begin : DACbit_mapping
		assign DACbit[i] = {
			DACvaluePRIME[7][i], DACvaluePRIME[6][i], DACvaluePRIME[5][i], DACvaluePRIME[4][i], 
			DACvaluePRIME[3][i], DACvaluePRIME[2][i], DACvaluePRIME[1][i], DACvaluePRIME[0][i] };
		assign DACbitN[i] = {
			difference[7][i], difference[6][i], difference[5][i], difference[4][i], 
			difference[3][i], difference[2][i], difference[1][i], difference[0][i] };
	end
	for (i=3; i<NUMBER_OF_BANKS; i=i+1) begin : fakebanks
		assign read_data_word[i] = 0;
	end
	assign potential_oserdes_word[0] = DACbit[7];
	for (i=1; i<NUMBER_OF_BANKS; i=i+1) begin : banksfake
		assign potential_oserdes_word[i] = 0;
	end
	wire [31:0] bank1 [15:0];
	wire [31:0] bank2 [15:0];
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank1 (.clock(word_clock),
		//.reset(reset_word),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[1]),
		.data_in_b_0(bank1[0]),  .data_in_b_1(bank1[1]),  .data_in_b_2(bank1[2]),  .data_in_b_3(bank1[3]),
		.data_in_b_4(bank1[4]),  .data_in_b_5(bank1[5]),  .data_in_b_6(bank1[6]),  .data_in_b_7(bank1[7]),
		.data_in_b_8(bank1[8]),  .data_in_b_9(bank1[9]),  .data_in_b_a(bank1[10]), .data_in_b_b(bank1[11]),
		.data_in_b_c(bank1[12]), .data_in_b_d(bank1[13]), .data_in_b_e(bank1[14]), .data_in_b_f(bank1[15]),
		.write_strobe_b(1'b1));
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank2 (.clock(word_clock), .reset(reset_word),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[2]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[2]),
		.data_out_b_0(bank2[0]),  .data_out_b_1(bank2[1]),  .data_out_b_2(bank2[2]),  .data_out_b_3(bank2[3]),
		.data_out_b_4(bank2[4]),  .data_out_b_5(bank2[5]),  .data_out_b_6(bank2[6]),  .data_out_b_7(bank2[7]),
		.data_out_b_8(bank2[8]),  .data_out_b_9(bank2[9]),  .data_out_b_a(bank2[10]), .data_out_b_b(bank2[11]),
		.data_out_b_c(bank2[12]), .data_out_b_d(bank2[13]), .data_out_b_e(bank2[14]), .data_out_b_f(bank2[15]));
//	assign pll_oserdes_locked = pll_oserdes_locked_other && pll_oserdes_locked_right_outer && pll_oserdes_locked_left_outer && pll_oserdes_locked_right_inner && pll_oserdes_locked_left_inner;
//	assign coax[0] = 0;
//	assign coax[1] = 0;
//	assign coax[2] = 0;
//	assign coax[3] = 0;
//	assign coax[5] = sync_out_stream[SYNC_OUT_STREAM_PICKOFF];
	wire sync_read_address; // assert this when you feel like (re)synchronizing
	localparam SYNC_OUT_STREAM_PICKOFF = 2;
	wire [SYNC_OUT_STREAM_PICKOFF:0] sync_out_stream; // sync_out_stream[2] is usually good
	wire [7:0] sync_out_word; // dump this in to one of the outputs in a multi-lane oserdes module to get a sync bit that is precisely aligned with your data
	wire [7:0] sync_out_word_delayed; // dump this in to one of the outputs in a multi-lane oserdes module to get a sync bit that is precisely aligned with your data
//	wire [2:0] rot_pipeline;
	assign bank1[0]  = { oserdes_word[3], oserdes_word[2], oserdes_word[1], oserdes_word[0] };
	assign bank1[1]  = 0;
	assign bank1[2]  = 0;
	assign bank1[3]  = hdrb_read_errors;
	assign bank1[4]  = hdrb_write_errors;
	assign bank1[5]  = hdrb_address_errors;
	assign bank1[6]  = { 16'd0, 4'd0, status4, status8 };
	assign bank1[7]  = 0;
	assign bank1[8]  = 0;
	assign bank1[9]  = 0;
	assign bank1[10] = 0;
	assign bank1[11] = 0;
	assign bank1[12] = 0;
	assign bank1[13] = 0;
	assign bank1[14] = 0;
	assign bank1[15] = 0;
	(* KEEP = "TRUE" *)
	assign      minuend                   = bank2[0][7:0];
	wire        train_oserdes             = bank2[4][0];
	wire  [7:0] train_oserdes_pattern     = bank2[5][7:0];
	wire [31:0] start_sample              = bank2[6][31:0];
	wire [31:0] end_sample                = bank2[7][31:0];
	assign reset = 0;
	wire [7:0] iserdes_word_raw;
	// the order here is 12, 11, 10, 6, 5, 4, 9, 8, 7, 3, 2, 1
	wire [7:0] dummy = 0;
	wire strobe_is_alignedA, strobe_is_alignedB, strobe_is_alignedC, strobe_is_alignedD;
	ocyrus_triacontahedron8_split_12_6_6_4_2_D0input #(
		.BIT_DEPTH(8), .PERIOD(PERIOD), .MULTIPLY(MULTIPLY), .DIVIDE(DIVIDE), .EXTRA_DIVIDE(EXTRA_DIVIDE), .SCOPE(SCOPE)
	) orama (
		.clock_in(clock100), .reset(reset100),
		.word_A11_in(dummy), .word_A10_in(dummy), .word_A09_in(dummy), .word_A08_in(dummy), .word_A07_in(dummy), .word_A06_in(dummy),
		.word_A05_in(dummy), .word_A04_in(dummy), .word_A03_in(dummy), .word_A02_in(dummy), .word_A01_in(dummy), .word_A00_in(dummy),
		.word_B5_in(pattern[12]), .word_B4_in(pattern[11]), .word_B3_in(pattern[10]), .word_B2_in(pattern[6]), .word_B1_in(pattern[5]), .word_B0_in(pattern[4]),
		.word_C5_in(pattern[9]), .word_C4_in(pattern[8]), .word_C3_in(pattern[7]), .word_C2_in(pattern[3]), .word_C1_in(pattern[2]), .word_C0_in(pattern[1]),
		.word_D3_in(dummy), .word_D2_in(dummy), .word_D1_in(dummy), .word_D0_out(),
		.word_E1_in(dummy), .word_E0_in(sync_out_word_alternate),
		.word_clockA_out(word_clock), .word_clockB_out(), .word_clockC_out(), .word_clockD_out(), .word_clockE_out(),
		.A11_out(), .A10_out(), .A09_out(), .A08_out(), .A07_out(), .A06_out(),
		.A05_out(), .A04_out(), .A03_out(), .A02_out(), .A01_out(), .A00_out(),
		.B5_out(signal[12]), .B4_out(signal[11]), .B3_out(signal[10]), .B2_out(signal[6]), .B1_out(signal[5]), .B0_out(signal[4]),
		.C5_out(signal[9]), .C4_out(signal[8]), .C3_out(signal[7]), .C2_out(signal[3]), .C1_out(signal[2]), .C0_out(signal[1]),
		.D3_out(coax[3]), .D2_out(coax[2]), .D1_out(coax[1]), .D0_in(coax[0]),
		.E1_out(coax[5]), .E0_out(coax[4]),
		.strobe_is_alignedA(strobe_is_alignedA), .strobe_is_alignedB(strobe_is_alignedB), .strobe_is_alignedC(strobe_is_alignedC), .strobe_is_alignedD(strobe_is_alignedD),
		.locked(pll_oserdes_locked)
	);
	for (i=0; i<NUMBER_OF_BANKS; i=i+1) begin : train_or_regular
		assign oserdes_word[i] = train_oserdes ? train_oserdes_pattern : potential_oserdes_word[i];
	end
//	assign coax[1] = 0; // because coax[1] is on same pin pair as gpio17 on althea revB
//	assign coax[2] = 0; // because coax[2] is on same pin pair as gpio12 on althea revB
//	assign coax[5] = 0; // because coax[5] is on same pin pair as p on althea revB
	sequencer_sync #(.ADDRESS_DEPTH_OSERDES(ADDRESS_DEPTH_OSERDES), .LOG2_OF_OSERDES_DATA_WIDTH(LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH), .SYNC_OUT_STREAM_PICKOFF(SYNC_OUT_STREAM_PICKOFF)) ss (.clock(word_clock), .reset(reset_word), .sync_read_address(sync_read_address), .start_sample(start_sample), .end_sample(end_sample), .read_address(read_address), .sync_out_stream(sync_out_stream), .sync_out_word(sync_out_word));
	if (0) begin // to test the rpi interface to the read/write pollable memory
		assign coax[4] = enable; // scope trigger
//		assign coax[0] = write_strobe[0];
		assign pll_oserdes_locked_other = 1;
	end else if (0) begin // to put the oserdes outputs on coax[4] and coax[0]
		ocyrus_double8 #(.BIT_DEPTH(8), .PERIOD(PERIOD), .MULTIPLY(MULTIPLY), .DIVIDE(DIVIDE), .SCOPE(SCOPE), .EXTRA_DIVIDE(EXTRA_DIVIDE)) mylei2 (
			.clock_in(clock100), .reset(reset100), .word_clock_out(),
			.word1_in(oserdes_word[0]), .D1_out(coax[0]),
			.word0_in(oserdes_word[0]), .D0_out(coax[4]),
			.bit_clock(), .bit_strobe(),
			.locked(pll_oserdes_locked_other));
		assign sync_read_address = 0;
	end else if (0) begin
		ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(PERIOD), .MULTIPLY(MULTIPLY), .DIVIDE(DIVIDE), .SCOPE(SCOPE), .EXTRA_DIVIDE(EXTRA_DIVIDE)) mylei (.clock_in(clock100), .reset(reset100), .word_clock_out(), .word_in(oserdes_word[0]), .D_out(coax[0]), .locked(pll_oserdes_locked_other));
		assign coax[4] = sync_out_stream[SYNC_OUT_STREAM_PICKOFF]; // scope trigger
		assign sync_read_address = 0;
	end else if (1) begin
		//ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(PERIOD), .MULTIPLY(MULTIPLY), .DIVIDE(DIVIDE), .SCOPE(SCOPE), .EXTRA_DIVIDE(EXTRA_DIVIDE)) mylei1 (.clock_in(clock100), .reset(reset100), .word_clock_out(), .word_in(oserdes_word[0]), .D_out(coax[4]), .locked(pll_oserdes_locked_other));
		//assign sync_read_address = coax[0];
		assign sync_read_address = 0;
		//assign coax[0] = sync_out_stream[SYNC_OUT_STREAM_PICKOFF]; // scope trigger
//		assign pll_oserdes_locked_other = 1;
	end else begin // to synchronize the coax outputs and to trigger the scope on that synchronization
		//assign coax[4] = sync_out_stream[SYNC_OUT_STREAM_PICKOFF]; // scope trigger
		//assign sync_read_address = coax[0] || coax[3]; // an input to synchronize to an external event
//		assign sync_read_address = diff_pair_right_p[0] || diff_pair_right_p[5]; // an input to synchronize to an external event
		//wire sync_read_address_raw;
		//wire sync_read_address_not;
		//IBUFDS buddy (.I(diff_pair_right_p[0]), .IB(diff_pair_right_n[0]), .O(sync_read_address_raw));
		//edge_to_pulse #(.polarity(1)) my_e2p_instance (.clock(word_clock), .i(sync_read_address_raw), .o(sync_read_address_not));
		//assign coax[0] = sync_read_address_raw;
		//assign coax[1] = sync_read_address_not;
		//assign sync_read_address = ~sync_read_address_not;
		assign sync_read_address = 0;
//		assign pll_oserdes_locked_other = 1;
		wire [2:0] adc_bit;
		wire [5:0] adc_thresh;
//		IBUFDS adc0 (.I(diff_pair_right_p[0]), .IB(diff_pair_right_n[0]), .O(adc_thresh[0]));
//		IBUFDS adc1 (.I(diff_pair_right_p[1]), .IB(diff_pair_right_n[1]), .O(adc_thresh[1]));
//		IBUFDS adc2 (.I(diff_pair_right_p[2]), .IB(diff_pair_right_n[2]), .O(adc_thresh[2]));
//		IBUFDS adc3 (.I(diff_pair_right_p[3]), .IB(diff_pair_right_n[3]), .O(adc_thresh[3]));
//		IBUFDS adc4 (.I(diff_pair_right_p[4]), .IB(diff_pair_right_n[4]), .O(adc_thresh[4]));
//		IBUFDS adc5 (.I(diff_pair_right_p[5]), .IB(diff_pair_right_n[5]), .O(adc_thresh[5]));
		assign adc_bit = adc_thresh[5] ? 3'b110 :
		                 adc_thresh[4] ? 3'b101 :
		                 adc_thresh[3] ? 3'b100 :
		                 adc_thresh[2] ? 3'b011 :
		                 adc_thresh[1] ? 3'b010 :
		                 adc_thresh[0] ? 3'b001 : 3'b000;
		assign coax_led = { 1'b0, adc_bit[2:0] };
	end
	// ----------------------------------------------------------------------
	if (0) begin
		assign status4 = 0;
		assign status8 = 0;
	end else begin
		assign status4[3] = ~pll_oserdes_locked;
		assign status4[2] = 0;
		assign status4[1] = 0;
		assign status4[0] = 0;
		// status8:
		assign status8[7] = ~clock50_locked;
		assign status8[6] = reset100;
		assign status8[5] = ~pll_oserdes_locked;
		assign status8[4] = reset_word;
		assign status8[3] = ~strobe_is_alignedA;
		assign status8[2] = ~strobe_is_alignedB;
		assign status8[1] = ~strobe_is_alignedC;
		assign status8[0] = ~strobe_is_alignedD;
	end
	assign coax_led = status4;
	assign led = status8;
	initial begin
		#100;
		//$display("%d banks", NUMBER_OF_BANKS);
	end
endmodule

module top_tb;
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
	reg clock100_p = 0;
	reg clock100_n = 1;
	reg clock10 = 0;
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
	top #(.BUS_WIDTH(BUS_WIDTH), .ADDRESS_DEPTH(ADDRESS_DEPTH), .TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD), .TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD), .ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE), .TESTBENCH(1)) althea (
		.clock100_p(clock100_p), .clock100_n(clock100_n), .clock10(clock10), .button(button),
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
		#512; // wait for reset100
		#512; // wait for reset125
		//#300; button <= 0; #300; button <= 1;
		//#512; // wait for reset100
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
		clock100_p <= #1.5 ~clock100_p;
		clock100_n <= #2.5 ~clock100_n;
	end
	always begin
		#HALF_PERIOD_OF_CONTROLLER;
		clock <= #0.625 ~clock;
	end
endmodule

module myalthea #(
	) (
	input clock50_p, clock50_n,
	inout coax4,
	inout coax3,
	inout coax0,
	// other IOs:
	output rpi_gpio2_i2c1_sda, // ack_valid
	input rpi_gpio3_i2c1_scl, // register_select
	input rpi_gpio4_gpclk0, // enable
	input rpi_gpio5, // read
	// 16 bit bus:
	inout rpi_gpio6_gpclk2, rpi_gpio7_spi_ce1, rpi_gpio8_spi_ce0, rpi_gpio9_spi_miso,
	inout rpi_gpio10_spi_mosi, rpi_gpio11_spi_sclk, rpi_gpio12, rpi_gpio13,
	inout rpi_gpio14, rpi_gpio15, rpi_gpio16, rpi_gpio17,
	inout rpi_gpio18, rpi_gpio19, rpi_gpio20, rpi_gpio21,
	// diff-pair IOs (toupee connectors):
	a_p, b_p, c_p, d_p, e_p, f_p, // rotated
	g_p, h_p, j_p, k_p, l_p, m_p,
//	a_n, b_n, c_n, d_n, e_n, f_n, // flipped
//	g_n, h_n, j_n, k_n, l_n, m_n, 
	// single-ended IOs (toupee connectors):
	n, p, q, r, s, t,
	u, v, w, x, y, z,
	// other IOs:
	//input [2:0] rot
	input button, // reset
//	output [7-LEFT_DAC_OUTER*4:4-LEFT_DAC_OUTER*4] led,
	output [3:0] coax_led
);
	localparam BUS_WIDTH = 16;
	localparam BANK_ADDRESS_DEPTH = 13;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	wire clock10 = 0;
	wire [3:0] internal_coax_led;
	wire [7:0] internal_led;
	//assign led = internal_led;
	assign coax_led = internal_coax_led;
	wire [5:0] diff_pair_left;
//	assign { a_p, c_p, d_p, f_p, b_p, e_p } = diff_pair_left; // rotated
	assign { a_n, c_n, d_n, f_n, b_n, e_n } = diff_pair_left; // flipped
	wire coax5, coax2, coax1;
	wire [12:1] signal;
	wire [12:1] indicator;
	//assign { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p } = signal;
	//assign { t, s, r, q, p, n, u, v, w, x, y, z } = indicator;
	assign { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p } = signal;
	assign { t, s, r, q, p, n, u, v, w, x, y, z } = indicator;
	top #(
		.TESTBENCH(0),
		.BUS_WIDTH(BUS_WIDTH), .BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10), .button(button),
		.coax({coax5, coax4, coax3, coax2, coax1, coax0}),
		.bus({
			rpi_gpio21, rpi_gpio20, rpi_gpio19, rpi_gpio18,
			rpi_gpio17, rpi_gpio16, rpi_gpio15, rpi_gpio14,
			rpi_gpio13, rpi_gpio12, rpi_gpio11_spi_sclk, rpi_gpio10_spi_mosi,
			rpi_gpio9_spi_miso, rpi_gpio8_spi_ce0, rpi_gpio7_spi_ce1, rpi_gpio6_gpclk2
		}),
		.signal(signal),
		.indicator(indicator),
//		.diff_pair_left(diff_pair_left),
//		.diff_pair_right_p({ m_p, k_p, l_p, j_p, h_p, g_p }),
//		.diff_pair_right_n({ m_n, k_n, l_n, j_n, h_n, g_n }),
//		.single_ended_left({ z, y, x, w, v, u }),
//		.single_ended_right({ n, p, q, r, s, t }),
		.register_select(rpi_gpio3_i2c1_scl), .read(rpi_gpio5),
		.enable(rpi_gpio4_gpclk0), .ack_valid(rpi_gpio2_i2c1_sda),
//		.rot(rot),
//		.led(internal_led),
		.coax_led(internal_coax_led)
	);
endmodule

