// written 2022-10-14 by mza
// based on mza-test055.palimpsest.cable-tester.althea.revB.v
// last updated 2022-10-14 by mza

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
	parameter TRANSACTIONS_PER_ADDRESS_WORD = 1,
	parameter BANK_ADDRESS_DEPTH = 13,
	parameter LOG2_OF_NUMBER_OF_BANKS = BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD - BANK_ADDRESS_DEPTH,
	parameter NUMBER_OF_BANKS = 1<<LOG2_OF_NUMBER_OF_BANKS,
	parameter LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH = $clog2(64),
	parameter ADDRESS_DEPTH_OSERDES = BANK_ADDRESS_DEPTH + LOG2_OF_BUS_WIDTH + LOG2_OF_TRANSACTIONS_PER_DATA_WORD - LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH,
	parameter ADDRESS_AUTOINCREMENT_MODE = 1,
	parameter RIGHT_DAC_OUTER = 1,
	parameter LEFT_DAC_OUTER = 1,
	parameter LEFT_DAC_ROTATED = 0,
	parameter RIGHT_DAC_INNER = 1,
	parameter LEFT_DAC_INNER = 1,
	parameter TESTBENCH = 0,
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
	input [12:1] signal,
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
	localparam MULTIPLY = 8;
	localparam DIVIDE = 2;
	localparam EXTRA_DIVIDE = 16;
	localparam SCOPE = "GLOBAL"; // "GLOBAL" (400 MHz), "BUFIO2" (525 MHz), "BUFPLL" (1080 MHz)
//	wire [7:0] pattern [12:1];
//	assign pattern[1]  = 8'h0f;
//	assign pattern[2]  = 8'h03;
//	assign pattern[3]  = 8'h07;
//	assign pattern[4]  = 8'h01;
//	assign pattern[5]  = 8'h1f;
//	assign pattern[6]  = 8'h3f;
//	assign pattern[7]  = 8'h7f;
//	assign pattern[8]  = 8'hcc;
//	assign pattern[9]  = 8'ha1;
//	assign pattern[10] = 8'ha3;
//	assign pattern[11] = 8'ha7;
//	assign pattern[12] = 8'haf;
//	reg [7:0] status [12:1];
	localparam ERROR_COUNT_PICKOFF = 7;
	wire [3:0] status4;
	wire [7:0] status8;
	wire reset;
	genvar i;
	wire pll_oserdes_locked;
	wire pll_oserdes_locked_other;
//	wire pll_oserdes_locked_right_outer;
//	wire pll_oserdes_locked_left_outer;
//	wire pll_oserdes_locked_right_inner;
//	wire pll_oserdes_locked_left_inner;
	// ----------------------------------------------------------------------
	wire clock100;
	wire clock50_locked;
	if (1) begin
		wire clock50_raw;
		IBUFGDS mybuf50_raw1 (.I(clock50_p), .IB(clock50_n), .O(clock50_raw));
		wire clock100_raw;
		simpledcm_CLKGEN #(.MULTIPLY(2), .DIVIDE(1), .PERIOD(20.0)) mydcm50 (.clockin(clock50_raw), .reset(reset), .clockout(clock100_raw), .clockout180(), .locked(clock50_locked));
		BUFG mybuf50_raw2 (.I(clock100_raw), .O(clock100));
	end
	wire reset100;
	if (1) begin
//		IBUFGDS mybuf0 (.I(clock100_p), .IB(clock100_n), .O(clock100));
		reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset100_wait4pll (.reset_input(reset), .pll_locked_input(clock50_locked), .clock_input(clock100), .reset_output(reset100));
	end else begin
		wire clock100_locked;
		dummy_dcm_diff_input lollipop (.clock_p(clock100_p), .clock_n(clock100_n), .reset(reset), .clock_out(clock100), .clock_locked(clock100_locked));
		reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset100_wait4pll (.reset_input(reset), .pll_locked_input(clock100_locked), .clock_input(clock100), .reset_output(reset100));
	end
	wire word_clock;
//	wire word_clock_right_outer;
//	wire word_clock_left_outer;
//	wire word_clock_right_inner;
//	wire word_clock_left_inner;
	// ----------------------------------------------------------------------
	wire reset_word;
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset_input(reset100), .pll_locked_input(pll_oserdes_locked), .clock_input(word_clock), .reset_output(reset_word));
	// ----------------------------------------------------------------------
	wire [BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD-1:0] address_word_full;
	wire [BANK_ADDRESS_DEPTH-1:0] address_word_narrow = address_word_full[BANK_ADDRESS_DEPTH-1:0];
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] write_data_word;
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] read_data_word [NUMBER_OF_BANKS-1:0];
	wire [LOG2_OF_NUMBER_OF_BANKS-1:0] bank;
	wire [LOG2_OF_NUMBER_OF_BANKS-1:0] write_strobe;
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
//	wire [OSERDES_DATA_WIDTH-1:0] potential_oserdes_word [NUMBER_OF_BANKS-1:0];
//	wire [OSERDES_DATA_WIDTH-1:0] oserdes_word [NUMBER_OF_BANKS-1:0];
	wire [ADDRESS_DEPTH_OSERDES-1:0] read_address; // in 8-bit words
//	wire [31:0] a_c_;
//	wire [31:0] _b_d;
	RAM_s6_8k_16bit_32bit mem0 (.reset(reset_word),
		.clock_a(word_clock), .address_a(address_word_narrow), .data_in_a(write_data_word[15:0]), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0][15:0]),
		.clock_b(word_clock), .address_b(read_address), .data_out_b());
	RAM_s6_8k_16bit_32bit mem1 (.reset(reset_word),
		.clock_a(word_clock), .address_a(address_word_narrow), .data_in_a(write_data_word[31:16]), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0][31:16]),
		.clock_b(word_clock), .address_b(read_address), .data_out_b());
//	wire [63:0] oserdes_word64;
//	assign oserdes_word64[63:48] = a_c_[31:16];
//	assign oserdes_word64[47:32] = _b_d[31:16];
//	assign oserdes_word64[31:16] = a_c_[15:0];
//	assign oserdes_word64[15:0 ] = _b_d[15:0];
//	wire [OSERDES_DATA_WIDTH-1:0] preDACbit [7:0]; // preDACbit[i] is an 8 bit word giving the next 8 timeseries values [7 downto 0] for bit i of the DAC output
//	for (i=0; i<8; i=i+1) begin : preDACbit_mapping
		// bit0 -> 56, 48, 40, 32, 24, 16, 8, 0
		// bit7 -> 63, 55, 47, 39, 31, 23, 15, 7
//		assign preDACbit[i] = { oserdes_word64[8*7+i], oserdes_word64[8*6+i], oserdes_word64[8*5+i], oserdes_word64[8*4+i],
//		                        oserdes_word64[8*3+i], oserdes_word64[8*2+i], oserdes_word64[8*1+i], oserdes_word64[8*0+i] };
//	end
//	wire [OSERDES_DATA_WIDTH-1:0] DACvalue [7:0]; // DACvalue[i] for i=7 downto 0 is a timeseries of 8 bit DAC values
//	wire [OSERDES_DATA_WIDTH-1:0] DACvaluePRIME [7:0]; // delayed version of DACvalue
//	for (i=0; i<8; i=i+1) begin : DACvalue_mapping
//		assign DACvalue[i] = {
//			preDACbit[7][i], preDACbit[6][i], preDACbit[5][i], preDACbit[4][i], 
//			preDACbit[3][i], preDACbit[2][i], preDACbit[1][i], preDACbit[0][i] };
//	end
//	wire [OSERDES_DATA_WIDTH-1:0] minuend;
//	wire [OSERDES_DATA_WIDTH-1:0] difference [7:0];
//	localparam DEPTH = 4;
//	for (i=0; i<8; i=i+1) begin : arithmetic_pipeline_mapping
//		arithmetic_pipeline #(.WIDTH(OSERDES_DATA_WIDTH), .DEPTH(DEPTH)) ap (.clock(word_clock), .minuend(minuend), .subtrahend(DACvalue[i]), .difference(difference[i]));
//		pipeline #(.WIDTH(OSERDES_DATA_WIDTH), .DEPTH(DEPTH)) pl (.clock(word_clock), .in(DACvalue[i]), .out(DACvaluePRIME[i]));
//	end
//	wire [OSERDES_DATA_WIDTH-1:0] DACbit [7:0];
//	wire [OSERDES_DATA_WIDTH-1:0] DACbitN [7:0];
//	for (i=0; i<8; i=i+1) begin : DACbit_mapping
//		assign DACbit[i] = {
//			DACvaluePRIME[7][i], DACvaluePRIME[6][i], DACvaluePRIME[5][i], DACvaluePRIME[4][i], 
//			DACvaluePRIME[3][i], DACvaluePRIME[2][i], DACvaluePRIME[1][i], DACvaluePRIME[0][i] };
//		assign DACbitN[i] = {
//			difference[7][i], difference[6][i], difference[5][i], difference[4][i], 
//			difference[3][i], difference[2][i], difference[1][i], difference[0][i] };
//	end
	for (i=3; i<NUMBER_OF_BANKS; i=i+1) begin : fakebanks
		assign read_data_word[i] = 0;
	end
//	assign potential_oserdes_word[0] = DACbit[7];
//	for (i=1; i<NUMBER_OF_BANKS; i=i+1) begin : banksfake
//		assign potential_oserdes_word[i] = 0;
//	end
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
//	if (1==RIGHT_DAC_OUTER) begin
//		assign word_clock = word_clock_right_outer;
//		assign pll_oserdes_locked_other = 1;
//	end else if (1==LEFT_DAC_OUTER) begin
//		assign word_clock = word_clock_left_outer;
//		assign pll_oserdes_locked_other = 1;
//	end else if (1==RIGHT_DAC_INNER) begin
//		assign word_clock = word_clock_right_inner;
//		assign pll_oserdes_locked_other = 1;
//	end else if (1==LEFT_DAC_INNER) begin
//		assign word_clock = word_clock_left_inner;
//		assign pll_oserdes_locked_other = 1;
//	end else begin
//		ocyrus_quad8 #(.BIT_DEPTH(8), .PERIOD(PERIOD), .DIVIDE(DIVIDE), .MULTIPLY(MULTIPLY), .SCOPE(SCOPE), .EXTRA_DIVIDE(EXTRA_DIVIDE)) mylei4 (
//			.clock_in(clock100), .reset(reset100), .word_clock_out(word_clock), .locked(pll_oserdes_locked_other),
//			.word3_in(DACbit[7]), .word2_in(DACbit[6]), .word1_in(DACbit[5]), .word0_in(DACbit[4]),
//			.D3_out(coax[3]), .D2_out(coax[2]), .D1_out(coax[1]), .D0_out(coax[0]));
//	end
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
	reg [31:0] hit_counter = 0;
//	assign bank1[0]  = { oserdes_word[3], oserdes_word[2], oserdes_word[1], oserdes_word[0] };
	assign bank1[0]  = hit_counter;
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
//	assign      minuend                   = bank2[0][7:0];
	wire        train_oserdes             = bank2[4][0];
	wire  [7:0] train_oserdes_pattern     = bank2[5][7:0];
	wire [31:0] start_sample              = bank2[6][31:0];
	wire [31:0] end_sample                = bank2[7][31:0];
	assign reset = 0;
	wire [7:0] iserdes_in [12:1];
	reg [7:0] iserdes_in_buffered_1 [12:1];
	reg [7:0] iserdes_in_buffered_2 [12:1];
	reg [12:1] iserdes_word_hit;
	reg any;
	reg [2:0] anytrain = 0;
	for (i=1; i<=12; i=i+1) begin : iserdes_buffer_1_mapping
		always @(posedge word_clock) begin
			if (reset_word) begin
				iserdes_in_buffered_1[i] <= 0;
			end else begin
				iserdes_in_buffered_1[i] <= iserdes_in[i];
			end
		end
	end
	for (i=1; i<=12; i=i+1) begin : iserdes_buffer_2_mapping
		always @(posedge word_clock) begin
			if (reset_word) begin
				iserdes_in_buffered_2[i] <= 0;
			end else begin
				iserdes_in_buffered_2[i] <= iserdes_in_buffered_1[i];
			end
		end
	end
	for (i=1; i<=12; i=i+1) begin : iserdes_word_hit_mapping
		always @(posedge word_clock) begin
			if (reset_word) begin
				iserdes_word_hit[i] <= 0;
			end else begin
				iserdes_word_hit[i] <= |iserdes_in[i]; // this result will be available when iserdes_in_buffered_1 corresponds
			end
		end
	end
	always @(posedge word_clock) begin
		if (reset_word) begin
			any <= 0;
		end else begin
			any <= |iserdes_word_hit; // this result will be available when iserdes_in_buffered_2 corresponds
		end
	end
	always @(posedge word_clock) begin
		if (reset_word) begin
			anytrain <= 0;
		end else begin
			anytrain <= { anytrain[1], anytrain[0], any };
		end
	end
	always @(posedge word_clock) begin
		if (reset_word) begin
			hit_counter <= 0;
		end else begin
			if (2'b01==anytrain[2:1]) begin
				hit_counter <= hit_counter + 1'b1;
			end
		end
	end
	wire strobe_is_alignedA;
	wire strobe_is_alignedB;
	wire strobe_is_alignedC;
	wire strobe_is_alignedD;
	// the order here is 12, 11, 10, 6, 5, 4, 9, 8, 7, 3, 2, 1
	ocyrus_triacontahedron8_split_12_6_6_4_2_BCinput #(.BIT_DEPTH(8), .PERIOD(PERIOD), .MULTIPLY(MULTIPLY), .DIVIDE(DIVIDE), .EXTRA_DIVIDE(EXTRA_DIVIDE)
	) orama (
		.clock_in(clock100), .reset(reset100),
		.word_A11_in({8{iserdes_word_hit[12]}}), .word_A10_in({8{iserdes_word_hit[11]}}), .word_A09_in({8{iserdes_word_hit[10]}}), .word_A08_in({8{iserdes_word_hit[9]}}), .word_A07_in({8{iserdes_word_hit[8]}}), .word_A06_in({8{iserdes_word_hit[7]}}),
		.word_A05_in({8{iserdes_word_hit[6]}}), .word_A04_in({8{iserdes_word_hit[5]}}), .word_A03_in({8{iserdes_word_hit[4]}}), .word_A02_in({8{iserdes_word_hit[3]}}), .word_A01_in({8{iserdes_word_hit[2]}}), .word_A00_in({8{iserdes_word_hit[1]}}),
		.word_B5_out(iserdes_in[12]), .word_B4_out(iserdes_in[11]), .word_B3_out(iserdes_in[10]), .word_B2_out(iserdes_in[9]), .word_B1_out(iserdes_in[8]), .word_B0_out(iserdes_in[7]),
		.word_C5_out(iserdes_in[6]), .word_C4_out(iserdes_in[5]), .word_C3_out(iserdes_in[4]), .word_C2_out(iserdes_in[3]), .word_C1_out(iserdes_in[2]), .word_C0_out(iserdes_in[1]),
		.word_D3_in(sync_out_word), .word_D2_in(sync_out_word), .word_D1_in(sync_out_word), .word_D0_in({8{any}}),
		.word_E1_in(sync_out_word), .word_E0_in(sync_out_word),
		.word_clockA_out(), .word_clockB_out(word_clock), .word_clockC_out(), .word_clockD_out(), .word_clockE_out(),
		.A11_out(indicator[12]), .A10_out(indicator[11]), .A09_out(indicator[10]), .A08_out(indicator[6]), .A07_out(indicator[5]), .A06_out(indicator[4]),
		.A05_out(indicator[9]), .A04_out(indicator[8]), .A03_out(indicator[7]), .A02_out(indicator[3]), .A01_out(indicator[2]), .A00_out(indicator[1]),
		.B5_in(signal[12]), .B4_in(signal[11]), .B3_in(signal[10]), .B2_in(signal[6]), .B1_in(signal[5]), .B0_in(signal[4]),
		.C5_in(signal[9]), .C4_in(signal[8]), .C3_in(signal[7]), .C2_in(signal[3]), .C1_in(signal[2]), .C0_in(signal[1]),
		.D3_out(coax[3]), .D2_out(coax[2]), .D1_out(coax[1]), .D0_out(coax[0]),
		.E1_out(coax[5]), .E0_out(coax[4]),
		.strobe_is_alignedA(strobe_is_alignedA), .strobe_is_alignedB(strobe_is_alignedB),
		.strobe_is_alignedC(strobe_is_alignedC), .strobe_is_alignedD(strobe_is_alignedD),
		.locked(pll_oserdes_locked)
	);
//	for (i=0; i<NUMBER_OF_BANKS; i=i+1) begin : train_or_regular
//		assign oserdes_word[i] = train_oserdes ? train_oserdes_pattern : potential_oserdes_word[i];
//	end
//	assign coax[1] = 0; // because coax[1] is on same pin pair as gpio17 on althea revB
//	assign coax[2] = 0; // because coax[2] is on same pin pair as gpio12 on althea revB
//	assign coax[5] = 0; // because coax[5] is on same pin pair as p on althea revB
	sequencer_sync #(.ADDRESS_DEPTH_OSERDES(ADDRESS_DEPTH_OSERDES), .LOG2_OF_OSERDES_DATA_WIDTH(LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH), .SYNC_OUT_STREAM_PICKOFF(SYNC_OUT_STREAM_PICKOFF)) ss (.clock(word_clock), .reset(reset_word), .sync_read_address(sync_read_address), .start_sample(start_sample), .end_sample(end_sample), .read_address(read_address), .sync_out_stream(sync_out_stream), .sync_out_word(sync_out_word));
	if (0) begin // to test the rpi interface to the read/write pollable memory
		assign coax[4] = enable; // scope trigger
//		assign coax[0] = write_strobe[0];
		assign pll_oserdes_locked_other = 1;
	end else if (1) begin
		assign sync_read_address = 0;
	end
	// ----------------------------------------------------------------------
	if (0) begin
		assign status4 = { any, any, any, any };
		assign status8 = 0;
	end else begin
		assign status4[3] = ~pll_oserdes_locked;
		assign status4[2] = enable;
		assign status4[1] = 0;
		assign status4[0] = any;
		// ------------------------------------------------
		assign status8[7] = ~pll_oserdes_locked;
		assign status8[6] = enable;
		assign status8[5] = 0;
		assign status8[4] = any;
		assign status8[3] = strobe_is_alignedA;
		assign status8[2] = strobe_is_alignedB;
		assign status8[1] = strobe_is_alignedC;
		assign status8[0] = strobe_is_alignedD;
	end
	assign coax_led = status4;
	initial begin
		#100;
		$display("%d = %d + %d + %d - %d", ADDRESS_DEPTH_OSERDES, BANK_ADDRESS_DEPTH, LOG2_OF_BUS_WIDTH, LOG2_OF_TRANSACTIONS_PER_DATA_WORD, LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH);
		$display("BUS_WIDTH=%d, TRANSACTIONS_PER_DATA_WORD=%d, TRANSACTIONS_PER_ADDRESS_WORD=%d", BUS_WIDTH, TRANSACTIONS_PER_DATA_WORD, TRANSACTIONS_PER_ADDRESS_WORD);
		$display("%d banks", NUMBER_OF_BANKS);
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
	parameter LEFT_DAC_OUTER = 1,
	parameter RIGHT_DAC_OUTER = 1,
	parameter LEFT_DAC_ROTATED = 0,
	parameter LEFT_DAC_INNER = 0,
	parameter RIGHT_DAC_INNER = 0
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
	input
	a_p, b_p, c_p, d_p, e_p, f_p, // rotated
	g_p, h_p, j_p, k_p, l_p, m_p,
//	a_n, b_n, c_n, d_n, e_n, f_n, // flipped
//	g_n, h_n, j_n, k_n, l_n, m_n, 
	// single-ended IOs (toupee connectors):
	output
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
	if (1==LEFT_DAC_ROTATED) begin
//		assign { a_p, c_p, d_p, f_p, b_p, e_p } = diff_pair_left; // rotated
	end else begin
		assign { a_n, c_n, d_n, f_n, b_n, e_n } = diff_pair_left; // flipped
	end
	wire coax5, coax2, coax1;
	wire [12:1] signal;
	wire [12:1] indicator;
	//assign { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p } = signal;
	//assign { t, s, r, q, p, n, u, v, w, x, y, z } = indicator;
	//assign { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p } = signal;
	assign signal = { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p };
	assign { t, s, r, q, p, n, u, v, w, x, y, z } = indicator;
	top #(
		.LEFT_DAC_OUTER(LEFT_DAC_OUTER), .RIGHT_DAC_OUTER(RIGHT_DAC_OUTER),
		.LEFT_DAC_ROTATED(LEFT_DAC_ROTATED),
		.LEFT_DAC_INNER(LEFT_DAC_INNER), .RIGHT_DAC_INNER(RIGHT_DAC_INNER),
		.TESTBENCH(0),
		.BUS_WIDTH(BUS_WIDTH), .BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10),
		.button(button),
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

