// written 2021-10-13 by mza
// based on mza-test050.simple-parallel-interface-and-pollable-memory.6bit-oserdes-R2R-ladder-DAC.althea.revBLM.v
// last updated 2021-10-26 by mza

`define althea_revBLM
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
	parameter RIGHT_DAC_INNER = 1,
	parameter LEFT_DAC_INNER = 1,
	parameter TESTBENCH = 0,
	parameter COUNTER100_BIT_PICKOFF = TESTBENCH ? 5 : 23,
	parameter COUNTERWORD_BIT_PICKOFF = TESTBENCH ? 5 : 23
) (
	input clock100_p, clock100_n,
	input clock10,
	input button,
	inout [5:0] coax,
//	input [2:0] rot,
	inout [BUS_WIDTH-1:0] bus,
	input read, // 0=write; 1=read
	input register_select, // 0=address; 1=data
	input enable, // 1=active; 0=inactive
	output ack_valid,
	output [5:0] diff_pair_left_p,
//	output [5:0] diff_pair_left_n,
	output [5:0] diff_pair_right_p,
//	output [5:0] diff_pair_right_n,
	output [5:0] single_ended_left,
	output [5:0] single_ended_right,
//	output [7-LEFT_DAC_OUTER*4:4-LEFT_DAC_OUTER*4] led,
	output [3:0] coax_led
);
	localparam ERROR_COUNT_PICKOFF = 7;
	wire [3:0] status4;
	wire [7:0] status8;
	wire reset;
	genvar i;
	wire pll_oserdes_locked;
	wire pll_oserdes_locked_1;
	wire pll_oserdes_locked_2;
	wire pll_oserdes_locked_3;
	wire dpr;
	wire dpl;
//	for (i=0; i<6; i=i+1) begin : diff_pair_n
//		assign diff_pair_right_n[i] = dpr;
//		assign diff_pair_left_n[i] = dpl;
//	end
//	assign diff_pair_left[3] = pll_oserdes_locked_2; // e_n
//	assign diff_pair_left[2] = pll_oserdes_locked_1; // e_p
//	assign diff_pair_left[1] = pll_oserdes_locked;   // b_p
//	assign diff_pair_left[0] = write_strobe;         // b_n
//	assign diff_pair_right[0] = read;            // k_p
//	assign diff_pair_right[1] = register_select; // k_n
//	assign diff_pair_right[3] = ack_valid;       // h_n
//	assign diff_pair_right[2] = enable;          // h_p
//	assign diff_pair_left[11:4] = bus[15:8]; // a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p
//	assign diff_pair_right[11:4] = bus[7:0]; // g_n, g_p, j_n, j_p, l_n, l_p, m_n, m_p
	// ----------------------------------------------------------------------
	wire reset100;
	wire clock100;
	IBUFGDS mybuf0 (.I(clock100_p), .IB(clock100_n), .O(clock100));
	wire word_clock;
	wire word_clock2;
	wire word_clock3;
	wire word_clock4;
	wire word_clock5;
	wire word_clock0 = word_clock2;
	wire word_clock1 = word_clock2;
	wire clock = word_clock0;
	// ----------------------------------------------------------------------
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset100_wait4pll (.reset_input(reset), .pll_locked_input(1'b1), .clock_input(clock100), .reset_output(reset100));
	wire reset_word0;
	wire reset_word1;
	assign pll_oserdes_locked = pll_oserdes_locked_1 && pll_oserdes_locked_2;
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset_input(reset100), .pll_locked_input(pll_oserdes_locked), .clock_input(word_clock0), .reset_output(reset_word0));
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword1_wait4pll (.reset_input(reset100), .pll_locked_input(pll_oserdes_locked), .clock_input(word_clock1), .reset_output(reset_word1));
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
		.clock(word_clock0),
		.reset(reset_word0),
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
	wire [7:0] oserdes_word_delayed;
	wire [7:0] oserdes_word1_buffer;
//	wire [7:0] oserdes_word1_buffer_mid;
	wire [7:0] oserdes_word1_buffer_delayed;
	wire [63:0] oserdes_word64;
	wire [OSERDES_DATA_WIDTH-1:0] oserdes_word_for_DACbit [7:0];
	for (i=0; i<8; i=i+1) begin : oserdes_bit_mapping
		// bit0 -> 56, 48, 40, 32, 24, 16, 8, 0
		// bit7 -> 63, 55, 47, 39, 31, 23, 15, 7
		assign oserdes_word_for_DACbit[i] = { oserdes_word64[8*7+i], oserdes_word64[8*6+i], oserdes_word64[8*5+i], oserdes_word64[8*4+i],
		                                      oserdes_word64[8*3+i], oserdes_word64[8*2+i], oserdes_word64[8*1+i], oserdes_word64[8*0+i] };
	end
//	assign oserdes_word = oserdes_word_for_DACbit[0];
	wire [ADDRESS_DEPTH_OSERDES-1:0] read_address; // in 8-bit words
	wire [31:0] bank1 [15:0];
	wire [31:0] bank2 [15:0];
//	assign oserdes_word = { 7'd0, oserdes_word64[0] };
	wire [31:0] a_c_;
	wire [31:0] _b_d;
	RAM_s6_8k_16bit_32bit mem0 (.reset(reset100),
		.clock_a(clock), .address_a(address_word_narrow), .data_in_a(write_data_word[15:0]), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0][15:0]),
		.clock_b(word_clock), .address_b(read_address), .data_out_b(_b_d));
	RAM_s6_8k_16bit_32bit mem1 (.reset(reset100),
		.clock_a(clock), .address_a(address_word_narrow), .data_in_a(write_data_word[31:16]), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0][31:16]),
		.clock_b(word_clock), .address_b(read_address), .data_out_b(a_c_));
	assign oserdes_word64[63:48] = a_c_[31:16];
	assign oserdes_word64[47:32] = _b_d[31:16];
	assign oserdes_word64[31:16] = a_c_[15:0];
	assign oserdes_word64[15:0 ] = _b_d[15:0];
	for (i=3; i<NUMBER_OF_BANKS; i=i+1) begin : fakebanks
		assign read_data_word[i] = 0;
	end
	assign potential_oserdes_word[0] = oserdes_word_for_DACbit[7];
	for (i=1; i<NUMBER_OF_BANKS; i=i+1) begin : banksfake
		assign potential_oserdes_word[i] = 0;
	end
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank1 (.clock(word_clock0), .reset(reset_word0),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[1]),
		.data_in_b_0(bank1[0]),  .data_in_b_1(bank1[1]),  .data_in_b_2(bank1[2]),  .data_in_b_3(bank1[3]),
		.data_in_b_4(bank1[4]),  .data_in_b_5(bank1[5]),  .data_in_b_6(bank1[6]),  .data_in_b_7(bank1[7]),
		.data_in_b_8(bank1[8]),  .data_in_b_9(bank1[9]),  .data_in_b_a(bank1[10]), .data_in_b_b(bank1[11]),
		.data_in_b_c(bank1[12]), .data_in_b_d(bank1[13]), .data_in_b_e(bank1[14]), .data_in_b_f(bank1[15]),
		.write_strobe_b(1'b1));
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank2 (.clock(word_clock0), .reset(reset_word0),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[2]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[2]),
		.data_out_b_0(bank2[0]),  .data_out_b_1(bank2[1]),  .data_out_b_2(bank2[2]),  .data_out_b_3(bank2[3]),
		.data_out_b_4(bank2[4]),  .data_out_b_5(bank2[5]),  .data_out_b_6(bank2[6]),  .data_out_b_7(bank2[7]),
		.data_out_b_8(bank2[8]),  .data_out_b_9(bank2[9]),  .data_out_b_a(bank2[10]), .data_out_b_b(bank2[11]),
		.data_out_b_c(bank2[12]), .data_out_b_d(bank2[13]), .data_out_b_e(bank2[14]), .data_out_b_f(bank2[15]));
	if (0==RIGHT_DAC_OUTER && 0==LEFT_DAC_OUTER && 0==RIGHT_DAC_INNER && 0==LEFT_DAC_INNER) begin
		ocyrus_quad8 #(.BIT_DEPTH(8), .PERIOD(10.0), .DIVIDE(1), .MULTIPLY(10), .SCOPE("BUFPLL")) mylei4 (
			.clock_in(clock100), .reset(reset100), .word_clock_out(word_clock), .locked(pll_oserdes_locked_1),
			.word3_in(oserdes_word_for_DACbit[7]), .word2_in(oserdes_word_for_DACbit[6]), .word1_in(oserdes_word_for_DACbit[5]), .word0_in(oserdes_word_for_DACbit[4]),
			.D3_out(coax[3]), .D2_out(coax[2]), .D1_out(coax[1]), .D0_out(coax[0]));
	end else begin
//		for (i=0; i<4; i=i+1) begin : single_ended_array_coax
//			assign coax[i] = 0;
//		end
		assign word_clock = word_clock2;
		assign pll_oserdes_locked_1 = 1;
	end
	assign coax[0] = 0;
	assign coax[1] = 0;
	assign coax[2] = 0;
	assign coax[3] = 0;
	assign coax[5] = sync_out_stream[SYNC_OUT_STREAM_PICKOFF];
	wire sync_read_address; // assert this when you feel like (re)synchronizing
	localparam SYNC_OUT_STREAM_PICKOFF = 2;
	wire [SYNC_OUT_STREAM_PICKOFF:0] sync_out_stream; // sync_out_stream[2] is usually good
	wire [7:0] sync_out_word; // dump this in to one of the outputs in a multi-lane oserdes module to get a sync bit that is precisely aligned with your data
//	assign dpr = sync_out_stream[SYNC_OUT_STREAM_PICKOFF];
//	assign dpl = sync_out_stream[SYNC_OUT_STREAM_PICKOFF];
	assign dpr = 0;
	assign dpl = 0;
	wire [7:0] sync_out_word_delayed; // dump this in to one of the outputs in a multi-lane oserdes module to get a sync bit that is precisely aligned with your data
//	wire [2:0] rot_pipeline;
	assign bank1[0]  = { oserdes_word[3], oserdes_word[2], oserdes_word[1], oserdes_word[0] };
	assign bank1[1]  = { oserdes_word_delayed, 8'd0, oserdes_word1_buffer, oserdes_word1_buffer_delayed };
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
//	wire  [2:0] bitslip_iserdes           = bank2[0][2:0];
	wire  [2:0] bitslip_oserdes1          = bank2[1][2:0];
//	wire  [2:0] bitslip_oserdes1_again    = bank2[2][2:0];
	(* KEEP = "TRUE" *)
	wire  [1:0] word_clock_sel            = bank2[3][1:0];
	wire        train_oserdes             = bank2[4][0];
	wire  [7:0] train_oserdes_pattern     = bank2[5][7:0];
	wire [31:0] start_sample              = bank2[6][31:0];
	wire [31:0] end_sample                = bank2[7][31:0];
//	wire        enable_histogram_sampling = bank2[8][0];
//	wire        clear_histogram_results   = bank2[8][1];
	if (1==RIGHT_DAC_OUTER) begin
		ocyrus_hex8 #(.BIT_DEPTH(8), .PERIOD(10.0), .DIVIDE(1), .MULTIPLY(10), .SCOPE("BUFPLL")) mylei6r (
			.clock_in(clock100), .reset(reset100), .word_clock_out(word_clock2), .locked(pll_oserdes_locked_2),
			.word5_in(oserdes_word_for_DACbit[7]), .word4_in(oserdes_word_for_DACbit[6]),
			.word3_in(oserdes_word_for_DACbit[5]), .word2_in(oserdes_word_for_DACbit[4]),
			.word1_in(oserdes_word_for_DACbit[3]), .word0_in(sync_out_word),
			.D5_out(single_ended_right[5]), .D4_out(single_ended_right[4]),
			.D3_out(single_ended_right[3]), .D2_out(single_ended_right[2]),
			.D1_out(single_ended_right[1]), .D0_out(coax[4]));
		assign single_ended_right[0] = 0;
	end else begin
		for (i=0; i<6; i=i+1) begin : single_ended_array_right
			assign single_ended_right[i] = 0;
		end
		assign pll_oserdes_locked_2 = 1;
	end
	if (1==RIGHT_DAC_INNER) begin
		ocyrus_hex8 #(.BIT_DEPTH(8), .PERIOD(10.0), .DIVIDE(1), .MULTIPLY(10), .SCOPE("BUFPLL")) mylei6rdual (
			.clock_in(clock100), .reset(reset100), .word_clock_out(word_clock4), .locked(pll_oserdes_locked_4),
			.word5_in(oserdes_word_for_DACbit[7]), .word4_in(oserdes_word_for_DACbit[6]),
			.word3_in(oserdes_word_for_DACbit[5]), .word2_in(oserdes_word_for_DACbit[4]),
			.word1_in(oserdes_word_for_DACbit[3]), .word0_in(oserdes_word_for_DACbit[2]),
			.D5_out(diff_pair_right_p[5]), .D4_out(diff_pair_right_p[4]),
			.D3_out(diff_pair_right_p[3]), .D2_out(diff_pair_right_p[2]),
			.D1_out(diff_pair_right_p[1]), .D0_out(diff_pair_right_p[0]));
	end else begin
		for (i=0; i<6; i=i+1) begin : diff_pair_pr
			assign diff_pair_right_p[i] = dpr;
		end
		assign pll_oserdes_locked_4 = 1;
	end
	if (1==LEFT_DAC_OUTER) begin
		ocyrus_hex8 #(.BIT_DEPTH(8), .PERIOD(10.0), .DIVIDE(1), .MULTIPLY(10), .SCOPE("BUFPLL")) mylei6l (
			.clock_in(clock100), .reset(reset100), .word_clock_out(word_clock3), .locked(pll_oserdes_locked_3),
			.word5_in(oserdes_word_for_DACbit[7]), .word4_in(oserdes_word_for_DACbit[6]),
			.word3_in(oserdes_word_for_DACbit[5]), .word2_in(oserdes_word_for_DACbit[4]),
			.word1_in(oserdes_word_for_DACbit[3]), .word0_in(oserdes_word_for_DACbit[2]),
			// for the case of the DAC board's outputs facing the same direction as the coax[0-3] outputs:
			//.D5_out(single_ended_left[5]), .D4_out(single_ended_left[4]),
			//.D3_out(single_ended_left[3]), .D2_out(single_ended_left[2]),
			//.D1_out(single_ended_left[1]), .D0_out(single_ended_left[0]));
			// for the case of the DAC board's outputs facing the opposite direction as the coax[0-3] outputs (the rotated case):
			.D5_out(single_ended_left[0]), .D4_out(single_ended_left[1]),
			.D3_out(single_ended_left[2]), .D2_out(single_ended_left[3]),
			.D1_out(single_ended_left[4]), .D0_out(single_ended_left[5]));
		assign reset = 0;
	end else begin
		for (i=0; i<6; i=i+1) begin : single_ended_array_left
			assign single_ended_left[i] = 0;
		end
		assign pll_oserdes_locked_3 = 1;
		assign reset = ~button;
	end
	if (1==LEFT_DAC_INNER) begin
		ocyrus_hex8 #(.BIT_DEPTH(8), .PERIOD(10.0), .DIVIDE(1), .MULTIPLY(10), .SCOPE("BUFPLL")) mylei6ldual (
			.clock_in(clock100), .reset(reset100), .word_clock_out(word_clock5), .locked(pll_oserdes_locked_5),
			.word5_in(oserdes_word_for_DACbit[7]), .word4_in(oserdes_word_for_DACbit[6]),
			.word3_in(oserdes_word_for_DACbit[5]), .word2_in(oserdes_word_for_DACbit[4]),
			.word1_in(oserdes_word_for_DACbit[3]), .word0_in(oserdes_word_for_DACbit[2]),
			.D5_out(diff_pair_left_p[5]), .D4_out(diff_pair_left_p[4]),
			.D3_out(diff_pair_left_p[3]), .D2_out(diff_pair_left_p[2]),
			.D1_out(diff_pair_left_p[1]), .D0_out(diff_pair_left_p[0]));
	end else begin
		for (i=0; i<6; i=i+1) begin : diff_pair_pl
			assign diff_pair_left_p[i] = dpl;
		end
		assign pll_oserdes_locked_5 = 1;
	end
	for (i=0; i<NUMBER_OF_BANKS; i=i+1) begin : train_or_regular
		assign oserdes_word[i] = train_oserdes ? train_oserdes_pattern : potential_oserdes_word[i];
	end
	sequencer_sync #(.ADDRESS_DEPTH_OSERDES(ADDRESS_DEPTH_OSERDES), .LOG2_OF_OSERDES_DATA_WIDTH(LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH), .SYNC_OUT_STREAM_PICKOFF(SYNC_OUT_STREAM_PICKOFF)) ss (.clock(word_clock0), .reset(reset_word0), .sync_read_address(sync_read_address), .start_sample(start_sample), .end_sample(end_sample), .read_address(read_address), .sync_out_stream(sync_out_stream), .sync_out_word(sync_out_word));
//	cdc_pipeline #(.WIDTH(3), .DEPTH(3)) tongs (.clock(word_clock0), .in(~rot), .out(rot_pipeline));
	localparam DELAY = 7;
	pipeline #(.WIDTH(8), .DEPTH(DELAY+4)) queens (.clock(word_clock0), .in(oserdes_word[0]), .out(oserdes_word_delayed));
//	pipeline #(.WIDTH(8), .DEPTH(DELAY+4)) diamond_head (.clock(word_clock0), .in(sync_out_word), .out(sync_out_word_delayed));
	bitslip #(.WIDTH(8)) bso1 (.clock(word_clock1), .bitslip(bitslip_oserdes1), .data_in(oserdes_word[0]), .data_out(oserdes_word1_buffer));
	pipeline #(.WIDTH(8), .DEPTH(DELAY)) kewalos (.clock(word_clock1), .in(oserdes_word1_buffer), .out(oserdes_word1_buffer_delayed));
//	bitslip #(.WIDTH(8)) bso2 (.clock(word_clock1), .bitslip(bitslip_oserdes1_again), .data_in(oserdes_word1_buffer_mid), .data_out(oserdes_word1_buffer_delayed));
	//pipeline #(.WIDTH(8), .DEPTH(DELAY)) canoes (.clock(word_clock1), .in(sync_out_word1_buffer), .out(sync_out_word1_buffer1));
	//assign coax_led = 4'b1111;
	//assign coax_led = reset_counter;
	if (0) begin // to test the rpi interface to the read/write pollable memory
		assign coax[4] = enable; // scope trigger
		assign coax[5] = write_strobe[0];
		assign pll_oserdes_locked_2 = 1;
	end else if (0) begin // to put the oserdes outputs on coax[4] and coax[5]
		ocyrus_double8 #(.BIT_DEPTH(8), .PERIOD(10.0), .MULTIPLY(10), .DIVIDE(1), .SCOPE("BUFPLL")) mylei2 (
			.clock_in(clock100), .reset(reset100), .word_clock_out(),
			.word1_in(oserdes_word[0]), .D1_out(coax[5]),
			.word0_in(oserdes_word[0]), .D0_out(coax[4]),
			.bit_clock(), .bit_strobe(),
			.locked(pll_oserdes_locked_2));
		assign sync_read_address = 0;
	end else if (0) begin
		ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(10.0), .MULTIPLY(10), .DIVIDE(1), .SCOPE("BUFPLL")) mylei (.clock_in(clock100), .reset(reset100), .word_clock_out(), .word_in(oserdes_word[0]), .D_out(coax[5]), .locked(pll_oserdes_locked_2));
		assign coax[4] = sync_out_stream[SYNC_OUT_STREAM_PICKOFF]; // scope trigger
		assign sync_read_address = 0;
	end else if (1) begin
		//ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(10.0), .MULTIPLY(10), .DIVIDE(1), .SCOPE("BUFPLL")) mylei1 (.clock_in(clock100), .reset(reset100), .word_clock_out(), .word_in(oserdes_word[0]), .D_out(coax[4]), .locked(pll_oserdes_locked_2));
		//assign sync_read_address = coax[5];
		assign sync_read_address = 0;
		//assign coax[5] = sync_out_stream[SYNC_OUT_STREAM_PICKOFF]; // scope trigger
//		assign pll_oserdes_locked_2 = 1;
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
//		assign pll_oserdes_locked_2 = 1;
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
	assign status4[3] = ~pll_oserdes_locked;
	assign status4[2] = ~pll_oserdes_locked_1;
	assign status4[1] = ~pll_oserdes_locked_2;
	assign status4[0] = enable;
	assign coax_led = status4;
	assign status8[7] = ~pll_oserdes_locked;
	assign status8[6] = ~pll_oserdes_locked_1;
	assign status8[5] = ~pll_oserdes_locked_2;
	assign status8[4] = enable;
//	if (0==LEFT_DAC_OUTER) begin
//		assign led[7:4] = status8[7:4];
//	end
	assign status8[3] = ~pll_oserdes_locked;
	assign status8[2] = ~pll_oserdes_locked_1;
	assign status8[1] = ~pll_oserdes_locked_2;
	assign status8[0] = enable;
//	if (0==RIGHT_DAC_OUTER) begin
//		assign led[3:0] = status8[3:0];
//	end
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
	parameter LEFT_DAC_OUTER = 0,
	parameter RIGHT_DAC_OUTER = 0,
	parameter LEFT_DAC_INNER = 0,
	parameter RIGHT_DAC_INNER = 1
) (
	input clock100_p, clock100_n,
	inout [5:0] coax,
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
	a_p, b_p, c_p, d_p, e_p, f_p, 
	g_p, h_p, j_p, k_p, l_p, m_p, 
//	a_n, b_n, c_n, d_n, e_n, f_n, 
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
	top #(
		.LEFT_DAC_OUTER(LEFT_DAC_OUTER), .RIGHT_DAC_OUTER(RIGHT_DAC_OUTER),
		.LEFT_DAC_INNER(LEFT_DAC_INNER), .RIGHT_DAC_INNER(RIGHT_DAC_INNER),
		.TESTBENCH(0),
		.BUS_WIDTH(BUS_WIDTH), .BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) althea (
		.clock100_p(clock100_p), .clock100_n(clock100_n), .clock10(clock10), .button(button),
		.coax(coax),
		.bus({
			rpi_gpio21, rpi_gpio20, rpi_gpio19, rpi_gpio18,
			rpi_gpio17, rpi_gpio16, rpi_gpio15, rpi_gpio14,
			rpi_gpio13, rpi_gpio12, rpi_gpio11_spi_sclk, rpi_gpio10_spi_mosi,
			rpi_gpio9_spi_miso, rpi_gpio8_spi_ce0, rpi_gpio7_spi_ce1, rpi_gpio6_gpclk2
		}),
		.diff_pair_left_p({ a_p, c_p, d_p, f_p, b_p, e_p }),
//		.diff_pair_left_n({ a_n, c_n, d_n, f_n, b_n, e_n }),
		.diff_pair_right_p({ m_p, k_p, l_p, j_p, h_p, g_p }),
//		.diff_pair_right_n({ m_n, k_n, l_n, j_n, h_n, g_n }),
		.single_ended_left({ z, y, x, w, v, u }),
		.single_ended_right({ n, p, q, r, s, t }),
		.register_select(rpi_gpio3_i2c1_scl), .read(rpi_gpio5),
		.enable(rpi_gpio4_gpclk0), .ack_valid(rpi_gpio2_i2c1_sda),
		.coax_led(internal_coax_led)
//		.led(internal_led),
//		.rot(rot)
	);
endmodule

