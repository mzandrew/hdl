// written 2020-10-01 by mza
// based on mza-test043.spi-pollable-memories-and-multiple-oserdes-function-generator-outputs.althea.v
// based on mza-test044.simple-parallel-interface-and-pollable-memory.althea.v
// last updated 2021-07-21 by mza

`define althea_revB
`include "lib/generic.v"
`include "lib/RAM8.v"
//`include "lib/RAM.sv" // ise does not and will not support systemverilog
`include "lib/plldcm.v"
`include "lib/serdes_pll.v"
`include "lib/half_duplex_rpi_bus.v"
`include "lib/sequencer.v"
`include "lib/reset.v"
`include "lib/histogram.v"
`include "lib/fifo.v"

module top #(
	parameter BUS_WIDTH = 16,
	parameter LOG2_OF_BUS_WIDTH = $clog2(BUS_WIDTH),
	parameter TRANSACTIONS_PER_DATA_WORD = 2,
	parameter LOG2_OF_TRANSACTIONS_PER_DATA_WORD = $clog2(TRANSACTIONS_PER_DATA_WORD),
	parameter OSERDES_DATA_WIDTH = 8,
	parameter TRANSACTIONS_PER_ADDRESS_WORD = 1,
	parameter BANK_ADDRESS_DEPTH = 14,
	parameter LOG2_OF_NUMBER_OF_BANKS = BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD - BANK_ADDRESS_DEPTH,
	parameter NUMBER_OF_BANKS = 1<<LOG2_OF_NUMBER_OF_BANKS,
	parameter LOG2_OF_OSERDES_DATA_WIDTH = $clog2(OSERDES_DATA_WIDTH),
	parameter ADDRESS_DEPTH_OSERDES = BANK_ADDRESS_DEPTH + LOG2_OF_BUS_WIDTH + LOG2_OF_TRANSACTIONS_PER_DATA_WORD - LOG2_OF_OSERDES_DATA_WIDTH,
	parameter ADDRESS_AUTOINCREMENT_MODE = 1,
	parameter TESTBENCH = 0,
	parameter WRITE_STROBE_PICKOFF = 17, // about 1 kHz
	parameter COUNTER50_BIT_PICKOFF = TESTBENCH ? 5 : 23,
	parameter COUNTERWORD_BIT_PICKOFF = TESTBENCH ? 5 : 23
) (
	input clock50_p, clock50_n,
	input clock10,
	input reset,
	inout [5:0] coax,
	input [2:0] rot,
	inout [BUS_WIDTH-1:0] bus,
	input read, // 0=write; 1=read
	input register_select, // 0=address; 1=data
	input enable, // 1=active; 0=inactive
	output ack_valid,
	output [11:0] diff_pair_left,
	output [11:0] diff_pair_right,
	inout [5:0] single_ended_left,
	inout [5:0] single_ended_right,
	output [3:0] coax_led,
	output [7:0] led
);
	wire [3:0] status4;
	wire [7:0] status8;
	genvar i;
	wire pll_oserdes_locked;
	wire pll_oserdes_locked_2;
	for (i=0; i<12; i=i+1) begin : diff_pair_array
		assign diff_pair_left[i] = 0;
		assign diff_pair_right[i] = 0;
	end
	assign single_ended_left[5:2] = 0;
	assign single_ended_left[0] = 0;
	assign single_ended_right[5] = 0;
	assign single_ended_right[1:0] = 0;
	//for (i=0; i<6; i=i+1) begin : single_ended_array
		//assign single_ended_left[i] = 0;
		//assign single_ended_right[i] = 0;
	//end
	// ----------------------------------------------------------------------
	wire reset50;
	wire clock50;
	IBUFGDS mybuf0 (.I(clock50_p), .IB(clock50_n), .O(clock50));
	wire word_clock0;
	wire word_clock1;
	wire clock = word_clock0;
	// ----------------------------------------------------------------------
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER50_BIT_PICKOFF)) reset50_wait4pll (.reset_input(reset), .pll_locked_input(1'b1), .clock_input(clock50), .reset_output(reset50));
	wire reset_word0;
	wire reset_word1;
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset_input(reset50), .pll_locked_input(pll_oserdes_locked), .clock_input(word_clock0), .reset_output(reset_word0));
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword1_wait4pll (.reset_input(reset50), .pll_locked_input(pll_oserdes_locked), .clock_input(word_clock1), .reset_output(reset_word1));
	// ----------------------------------------------------------------------
	wire [BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD-1:0] address_word_full;
	wire [BANK_ADDRESS_DEPTH-1:0] address_word_narrow = address_word_full[BANK_ADDRESS_DEPTH-1:0];
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] write_data_word;
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] read_data_word [NUMBER_OF_BANKS-1:0];
	wire [LOG2_OF_NUMBER_OF_BANKS-1:0] bank;
	wire [LOG2_OF_NUMBER_OF_BANKS-1:0] write_strobe;
	wire [31:0] hdrb_read_errors;
	wire [31:0] hdrb_write_errors;
	wire [31:0] hdrb_address_errors;
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
	wire [7:0] iserdes_word;
	wire [7:0] iserdes_word_buffer;
	wire [7:0] iserdes_word_buffer0;
	wire [7:0] iserdes_word_buffer_delayed;
	wire [ADDRESS_DEPTH_OSERDES-1:0] read_address; // in 8-bit words
	wire [31:0] bank1 [15:0];
	wire [31:0] bank2 [15:0];
	reg [WRITE_STROBE_PICKOFF:0] counter = 0;
	reg write_strobe_b = 0;
//	reg sample_histogram = 0;
	always @(posedge word_clock0) begin
		write_strobe_b <= 0;
//		sample_histogram <= 0;
		if (reset_word0) begin
			counter <= 0;
		end else begin
			if (counter[WRITE_STROBE_PICKOFF:0]==0) begin
				write_strobe_b <= 1;
//				sample_histogram <= 1;
			end
			counter <= counter + 1'b1;
		end
	end
	if (0) begin
		if (BANK_ADDRESS_DEPTH==12) begin
			RAM_s6_4k_32bit_8bit #(.ENDIANNESS("BIG")) mem0 (.reset(reset_word0),
				.clock_a(word_clock0), .address_a(address_word_narrow), .data_in_a(write_data_word), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0]),
				.clock_b(word_clock0), .address_b(read_address), .data_out_b(potential_oserdes_word[0]));
			RAM_s6_4k_32bit_8bit #(.ENDIANNESS("BIG")) mem1 (.reset(reset_word0),
				.clock_a(word_clock0), .address_a(address_word_narrow), .data_in_a(write_data_word), .write_enable_a(write_strobe[1]), .data_out_a(read_data_word[1]),
				.clock_b(word_clock0), .address_b(read_address), .data_out_b(potential_oserdes_word[1]));
			RAM_s6_4k_32bit_8bit #(.ENDIANNESS("BIG")) mem2 (.reset(reset_word0),
				.clock_a(word_clock0), .address_a(address_word_narrow), .data_in_a(write_data_word), .write_enable_a(write_strobe[2]), .data_out_a(read_data_word[2]),
				.clock_b(word_clock0), .address_b(read_address), .data_out_b(potential_oserdes_word[2]));
			RAM_s6_4k_32bit_8bit #(.ENDIANNESS("BIG")) mem3 (.reset(reset_word0),
				.clock_a(word_clock0), .address_a(address_word_narrow), .data_in_a(write_data_word), .write_enable_a(write_strobe[3]), .data_out_a(read_data_word[3]),
				.clock_b(word_clock0), .address_b(read_address), .data_out_b(potential_oserdes_word[3]));
		end else if (BANK_ADDRESS_DEPTH==13) begin
			RAM_s6_8k_32bit_8bit #(.ENDIANNESS("BIG")) mem0 (.reset(reset_word0),
				.clock_a(word_clock0), .address_a(address_word_narrow), .data_in_a(write_data_word), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0]),
				.clock_b(word_clock0), .address_b(read_address), .data_out_b(potential_oserdes_word[0]));
			RAM_s6_8k_32bit_8bit #(.ENDIANNESS("BIG")) mem1 (.reset(reset_word0),
				.clock_a(word_clock0), .address_a(address_word_narrow), .data_in_a(write_data_word), .write_enable_a(write_strobe[1]), .data_out_a(read_data_word[1]),
				.clock_b(word_clock0), .address_b(read_address), .data_out_b(potential_oserdes_word[1]));
		end else begin
			RAM_s6_16k_32bit_8bit #(.ENDIANNESS("BIG")) mem (.reset(reset_word0),
				.clock_a(word_clock0), .address_a(address_word_narrow), .data_in_a(write_data_word), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0]),
				.clock_b(word_clock0), .address_b(read_address), .data_out_b(potential_oserdes_word[0]));
		end
	end else begin
	for (i=3; i<NUMBER_OF_BANKS; i=i+1) begin : fakebanks
		assign read_data_word[i] = 0;
	end
	for (i=1; i<NUMBER_OF_BANKS; i=i+1) begin : banksfake
		assign potential_oserdes_word[i] = 0;
	end
		RAM_s6_4k_32bit_8bit #(.ENDIANNESS("BIG")) mem_bank0 (.reset(reset_word0),
			.clock_a(word_clock0), .address_a(address_word_narrow), .data_in_a(write_data_word), .write_enable_a(write_strobe[0]), .data_out_a(read_data_word[0]),
			.clock_b(word_clock0), .address_b(read_address), .data_out_b(potential_oserdes_word[0]));
		RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank1 (.clock(word_clock0), .reset(reset_word0),
			.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[1]),
			.data_in_b_0(bank1[0]),  .data_in_b_1(bank1[1]),  .data_in_b_2(bank1[2]),  .data_in_b_3(bank1[3]),
			.data_in_b_4(bank1[4]),  .data_in_b_5(bank1[5]),  .data_in_b_6(bank1[6]),  .data_in_b_7(bank1[7]),
			.data_in_b_8(bank1[8]),  .data_in_b_9(bank1[9]),  .data_in_b_a(bank1[10]), .data_in_b_b(bank1[11]),
			.data_in_b_c(bank1[12]), .data_in_b_d(bank1[13]), .data_in_b_e(bank1[14]), .data_in_b_f(bank1[15]),
			.write_strobe_b(write_strobe_b));
		RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank2 (.clock(word_clock0), .reset(reset_word0),
			.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[2]),
			.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[2]),
			.data_out_b_0(bank2[0]),  .data_out_b_1(bank2[1]),  .data_out_b_2(bank2[2]),  .data_out_b_3(bank2[3]),
			.data_out_b_4(bank2[4]),  .data_out_b_5(bank2[5]),  .data_out_b_6(bank2[6]),  .data_out_b_7(bank2[7]),
			.data_out_b_8(bank2[8]),  .data_out_b_9(bank2[9]),  .data_out_b_a(bank2[10]), .data_out_b_b(bank2[11]),
			.data_out_b_c(bank2[12]), .data_out_b_d(bank2[13]), .data_out_b_e(bank2[14]), .data_out_b_f(bank2[15]));
	end
	wire [2:0] rot_pipeline;
	localparam LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE = 12;
	localparam PADDING = 24 - LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE;
	wire [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count [3:0];
	wire [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] pipelined_count [3:0];
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] previous_count [3:0];
	wire [OSERDES_DATA_WIDTH-1:0] result [3:0];
	wire [OSERDES_DATA_WIDTH-1:0] pipelined_result [3:0];
	reg [OSERDES_DATA_WIDTH-1:0] previous_result [3:0];
	wire max_count_reached;
	wire adding_finished;
	wire result_valid;
	wire [3:0] histogram_status4 = { 1'b0, result_valid, adding_finished, max_count_reached };
	wire [31:0] histogram_error_count;
	assign bank1[0]  = { oserdes_word[3], oserdes_word[2], oserdes_word[1], oserdes_word[0] };
	assign bank1[1]  = { oserdes_word_delayed, 8'd0, oserdes_word1_buffer, oserdes_word1_buffer_delayed };
	assign bank1[2]  = { iserdes_word, 8'd0, iserdes_word_buffer, iserdes_word_buffer_delayed };
	assign bank1[3]  = hdrb_read_errors;
	assign bank1[4]  = hdrb_write_errors;
	assign bank1[5]  = hdrb_address_errors;
	assign bank1[6]  = { 1'd0, rot_pipeline, 4'h0, histogram_status4, 4'd0, status4, status8 };
	assign bank1[7]  = histogram_error_count;
	assign bank1[8]  = { {PADDING{1'b0}}, previous_count[0], previous_result[0] };
	assign bank1[9]  = { {PADDING{1'b0}}, previous_count[1], previous_result[1] };
	assign bank1[10] = { {PADDING{1'b0}}, previous_count[2], previous_result[2] };
	assign bank1[11] = { {PADDING{1'b0}}, previous_count[3], previous_result[3] };
	assign bank1[12] = { {PADDING{1'b0}},          count[0],          result[0] };
	assign bank1[13] = { {PADDING{1'b0}},          count[1],          result[1] };
	assign bank1[14] = { {PADDING{1'b0}},          count[2],          result[2] };
	assign bank1[15] = { {PADDING{1'b0}},          count[3],          result[3] };
	wire  [2:0] bitslip_iserdes           = bank2[0][2:0];
	wire  [2:0] bitslip_oserdes1          = bank2[1][2:0];
//	wire  [2:0] bitslip_oserdes1_again    = bank2[2][2:0];
	(* KEEP = "TRUE" *)
	wire  [1:0] word_clock_sel            = bank2[3][1:0];
	wire        train_oserdes             = bank2[4][0];
	wire  [7:0] train_oserdes_pattern     = bank2[5][7:0];
	wire [31:0] start_sample              = bank2[6][31:0];
	wire [31:0] end_sample                = bank2[7][31:0];
	wire        enable_histogram_sampling = bank2[8][0];
	wire        clear_histogram_results   = bank2[8][1];
	pipeline #(.WIDTH(8), .DEPTH(3)) kings (.clock(word_clock0), .in(iserdes_word_buffer), .out(iserdes_word_buffer0));
	localparam RESULT_VALID_PIPELINE_PICKOFF = 1;
	reg [RESULT_VALID_PIPELINE_PICKOFF:0] result_valid_pipeline = 0;
	pipeline #(.WIDTH(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE), .DEPTH(RESULT_VALID_PIPELINE_PICKOFF+1)) kongs0 (.clock(word_clock0), .in(count[0]), .out(pipelined_count[0]));
	pipeline #(.WIDTH(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE), .DEPTH(RESULT_VALID_PIPELINE_PICKOFF+1)) kongs1 (.clock(word_clock0), .in(count[1]), .out(pipelined_count[1]));
	pipeline #(.WIDTH(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE), .DEPTH(RESULT_VALID_PIPELINE_PICKOFF+1)) kongs2 (.clock(word_clock0), .in(count[2]), .out(pipelined_count[2]));
	pipeline #(.WIDTH(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE), .DEPTH(RESULT_VALID_PIPELINE_PICKOFF+1)) kongs3 (.clock(word_clock0), .in(count[3]), .out(pipelined_count[3]));
	pipeline #(.WIDTH(OSERDES_DATA_WIDTH), .DEPTH(RESULT_VALID_PIPELINE_PICKOFF+1)) mothra0 (.clock(word_clock0), .in(result[0]), .out(pipelined_result[0]));
	pipeline #(.WIDTH(OSERDES_DATA_WIDTH), .DEPTH(RESULT_VALID_PIPELINE_PICKOFF+1)) mothra1 (.clock(word_clock0), .in(result[1]), .out(pipelined_result[1]));
	pipeline #(.WIDTH(OSERDES_DATA_WIDTH), .DEPTH(RESULT_VALID_PIPELINE_PICKOFF+1)) mothra2 (.clock(word_clock0), .in(result[2]), .out(pipelined_result[2]));
	pipeline #(.WIDTH(OSERDES_DATA_WIDTH), .DEPTH(RESULT_VALID_PIPELINE_PICKOFF+1)) mothra3 (.clock(word_clock0), .in(result[3]), .out(pipelined_result[3]));
	for (i=0; i<4; i=i+1) begin : previous_histogram
		always @(posedge word_clock0) begin
			if (reset_word0) begin
				previous_count[i] <= 0;
				previous_result[i] <= 0;
			end else begin
				if (result_valid_pipeline[RESULT_VALID_PIPELINE_PICKOFF -: 2]==2'b10) begin
					previous_count[i] <= pipelined_count[i];
					previous_result[i] <= pipelined_result[i];
				end
			end
		end
	end
	always @(posedge word_clock0) begin
		if (reset_word0) begin
			result_valid_pipeline <= 0;
		end else begin
			result_valid_pipeline <= { result_valid_pipeline[RESULT_VALID_PIPELINE_PICKOFF-1:0], result_valid };
		end
	end
	histogram #(.DATA_WIDTH(OSERDES_DATA_WIDTH), .LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE), .USE_BLOCK_MEMORY(1)) h1n1 (
	//histogram #(.DATA_WIDTH(OSERDES_DATA_WIDTH), .LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE), .USE_BLOCK_MEMORY(0)) h1n1 (
	//histogram_original #(.DATA_WIDTH(OSERDES_DATA_WIDTH), .LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE)) h1n1 (
		.clock(word_clock0), .reset(reset_word0), .clear_results(clear_histogram_results), .data_in(iserdes_word_buffer0), .sample(enable_histogram_sampling),
		.result00(result[0]), .result01(result[1]), .result02(result[2]), .result03(result[3]),
		.count00(count[0]), .count01(count[1]), .count02(count[2]), .count03(count[3]),
		.max_count_reached(max_count_reached), .adding_finished(adding_finished), .result_valid(result_valid), .error_count(histogram_error_count));
	for (i=0; i<NUMBER_OF_BANKS; i=i+1) begin : train_or_regular
		assign oserdes_word[i] = train_oserdes ? train_oserdes_pattern : potential_oserdes_word[i];
	end
	wire sync_read_address; // assert this when you feel like (re)synchronizing
	wire [3:0] sync_out_stream; // sync_out_stream[2] is usually good
	wire [7:0] sync_out_word; // dump this in to one of the outputs in a multi-lane oserdes module to get a sync bit that is precisely aligned with your data
	wire [7:0] sync_out_word_delayed; // dump this in to one of the outputs in a multi-lane oserdes module to get a sync bit that is precisely aligned with your data
	sequencer_sync #(.ADDRESS_DEPTH_OSERDES(ADDRESS_DEPTH_OSERDES), .LOG2_OF_OSERDES_DATA_WIDTH(LOG2_OF_OSERDES_DATA_WIDTH)) ss (.clock(word_clock0), .reset(reset_word0), .sync_read_address(sync_read_address), .start_sample(start_sample), .end_sample(end_sample), .read_address(read_address), .sync_out_stream(sync_out_stream), .sync_out_word(sync_out_word));
	cdc_pipeline #(.WIDTH(3), .DEPTH(3)) tongs (.clock(word_clock0), .in(~rot), .out(rot_pipeline));
	cdc_pipeline #(.WIDTH(8), .DEPTH(3)) publics (.clock(word_clock1), .in(iserdes_word), .out(iserdes_word_buffer));
	bitslip #(.WIDTH(8)) bsi (.clock(word_clock1), .bitslip(bitslip_iserdes), .data_in(iserdes_word_buffer), .data_out(iserdes_word_buffer_delayed));
	// use coax[0] and coax[4] to measure (with scope) and correct (with rotary switch) for the "arbitrary routing" bitslip which is compile-dependent
	// or send oserdes stream out of "v" and into iserdes on "q" (with an ezhook) or stream out of "r" and into "q" (with a jumper) and then see the result oserdes on coax[5] (measured delay from coax[4] to coax[5] is ~43 ns; with pipelining and a bitslip, this can be adjusted to be 0 ns delay)
	localparam DELAY = 7;
	pipeline #(.WIDTH(8), .DEPTH(DELAY+4)) queens (.clock(word_clock0), .in(oserdes_word[0]), .out(oserdes_word_delayed));
	pipeline #(.WIDTH(8), .DEPTH(DELAY+4)) diamond_head (.clock(word_clock0), .in(sync_out_word), .out(sync_out_word_delayed));
	bitslip #(.WIDTH(8)) bso1 (.clock(word_clock1), .bitslip(bitslip_oserdes1), .data_in(oserdes_word[0]), .data_out(oserdes_word1_buffer));
	pipeline #(.WIDTH(8), .DEPTH(DELAY)) kewalos (.clock(word_clock1), .in(oserdes_word1_buffer), .out(oserdes_word1_buffer_delayed));
//	bitslip #(.WIDTH(8)) bso2 (.clock(word_clock1), .bitslip(bitslip_oserdes1_again), .data_in(oserdes_word1_buffer_mid), .data_out(oserdes_word1_buffer_delayed));
	//pipeline #(.WIDTH(8), .DEPTH(DELAY)) canoes (.clock(word_clock1), .in(sync_out_word1_buffer), .out(sync_out_word1_buffer1));
	wire pre_coax_4;
	ocyrus_hex8_split_4_2 #(.BIT_DEPTH(8), .PERIOD(20.0), .MULTIPLY(20), .DIVIDE(1), .SCOPE("BUFPLL"), .PINTYPE3("n"), .PHASE45(0.0)) mylei6 (
		.clock_in(clock50), .reset(reset50), .word_clock0123_out(word_clock1), .locked(pll_oserdes_locked),
		.word_clock45_sel(word_clock_sel[1:0]), .word_clock45_out(word_clock0),
		.word0_in(oserdes_word1_buffer_delayed), .word1_in(oserdes_word1_buffer), .word2_in(oserdes_word1_buffer), .word3_in(iserdes_word_buffer_delayed),
		.word4_in(oserdes_word_delayed), .word5_in(sync_out_word_delayed),
		.D0_out(pre_coax_4), .D1_out(single_ended_left[1]), .D2_out(single_ended_right[2]), .D3_out(coax[5]),
		//.D0_out(pre_coax_4), .D1_out(single_ended_left[1]), .D2_out(), .D3_out(coax[5]),
		.D4_out(coax[0]), .D5_out(coax[3]),
		.iserdes_bit_input(single_ended_right[3]), .iserdes_word_out(iserdes_word));
	assign coax[4] = pre_coax_4; // -38 ps (sigma 16 ps) 15.png
	ddr mario1 (.clock(word_clock1), .reset(reset), .data0_in(1'b0), .data1_in(1'b1), .data_out(coax[2]));
	ddr mario2 (.clock(word_clock0), .reset(reset), .data0_in(1'b0), .data1_in(1'b1), .data_out(coax[1]));
	if (0) begin // to test the rpi interface to the read/write pollable memory
		assign coax[4] = enable; // scope trigger
		assign coax[5] = write_strobe[0];
		assign pll_oserdes_locked_2 = 1;
	end else if (0) begin // to put the oserdes outputs on coax[4] and coax[5]
		ocyrus_double8 #(.BIT_DEPTH(8), .PERIOD(20.0), .MULTIPLY(20), .DIVIDE(1), .SCOPE("BUFPLL")) mylei2 (
			.clock_in(clock50), .reset(reset50), .word_clock_out(),
			.word1_in(oserdes_word[0]), .D1_out(coax[5]),
			.word0_in(oserdes_word[0]), .D0_out(coax[4]),
			.bit_clock(), .bit_strobe(),
			.locked(pll_oserdes_locked_2));
		assign sync_read_address = 0;
	end else if (0) begin
		ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(20.0), .MULTIPLY(20), .DIVIDE(1), .SCOPE("BUFPLL"), .PINTYPE("n")) mylei (.clock_in(clock50), .reset(reset50), .word_clock_out(), .word_in(oserdes_word[0]), .D_out(coax[5]), .locked(pll_oserdes_locked_2));
		assign coax[4] = sync_out_stream[2]; // scope trigger
		assign sync_read_address = 0;
	end else if (1) begin
		//ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(20.0), .MULTIPLY(20), .DIVIDE(1), .SCOPE("BUFPLL")) mylei1 (.clock_in(clock50), .reset(reset50), .word_clock_out(), .word_in(oserdes_word[0]), .D_out(coax[4]), .locked(pll_oserdes_locked_2));
		//assign sync_read_address = coax[5];
		assign sync_read_address = 0;
		//assign coax[5] = sync_out_stream[2]; // scope trigger
		assign pll_oserdes_locked_2 = 1;
	end else begin // to synchronize the coax outputs and to trigger the scope on that synchronization
		assign coax[4] = sync_out_stream[2]; // scope trigger
		assign sync_read_address = coax[5]; // an input to synchronize to an external event
		assign pll_oserdes_locked_2 = 1;
	end
	// ----------------------------------------------------------------------
	//assign status4[2:0] = rot_pipeline;
	//assign status4 = reset_counter;
	//assign status4 = 4'b1001;
	//assign status4[0] = 1'b1;
	//assign status4[3] = 1'b1;
	//assign status4[2] = 0;
	//assign status4[3] = 0;
	assign status4[3:0] = bank;
	assign status8[7] = reset50;
	assign status8[6] = ~pll_oserdes_locked;
	assign status8[5] = reset_word0;
	assign status8[4] = reset_word1;
	assign status8[3] = ack_valid;
	assign status8[2] = read;
	assign status8[1] = enable;
	assign status8[0] = register_select;
	if (0) begin
//		assign led = status8;
		cdc_pipeline #(.WIDTH(8), .DEPTH(2)) blinx (.clock(clock50), .in(status8), .out(led));
	end
	if (1) begin
		cdc_pipeline #(.WIDTH(4), .DEPTH(2)) jarjar (.clock(clock50), .in(status4), .out(coax_led));
	end
	// ----------------------------------------------------------------------
	initial begin
		#100;
		$display("%d = %d + %d + %d - %d", ADDRESS_DEPTH_OSERDES, BANK_ADDRESS_DEPTH, LOG2_OF_BUS_WIDTH, LOG2_OF_TRANSACTIONS_PER_DATA_WORD, LOG2_OF_OSERDES_DATA_WIDTH);
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
	localparam BANK_ADDRESS_DEPTH = 14;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	reg clock50_p = 0;
	reg clock50_n = 1;
	reg clock10 = 0;
	reg reset = 0;
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
	top #(.BUS_WIDTH(BUS_WIDTH), .BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH), .TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD), .TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD), .ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE), .TESTBENCH(1)) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10), .reset(reset),
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
		#300; reset <= 1; #300; reset <= 0;
		#512; // wait for reset50
		#512; // wait for reset125
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
		#300; reset <= 1; #300; reset <= 0;
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
		clock50_p <= #1.5 ~clock50_p;
		clock50_n <= #2.5 ~clock50_n;
	end
	always begin
		#HALF_PERIOD_OF_CONTROLLER;
		clock <= #0.625 ~clock;
	end
endmodule

module myalthea (
	input clock50_p, clock50_n,
	inout [5:0] coax,
	// other IOs:
	output rpi_gpio2_i2c1_sda, // ack_valid
	input rpi_gpio3_i2c1_scl, // register_select
	input rpi_gpio4_gpclk0, // enable
	input rpi_gpio5, // read
	input rpi_gpio26, // spare
	// 16 bit bus:
	inout rpi_gpio6_gpclk2, rpi_gpio7_spi_ce1, rpi_gpio8_spi_ce0, rpi_gpio9_spi_miso,
	inout rpi_gpio10_spi_mosi, rpi_gpio11_spi_sclk, rpi_gpio12, rpi_gpio13,
	inout rpi_gpio14, rpi_gpio15, rpi_gpio16, rpi_gpio17,
	inout rpi_gpio18, rpi_gpio19, rpi_gpio20, rpi_gpio21,
	// diff-pair IOs (toupee connectors):
	a_p, a_n, b_p, b_n, c_p, c_n,
	d_p, d_n, e_p, e_n, f_p, f_n,
	g_p, g_n, h_p, h_n, j_p, j_n,
	k_p, k_n, l_p, l_n, m_p, m_n,
	// single-ended IOs (toupee connectors):
	n, p, q, r, s, t,
	u, v, w, x, y, z,
	// other IOs:
	input button, // reset
	output [3:0] coax_led,
//	output [7:0] led,
	input [2:0] rot
);
	localparam BUS_WIDTH = 16;
	localparam BANK_ADDRESS_DEPTH = 12;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	wire clock10 = 0;
	wire [3:0] internal_coax_led;
	wire [7:0] internal_led;
//	assign led = internal_led;
	assign coax_led = internal_coax_led;
	top #(
		.TESTBENCH(0),
		.BUS_WIDTH(BUS_WIDTH), .BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10), .reset(~button),
		.coax(coax),
		.bus({
			rpi_gpio21, rpi_gpio20, rpi_gpio19, rpi_gpio18,
			rpi_gpio17, rpi_gpio16, rpi_gpio15, rpi_gpio14,
			rpi_gpio13, rpi_gpio12, rpi_gpio11_spi_sclk, rpi_gpio10_spi_mosi,
			rpi_gpio9_spi_miso, rpi_gpio8_spi_ce0, rpi_gpio7_spi_ce1, rpi_gpio6_gpclk2
		}),
		.diff_pair_left({ a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p, b_n, b_p, e_n, e_p }),
		.diff_pair_right({ g_n, g_p, j_n, j_p, l_n, l_p, m_n, m_p, h_n, h_p, k_n, k_p }),
		.single_ended_left({ z, y, x, w, v, u }),
		.single_ended_right({ n, p, q, r, s, t }),
		.register_select(rpi_gpio3_i2c1_scl), .read(rpi_gpio5),
		.enable(rpi_gpio4_gpclk0), .ack_valid(rpi_gpio2_i2c1_sda),
		.coax_led(internal_coax_led),
		.led(internal_led),
		.rot(rot)
	);
endmodule

