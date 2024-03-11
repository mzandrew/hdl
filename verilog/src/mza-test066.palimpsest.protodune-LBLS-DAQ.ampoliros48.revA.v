// written 2024-03-08 by mza
// based on mza-test058.palimpsest.protodune-LBLS-DAQ.althea.revBLM.v
// last updated 2024-03-11 by mza

`define ampoliros48_revA
`include "lib/generic.v"
`include "lib/RAM8.v"
`include "lib/fifo.v"
//`include "lib/RAM.sv" // ise does not and will not support systemverilog
`include "lib/plldcm.v"
`include "lib/serdes_pll.v"
`include "lib/half_duplex_rpi_bus.v"
`include "lib/sequencer.v"
`include "lib/reset.v"
`include "lib/edge_to_pulse.v"
`include "lib/frequency_counter.v"

module LBLS_bank #(
	parameter SCALER_WIDTH = 32
) (
	input clock, reset,
	input [12:1] hit_mask,
	input [12:1] inversion_mask,
	input gate, clear_channel_ones_counters, trigger_active,
	input [7:0] win1, win2, win3, win4, win5, win6, win7, win8, win9, win10, win11, win12,
	output [31:0] sc1, sc2, sc3, sc4, sc5, sc6, sc7, sc8, sc9, sc10, sc11, sc12,
	output reg any = 0
);
	genvar i;
	wire [7:0] word [12:1];
	assign word[1] = win1; assign word[2]  = win2;  assign word[3]  = win3;  assign word[4]  = win4;
	assign word[5] = win5; assign word[6]  = win6;  assign word[7]  = win7;  assign word[8]  = win8;
	assign word[9] = win9; assign word[10] = win10; assign word[11] = win11; assign word[12] = win12;
	wire [7:0] word_maybe_inverted [12:1];
	wire [7:0] word_maybe_inverted_and_maybe_masked [12:1];
	reg [7:0] word_buffered_and_maybe_inverted_a [12:1];
	reg [7:0] word_buffered_and_maybe_inverted_b [12:1];
	for (i=1; i<=12; i=i+1) begin : raw_readout_registers_mapping
//		assign bank0[i] = { 8'd0, channel_ones_counter[i] };
//		assign bank1[i] = { word_buffered_and_maybe_inverted_a[i], word_maybe_inverted_and_maybe_masked[i], word_maybe_inverted[i], word[i] };
		assign word_maybe_inverted[i] = word[i] ^ {8{inversion_mask[i]}};
		assign word_maybe_inverted_and_maybe_masked[i] = (word[i] ^ {8{inversion_mask[i]}}) & {8{hit_mask[i]&gate}};
	end
//	wire [31:0] channel_counter [12:1];
//	reg [12:1] suggested_inversion_map;
//	for (i=1; i<=12; i=i+1) begin : channel_counter_scaler_mapping
//		assign bank6[i] = channel_counter[i];
//		iserdes_counter #(.BIT_DEPTH(8), .REGISTER_WIDTH(32)) channel_counter (.clock(clock), .reset(clear_channel_counters), .in(word_maybe_inverted[i]), .out(channel_counter[i]));
//		assign bank7[i] = channel_scaler_a[i] + channel_scaler_b[i] + channel_scaler_c[i] + channel_scaler_d[i];
//		iserdes_scaler #(.BIT_DEPTH(8), .REGISTER_WIDTH(32), .CLOCK_PERIODS_TO_ACCUMULATE(2500000)) channel_scaler_a (.clock(clock), .reset(1'b0), .in(word_maybe_inverted[i]), .out(channel_scaler_a[i]));
//	end
	iserdes_scaler_array12 #(.BIT_DEPTH(8), .REGISTER_WIDTH(SCALER_WIDTH), .CLOCK_PERIODS_TO_ACCUMULATE(2500000), .NUMBER_OF_CHANNELS(12)) channel_scaler_a_array12 (.clock(clock), .reset(1'b0),
		.in01(word_maybe_inverted[1]), .in02(word_maybe_inverted[2]), .in03(word_maybe_inverted[3]), .in04(word_maybe_inverted[4]),
		.in05(word_maybe_inverted[5]), .in06(word_maybe_inverted[6]), .in07(word_maybe_inverted[7]), .in08(word_maybe_inverted[8]),
		.in09(word_maybe_inverted[9]), .in10(word_maybe_inverted[10]), .in11(word_maybe_inverted[11]), .in12(word_maybe_inverted[12]),
		.out01(sc1), .out02(sc2),  .out03(sc3),  .out04(sc4),
		.out05(sc5), .out06(sc6),  .out07(sc7),  .out08(sc8),
		.out09(sc9), .out10(sc10), .out11(sc11), .out12(sc12)
	);
	reg [12:1] iserdes_word_hit;
	for (i=1; i<=12; i=i+1) begin : iserdes_buffer_1_mapping
		always @(posedge clock) begin
			if (reset) begin
				word_buffered_and_maybe_inverted_a[i] <= 0;
			end else begin
				//word_buffered_and_maybe_inverted_a[i] <= {8{|hitmask[i]}} & ~word[i];
				//word_buffered_and_maybe_inverted_a[i] <= {8{hit_mask[i] & inversion_mask[i]}} ^ word[i];
				//word_buffered_and_maybe_inverted_a[i] <= (word[i] ^ {8{inversion_mask[i]}}) & {8{hit_mask[i]&gate}};
				word_buffered_and_maybe_inverted_a[i] <= word_maybe_inverted_and_maybe_masked[i];
			end
		end
	end
	for (i=1; i<=12; i=i+1) begin : iserdes_buffer_2_mapping
		always @(posedge clock) begin
			if (reset) begin
				word_buffered_and_maybe_inverted_b[i] <= 0;
			end else begin
				word_buffered_and_maybe_inverted_b[i] <= word_buffered_and_maybe_inverted_a[i];
			end
		end
	end
	for (i=1; i<=12; i=i+1) begin : iserdes_word_hit_mapping
		always @(posedge clock) begin
			if (reset) begin
				iserdes_word_hit[i] <= 0;
			end else begin
				//iserdes_word_hit[i] <= |hitmask[i] && ~|word[i]; // this result will be available when word_buffered_and_maybe_inverted_a corresponds
				//iserdes_word_hit[i] <= hit_mask[i] & inversion_mask[i] ^ (|word[i]); // this result will be available when word_buffered_and_maybe_inverted_a corresponds
				//iserdes_word_hit[i] <= ((|word[i]) ^ inversion_mask[i]) & hit_mask[i] & gate; // this result will be available when word_buffered_and_maybe_inverted_a corresponds
				iserdes_word_hit[i] <= |word_maybe_inverted_and_maybe_masked[i];
			end
		end
	end
	for (i=1; i<=12; i=i+1) begin : channel_ones_counter_adder
		always @(posedge clock) begin
			if (reset) begin
				channel_ones_counter[i] <= 0;
			end else begin
				if (clear_channel_ones_counters) begin
					channel_ones_counter[i] <= 0;
				end else begin
					if (channel_ones_counter[i]<channel_ones_counter_max_count) begin
						channel_ones_counter[i] <= channel_ones_counter[i] + word_ones_counter_before[i];
					end else begin
						channel_ones_counter[i] <= channel_ones_counter_max_count;
					end
				end
			end
		end
	end
//	for (i=1; i<=12; i=i+1) begin : suggested_inversion_map_mapping
//		always @(posedge clock) begin
//			if (reset) begin
//				suggested_inversion_map[i] <= 0;
//			end else begin
//				if (channel_ones_counter_suggestion_threshold<channel_ones_counter[i]) begin
//					suggested_inversion_map[i] <= 1'b1;
//				end else begin
//					suggested_inversion_map[i] <= 0;
//				end
//			end
//		end
//	end
//	wire [255:0] [12:1];
	reg [7:0] previous_time_over_threshold [12:1];
	reg [7:0] time_over_threshold [12:1];
	localparam CHANNEL_ONES_COUNTER_NUMBER_OF_BITS = 24;
	reg [CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-1:0] channel_ones_counter [12:1];
	wire [CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-1:0] channel_ones_counter_max_count;
	wire [CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-1:0] channel_ones_counter_suggestion_threshold;
	localparam CHANNEL_ONES_COUNTER_UPPER_NYBBLE = 4'he;
	assign channel_ones_counter_suggestion_threshold[CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-1:CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-4] = 0;
	assign channel_ones_counter_suggestion_threshold[CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-5:CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-8] = CHANNEL_ONES_COUNTER_UPPER_NYBBLE;
	assign channel_ones_counter_suggestion_threshold[CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-8:0] = 0;
	assign channel_ones_counter_max_count[CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-1:CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-4] = CHANNEL_ONES_COUNTER_UPPER_NYBBLE;
	assign channel_ones_counter_max_count[CHANNEL_ONES_COUNTER_NUMBER_OF_BITS-5:0] = 0;
	wire [3:0] word_ones_counter_before [12:1];
	wire [3:0] word_ones_counter_after [12:1];
	for (i=1; i<=12; i=i+1) begin : ones_counter_mapping
		count_ones c1s_before (.clock(clock), .data_in(word[i]), .count_out(word_ones_counter_before[i]));
		count_ones c1s_after (.clock(clock), .data_in(word_buffered_and_maybe_inverted_a[i]), .count_out(word_ones_counter_after[i]));
	end
	for (i=1; i<=12; i=i+1) begin : time_over_threshold_mapping
		always @(posedge clock) begin
//			fifo_write_enable[i] <= 0;
			if (reset) begin
				previous_time_over_threshold[i] <= 0;
				time_over_threshold[i] <= 0;
			end else begin
				if (trigger_active) begin
					time_over_threshold[i] <= time_over_threshold[i] + word_ones_counter_after[i];
				end else begin
					previous_time_over_threshold[i] <= time_over_threshold[i];
					if (time_over_threshold[i]) begin
//						fifo_write_enable[i] <= 1;
						time_over_threshold[i] <= 0;
					end
				end
			end
		end
	end
	always @(posedge clock) begin
		if (reset) begin
			any <= 0;
		end else begin
			any <= |iserdes_word_hit; // this result will be available when word_buffered_and_maybe_inverted_b corresponds
		end
	end
endmodule

module LBLS #(
	parameter SCALER_WIDTH = 32,
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
	parameter TESTBENCH = 0,
	parameter COUNTER100_BIT_PICKOFF = TESTBENCH ? 5 : 23,
	parameter COUNTERWORD_BIT_PICKOFF = TESTBENCH ? 5 : 23
) (
	input clock100_p, clock100_n,
	input button,
	inout [BUS_WIDTH-1:0] bus,
	input read, // 0=write; 1=read
	input register_select, // 0=address; 1=data
	input enable, // 1=active; 0=inactive
	output ack_valid,
	output [3:1] outR, outF,
	inout [2:1] inoutM,
	input [3:1] inR, inF,
	output [3:1] tR, tF,
	output a_p, b_p, c_p, d_p, e_p, f_p, a_n, b_n, c_n, d_n, e_n, f_n,
	output u, v, w, x, y, z,
	input [12:1] a, b, c, d,
	output ldac, ampen
);
	genvar i;
	// PLL_ADV VCO range is 400 MHz to 1080 MHz
	localparam PERIOD = 10.0;
	localparam MULTIPLY = 8;
	localparam DIVIDE = 2;
	localparam EXTRA_DIVIDE = 16;
	localparam SCOPE = "BUFPLL"; // "GLOBAL" (400 MHz), "BUFIO2" (525 MHz), "BUFPLL" (1080 MHz)
	localparam ERROR_COUNT_PICKOFF = 7;
	wire [7:0] status8;
	wire reset;
	wire pll_oserdes_locked;
	// ----------------------------------------------------------------------
	wire reset100;
	wire clock100;
	IBUFGDS mybuf0 (.I(clock100_p), .IB(clock100_n), .O(clock100));
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset100_wait4pll (.reset_input(reset), .pll_locked_input(1'b1), .clock_input(clock100), .reset_output(reset100));
	wire word_clock;
	// ----------------------------------------------------------------------
	wire reset_word;
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset_input(reset100), .pll_locked_input(pll_oserdes_locked), .clock_input(word_clock), .reset_output(reset_word));
	// ----------------------------------------------------------------------
	wire [BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD-1:0] address_word_full;
	wire [BANK_ADDRESS_DEPTH-1:0] address_word_narrow = address_word_full[BANK_ADDRESS_DEPTH-1:0];
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] write_data_word;
	wire [BUS_WIDTH*TRANSACTIONS_PER_DATA_WORD-1:0] read_data_word [NUMBER_OF_BANKS-1:0];
	wire [LOG2_OF_NUMBER_OF_BANKS-1:0] bank;
	wire [NUMBER_OF_BANKS-1:0] write_strobe;
	wire [NUMBER_OF_BANKS-1:0] read_strobe;
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
		.read_strobe(read_strobe),
		.write_data_word(write_data_word),
		.read_data_word(read_data_word[bank]),
		.address_word_reg(address_word_full),
		.read_errors(hdrb_read_errors),
		.write_errors(hdrb_write_errors),
		.address_errors(hdrb_address_errors),
		.bank(bank)
	);
	// ----------------------------------------------------------------------
	wire [ADDRESS_DEPTH_OSERDES-1:0] read_address; // in 8-bit words
	wire [31:0] bank0 [15:0];
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank0 (.clock(word_clock), .reset(reset_word),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[0]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[0]),
		.data_out_b_0(bank0[0]),  .data_out_b_1(bank0[1]),  .data_out_b_2(bank0[2]),  .data_out_b_3(bank0[3]),
		.data_out_b_4(bank0[4]),  .data_out_b_5(bank0[5]),  .data_out_b_6(bank0[6]),  .data_out_b_7(bank0[7]),
		.data_out_b_8(bank0[8]),  .data_out_b_9(bank0[9]),  .data_out_b_a(bank0[10]), .data_out_b_b(bank0[11]),
		.data_out_b_c(bank0[12]), .data_out_b_d(bank0[13]), .data_out_b_e(bank0[14]), .data_out_b_f(bank0[15]));
	wire [12:1] hit_mask                        = bank0[0][11:0];
	wire [12:1] inversion_mask                  = bank0[1][11:0];
	wire [31:0] desired_trigger_quantity        = bank0[2][31:0];
	wire [31:0] trigger_duration_in_word_clocks = bank0[3][31:0];
	wire [3:0]  monitor_channel                 = bank0[4];
	wire        clear_gate_counter              = bank0[5][0];
	wire        clear_trigger_count             = bank0[5][1];
	wire        clear_hit_counter               = bank0[5][2];
	wire        clear_channel_counters          = bank0[5][3];
	wire        clear_channel_ones_counters     = bank0[5][4];
	wire [31:0] bank1 [15:0]; // scaler_a[i]
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank1 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[1]),
		.data_in_b_0(bank1[0]),  .data_in_b_1(bank1[1]),  .data_in_b_2(bank1[2]),  .data_in_b_3(bank1[3]),
		.data_in_b_4(bank1[4]),  .data_in_b_5(bank1[5]),  .data_in_b_6(bank1[6]),  .data_in_b_7(bank1[7]),
		.data_in_b_8(bank1[8]),  .data_in_b_9(bank1[9]),  .data_in_b_a(bank1[10]), .data_in_b_b(bank1[11]),
		.data_in_b_c(bank1[12]), .data_in_b_d(bank1[13]), .data_in_b_e(bank1[14]), .data_in_b_f(bank1[15]),
		.write_strobe_b(1'b1));
	assign bank1[0]  = { hdrb_read_errors[7:0], hdrb_write_errors[7:0], hdrb_address_errors[7:0], status8 };
//	assign bank1[13] = trigger_count;
//	assign bank1[14] = suggested_inversion_map;
//	assign bank1[15] = hit_counter_buffered;
	assign bank1[13] = 0;
	assign bank1[14] = 0;
	assign bank1[15] = 0;
//	for (i=1; i<=15; i=i+1) begin : dummy_bank1
//		assign bank1[i] = 0;
//	end
	wire [31:0] bank2 [15:0]; // scaler_b[i]
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank2 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[2]),
		.data_in_b_0(bank2[0]),  .data_in_b_1(bank2[1]),  .data_in_b_2(bank2[2]),  .data_in_b_3(bank2[3]),
		.data_in_b_4(bank2[4]),  .data_in_b_5(bank2[5]),  .data_in_b_6(bank2[6]),  .data_in_b_7(bank2[7]),
		.data_in_b_8(bank2[8]),  .data_in_b_9(bank2[9]),  .data_in_b_a(bank2[10]), .data_in_b_b(bank2[11]),
		.data_in_b_c(bank2[12]), .data_in_b_d(bank2[13]), .data_in_b_e(bank2[14]), .data_in_b_f(bank2[15]),
		.write_strobe_b(1'b1));
	assign bank2[0] = 0;
	assign bank2[13] = 0;
	assign bank2[14] = 0;
	assign bank2[15] = 0;
//	for (i=0; i<=15; i=i+1) begin : dummy_bank2
//		assign bank2[i] = 0;
//	end
	wire [31:0] bank3 [15:0]; // scaler_c[i]
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank3 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[3]),
		.data_in_b_0(bank3[0]),  .data_in_b_1(bank3[1]),  .data_in_b_2(bank3[2]),  .data_in_b_3(bank3[3]),
		.data_in_b_4(bank3[4]),  .data_in_b_5(bank3[5]),  .data_in_b_6(bank3[6]),  .data_in_b_7(bank3[7]),
		.data_in_b_8(bank3[8]),  .data_in_b_9(bank3[9]),  .data_in_b_a(bank3[10]), .data_in_b_b(bank3[11]),
		.data_in_b_c(bank3[12]), .data_in_b_d(bank3[13]), .data_in_b_e(bank3[14]), .data_in_b_f(bank3[15]),
		.write_strobe_b(1'b1));
	assign bank3[0] = 0;
	assign bank3[13] = 0;
	assign bank3[14] = 0;
	assign bank3[15] = 0;
//	for (i=0; i<=15; i=i+1) begin : dummy_bank3
//		assign bank3[i] = 0;
//	end
	wire [31:0] bank4 [15:0]; // scaler_d[i]
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank4 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[4]),
		.data_in_b_0(bank4[0]),  .data_in_b_1(bank4[1]),  .data_in_b_2(bank4[2]),  .data_in_b_3(bank4[3]),
		.data_in_b_4(bank4[4]),  .data_in_b_5(bank4[5]),  .data_in_b_6(bank4[6]),  .data_in_b_7(bank4[7]),
		.data_in_b_8(bank4[8]),  .data_in_b_9(bank4[9]),  .data_in_b_a(bank4[10]), .data_in_b_b(bank4[11]),
		.data_in_b_c(bank4[12]), .data_in_b_d(bank4[13]), .data_in_b_e(bank4[14]), .data_in_b_f(bank4[15]),
		.write_strobe_b(1'b1));
	assign bank4[0] = 0;
	assign bank4[13] = 0;
	assign bank4[14] = 0;
	assign bank4[15] = 0;
//	for (i=0; i<=15; i=i+1) begin : dummy_bank4
//		assign bank4[i] = 0;
//	end
//	reg [12:1] fifo_write_enable;
//	wire [12:1] fifo_read_enable;
//	wire fifo_empty = 0;
/*
	fifo_single_clock_using_single_bram #(.DATA_WIDTH(32), .LOG2_OF_DEPTH(10)) fsc_4321 (.clock(word_clock), .reset(reset_word), .error_count(),
		.data_in({previous_time_over_threshold[4],previous_time_over_threshold[3],previous_time_over_threshold[2],previous_time_over_threshold[1]}),
		.write_enable(|fifo_write_enable), .full(), .almost_full(), .full_or_almost_full(),
		.data_out(read_data_word[3]), .read_enable(read_strobe[3]), .empty(fifo_empty), .almost_empty(), .empty_or_almost_empty());
	fifo_single_clock_using_single_bram #(.DATA_WIDTH(32), .LOG2_OF_DEPTH(10)) fsc_8765 (.clock(word_clock), .reset(reset_word), .error_count(),
		.data_in({previous_time_over_threshold[8],previous_time_over_threshold[7],previous_time_over_threshold[6],previous_time_over_threshold[5]}),
		.write_enable(|fifo_write_enable), .full(), .almost_full(), .full_or_almost_full(),
		.data_out(read_data_word[4]), .read_enable(read_strobe[4]), .empty(), .almost_empty(), .empty_or_almost_empty());
	fifo_single_clock_using_single_bram #(.DATA_WIDTH(32), .LOG2_OF_DEPTH(10)) fsc_cba9 (.clock(word_clock), .reset(reset_word), .error_count(),
		.data_in({previous_time_over_threshold[12],previous_time_over_threshold[11],previous_time_over_threshold[10],previous_time_over_threshold[9]}),
		.write_enable(|fifo_write_enable), .full(), .almost_full(), .full_or_almost_full(),
		.data_out(read_data_word[5]), .read_enable(read_strobe[5]), .empty(), .almost_empty(), .empty_or_almost_empty());
*/
	wire [31:0] bank5 [15:0];
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank5 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[5]),
		.data_in_b_0(bank5[0]),  .data_in_b_1(bank5[1]),  .data_in_b_2(bank5[2]),  .data_in_b_3(bank5[3]),
		.data_in_b_4(bank5[4]),  .data_in_b_5(bank5[5]),  .data_in_b_6(bank5[6]),  .data_in_b_7(bank5[7]),
		.data_in_b_8(bank5[8]),  .data_in_b_9(bank5[9]),  .data_in_b_a(bank5[10]), .data_in_b_b(bank5[11]),
		.data_in_b_c(bank5[12]), .data_in_b_d(bank5[13]), .data_in_b_e(bank5[14]), .data_in_b_f(bank5[15]),
		.write_strobe_b(1'b1));
//	assign bank5[0] = 0;
	for (i=0; i<=15; i=i+1) begin : dummy_bank5
		assign bank5[i] = 0;
	end
	wire [31:0] bank6 [15:0];
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank6 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[6]),
		.data_in_b_0(bank6[0]),  .data_in_b_1(bank6[1]),  .data_in_b_2(bank6[2]),  .data_in_b_3(bank6[3]),
		.data_in_b_4(bank6[4]),  .data_in_b_5(bank6[5]),  .data_in_b_6(bank6[6]),  .data_in_b_7(bank6[7]),
		.data_in_b_8(bank6[8]),  .data_in_b_9(bank6[9]),  .data_in_b_a(bank6[10]), .data_in_b_b(bank6[11]),
		.data_in_b_c(bank6[12]), .data_in_b_d(bank6[13]), .data_in_b_e(bank6[14]), .data_in_b_f(bank6[15]),
		.write_strobe_b(1'b1));
//	assign bank6[0] = 0;
	for (i=0; i<=15; i=i+1) begin : dummy_bank6
		assign bank6[i] = 0;
	end
	wire [31:0] bank7 [15:0];
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank7 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[7]),
		.data_in_b_0(bank7[0]),  .data_in_b_1(bank7[1]),  .data_in_b_2(bank7[2]),  .data_in_b_3(bank7[3]),
		.data_in_b_4(bank7[4]),  .data_in_b_5(bank7[5]),  .data_in_b_6(bank7[6]),  .data_in_b_7(bank7[7]),
		.data_in_b_8(bank7[8]),  .data_in_b_9(bank7[9]),  .data_in_b_a(bank7[10]), .data_in_b_b(bank7[11]),
		.data_in_b_c(bank7[12]), .data_in_b_d(bank7[13]), .data_in_b_e(bank7[14]), .data_in_b_f(bank7[15]),
		.write_strobe_b(1'b1));
//	assign bank7[0] = 32'habcd0000;
//	assign bank7[13] = 32'habcd0013;
//	assign bank7[14] = 32'habcd0014;
//	assign bank7[15] = 32'habcd0015;
	for (i=0; i<=15; i=i+1) begin : dummy_bank7
		assign bank7[i] = 0;
	end
//	for (i=13; i<=15; i=i+1) begin : dummy_bank6_bank7_mapping
//		assign bank6[i] = 32'habcdef06;
//		assign bank7[i] = 32'habcdef07;
//	end
	// ----------------------------------------------------------------------
	assign reset = 0;
	//assign reset = ~button;
	wire any;
	assign ldac = 0;
	assign ampen = 0;
	assign outR[1] = 0;
	assign outR[2] = 0;
	assign outR[3] = 0;
	assign outF[1] = any;
	assign outF[2] = 0;
	assign outF[3] = 0;
	assign tR[1] = 0;
	assign tR[2] = 0;
	assign tR[3] = 0;
	assign tF[1] = 0;
	assign tF[2] = 0;
	assign tF[3] = 0;
	wire [31:0] start_sample = 0;
	wire [31:0] end_sample = 5120;
	wire sync_read_address; // assert this when you feel like (re)synchronizing
	localparam SYNC_OUT_STREAM_PICKOFF = 2;
	wire [SYNC_OUT_STREAM_PICKOFF:0] sync_out_stream; // sync_out_stream[2] is usually good
	wire [7:0] sync_out_word; // dump this in to one of the outputs in a multi-lane oserdes module to get a sync bit that is precisely aligned with your data
	wire [7:0] sync_out_word_delayed; // dump this in to one of the outputs in a multi-lane oserdes module to get a sync bit that is precisely aligned with your data
	sequencer_sync #(.ADDRESS_DEPTH_OSERDES(ADDRESS_DEPTH_OSERDES), .LOG2_OF_OSERDES_DATA_WIDTH(LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH), .SYNC_OUT_STREAM_PICKOFF(SYNC_OUT_STREAM_PICKOFF)) ss (.clock(word_clock), .reset(reset_word), .sync_read_address(sync_read_address), .start_sample(start_sample), .end_sample(end_sample), .read_address(read_address), .sync_out_stream(sync_out_stream), .sync_out_word(sync_out_word));
	if (0) begin // to test the rpi interface to the read/write pollable memory
	end else if (1) begin
		assign sync_read_address = 0;
	end
	// ----------------------------------------------------------------------
	wire [7:0] wa [12:1]; // word_A output from iserdes for bankA
	wire [7:0] wb [12:1]; // word_B output from iserdes for bankB
	wire [7:0] wc [12:1]; // word_C output from iserdes for bankC
	wire [7:0] wd [12:1]; // word_D output from iserdes for bankD
	iserdes_icositetrahedron_input #(
		.BIT_DEPTH(8), .PERIOD(PERIOD), .MULTIPLY(MULTIPLY), .DIVIDE(DIVIDE), .SCOPE(SCOPE)
	) bankAB (
		.clock_in(clock100), .reset(reset100), .locked(pll_oserdes_locked), .word_clock_out(word_clock), .bit_in_a(a), .bit_in_b(b),
		.word_out_1a(wa[1]), .word_out_2a(wa[2]), .word_out_3a(wa[3]),  .word_out_4a(wa[4]),   .word_out_5a(wa[5]),   .word_out_6a(wa[6]),
		.word_out_7a(wa[7]), .word_out_8a(wa[8]), .word_out_9a(wa[9]), .word_out_10a(wa[10]), .word_out_11a(wa[11]), .word_out_12a(wa[12]),
		.word_out_1b(wb[1]), .word_out_2b(wb[2]), .word_out_3b(wb[3]),  .word_out_4b(wb[4]),   .word_out_5b(wb[5]),   .word_out_6b(wb[6]),
		.word_out_7b(wb[7]), .word_out_8b(wb[8]), .word_out_9b(wb[9]), .word_out_10b(wb[10]), .word_out_11b(wb[11]), .word_out_12b(wb[12])
	);
	iserdes_icositetrahedron_input #(
		.BIT_DEPTH(8), .PERIOD(PERIOD), .MULTIPLY(MULTIPLY), .DIVIDE(DIVIDE), .SCOPE(SCOPE)
	) bankCD (
		.clock_in(clock100), .reset(reset100), .locked(), .word_clock_out(), .bit_in_a(c), .bit_in_b(d),
		.word_out_1a(wc[1]), .word_out_2a(wc[2]), .word_out_3a(wc[3]),  .word_out_4a(wc[4]),   .word_out_5a(wc[5]),   .word_out_6a(wc[6]),
		.word_out_7a(wc[7]), .word_out_8a(wc[8]), .word_out_9a(wc[9]), .word_out_10a(wc[10]), .word_out_11a(wc[11]), .word_out_12a(wc[12]),
		.word_out_1b(wd[1]), .word_out_2b(wd[2]), .word_out_3b(wd[3]),  .word_out_4b(wd[4]),   .word_out_5b(wd[5]),   .word_out_6b(wd[6]),
		.word_out_7b(wd[7]), .word_out_8b(wd[8]), .word_out_9b(wd[9]), .word_out_10b(wd[10]), .word_out_11b(wd[11]), .word_out_12b(wd[12])
	);
	// ----------------------------------------------------------------------
	wire raw_trigger = 0;
	localparam TRIGGER_TRAIN_PICKOFF = 2;
	localparam TRIGGER_TRAIN_DEPTH = 4;
	reg [TRIGGER_TRAIN_DEPTH-1:0] trigger_train = 0;
	wire trigger = trigger_train[TRIGGER_TRAIN_PICKOFF];
	always @(posedge word_clock) begin
		if (reset_word) begin
			trigger_train <= 0;
		end else begin
			trigger_train <= { trigger_train[TRIGGER_TRAIN_DEPTH-2:0], raw_trigger };
		end
	end
	reg trigger_active = 0;
	reg [31:0] trigger_active_counter = 0;
	reg [31:0] trigger_count = 0;
	always @(posedge word_clock) begin
		if (reset_word) begin
			trigger_active <= 0;
			trigger_active_counter <= 0;
			trigger_count <= 0;
		end else begin
			if (clear_trigger_count) begin
				trigger_active <= 0;
				trigger_active_counter <= 0;
				trigger_count <= 0;
			end else begin
				if (trigger_active) begin
					if (trigger_active_counter < trigger_duration_in_word_clocks) begin
						trigger_active_counter <= trigger_active_counter + 1'b1;
					end else begin
						trigger_active <= 0;
					end
				end else begin
					if (trigger) begin
						if (trigger_count < desired_trigger_quantity) begin
							trigger_active <= 1;
							trigger_active_counter <= 0;
							trigger_count <= trigger_count + 1'b1;
						end
					end
				end
			end
		end
	end
	// ----------------------------------------------------------------------
	wire raw_gate = 0;
	localparam GATE_TRAIN_PICKOFF = 2;
	localparam GATE_TRAIN_DEPTH = 4;
	reg [GATE_TRAIN_DEPTH-1:0] gate_train = 0;
	wire gate = gate_train[GATE_TRAIN_PICKOFF];
	reg [31:0] gate_counter = 0;
	reg [31:0] gate_counter_buffered = 0;
	always @(posedge word_clock) begin
		if (reset_word) begin
			gate_train <= 0;
		end else begin
			gate_train <= { gate_train[GATE_TRAIN_DEPTH-2:0], raw_gate };
		end
	end
	always @(posedge word_clock) begin
		if (reset_word) begin
			gate_counter <= 0;
			gate_counter_buffered <= 0;
		end else begin
			if (clear_gate_counter) begin
				gate_counter <= 0;
				gate_counter_buffered <= 0;
			end else begin
				gate_counter_buffered <= gate_counter;
				if (2'b01==gate_train[GATE_TRAIN_PICKOFF+1:GATE_TRAIN_PICKOFF]) begin
					gate_counter <= gate_counter + 1'b1;
				end
			end
		end
	end
	// ----------------------------------------------------------------------
	reg [2:0] anytrain = 0;
	always @(posedge word_clock) begin
		if (reset_word) begin
			anytrain <= 0;
		end else begin
			anytrain <= { anytrain[1:0], any };
		end
	end
	reg [31:0] hit_counter = 0;
	reg [31:0] hit_counter_buffered = 0;
	always @(posedge word_clock) begin
		if (reset_word) begin
			hit_counter <= 0;
			hit_counter_buffered <= 0;
		end else begin
			if (clear_hit_counter) begin
				hit_counter <= 0;
				hit_counter_buffered <= 0;
			end else begin
				hit_counter_buffered <= hit_counter;
				if (2'b01==anytrain[2:1]) begin
					hit_counter <= hit_counter + 1'b1;
				end
			end
		end
	end
	// ----------------------------------------------------------------------
	wire [SCALER_WIDTH-1:0] sca [12:1]; // channel_scaler_a
	wire [SCALER_WIDTH-1:0] scb [12:1]; // channel_scaler_b
	wire [SCALER_WIDTH-1:0] scc [12:1]; // channel_scaler_c
	wire [SCALER_WIDTH-1:0] scd [12:1]; // channel_scaler_d
	for (i=1; i<=12; i=i+1) begin : channel_scaler_mapping
		assign bank1[i] = sca[i]; // channel_scaler_a
		assign bank2[i] = scb[i]; // channel_scaler_b
		assign bank3[i] = scc[i]; // channel_scaler_c
		assign bank4[i] = scd[i]; // channel_scaler_d
	end
	wire anyA, anyB, anyC, anyD;
	assign any = anyA || anyB || anyC || anyD;
	LBLS_bank #( .SCALER_WIDTH(SCALER_WIDTH)) bankA (
		.clock(word_clock), .reset(reset_word),
		.inversion_mask(inversion_mask), .hit_mask(hit_mask), .gate(gate), .clear_channel_ones_counters(clear_channel_ones_counters), .trigger_active(trigger_active),
		.win1(wa[1]), .win2(wa[2]), .win3(wa[3]), .win4(wa[4]), .win5(wa[5]), .win6(wa[6]), .win7(wa[7]), .win8(wa[8]), .win9(wa[9]), .win10(wa[10]), .win11(wa[11]), .win12(wa[12]),
		.sc1(sca[1]), .sc2(sca[2]), .sc3(sca[3]), .sc4(sca[4]), .sc5(sca[5]), .sc6(sca[6]), .sc7(sca[7]), .sc8(sca[8]), .sc9(sca[9]), .sc10(sca[10]), .sc11(sca[11]), .sc12(sca[12]),
		.any(anyA)
	);
	LBLS_bank #( .SCALER_WIDTH(SCALER_WIDTH)) bankB (
		.clock(word_clock), .reset(reset_word),
		.inversion_mask(inversion_mask), .hit_mask(hit_mask), .gate(gate), .clear_channel_ones_counters(clear_channel_ones_counters), .trigger_active(trigger_active),
		.win1(wb[1]), .win2(wb[2]), .win3(wb[3]), .win4(wb[4]), .win5(wb[5]), .win6(wb[6]), .win7(wb[7]), .win8(wb[8]), .win9(wb[9]), .win10(wb[10]), .win11(wb[11]), .win12(wb[12]),
		.sc1(scb[1]), .sc2(scb[2]), .sc3(scb[3]), .sc4(scb[4]), .sc5(scb[5]), .sc6(scb[6]), .sc7(scb[7]), .sc8(scb[8]), .sc9(scb[9]), .sc10(scb[10]), .sc11(scb[11]), .sc12(scb[12]),
		.any(anyB)
	);
	LBLS_bank #( .SCALER_WIDTH(SCALER_WIDTH)) bankC (
		.clock(word_clock), .reset(reset_word),
		.inversion_mask(inversion_mask), .hit_mask(hit_mask), .gate(gate), .clear_channel_ones_counters(clear_channel_ones_counters), .trigger_active(trigger_active),
		.win1(wc[1]), .win2(wc[2]), .win3(wc[3]), .win4(wc[4]), .win5(wc[5]), .win6(wc[6]), .win7(wc[7]), .win8(wc[8]), .win9(wc[9]), .win10(wc[10]), .win11(wc[11]), .win12(wc[12]),
		.sc1(scc[1]), .sc2(scc[2]), .sc3(scc[3]), .sc4(scc[4]), .sc5(scc[5]), .sc6(scc[6]), .sc7(scc[7]), .sc8(scc[8]), .sc9(scc[9]), .sc10(scc[10]), .sc11(scc[11]), .sc12(scc[12]),
		.any(anyC)
	);
	LBLS_bank #( .SCALER_WIDTH(SCALER_WIDTH)) bankD (
		.clock(word_clock), .reset(reset_word),
		.inversion_mask(inversion_mask), .hit_mask(hit_mask), .gate(gate), .clear_channel_ones_counters(clear_channel_ones_counters), .trigger_active(trigger_active),
		.win1(wd[1]), .win2(wd[2]), .win3(wd[3]), .win4(wd[4]), .win5(wd[5]), .win6(wd[6]), .win7(wd[7]), .win8(wd[8]), .win9(wd[9]), .win10(wd[10]), .win11(wd[11]), .win12(wd[12]),
		.sc1(scd[1]), .sc2(scd[2]), .sc3(scd[3]), .sc4(scd[4]), .sc5(scd[5]), .sc6(scd[6]), .sc7(scd[7]), .sc8(scd[8]), .sc9(scd[9]), .sc10(scd[10]), .sc11(scd[11]), .sc12(scd[12]),
		.any(anyD)
	);
	// ----------------------------------------------------------------------
	if (1) begin
		assign status8[7] = anyD;
		assign status8[6] = anyC;
		assign status8[5] = anyB;
		assign status8[4] = anyA;
		// -------------------------------------
		assign status8[3] = ~pll_oserdes_locked;
		assign status8[2] = trigger_active;
		assign status8[1] = 0;
		assign status8[0] = any;
	end
	initial begin
		#100;
		$display("%d = %d + %d + %d - %d", ADDRESS_DEPTH_OSERDES, BANK_ADDRESS_DEPTH, LOG2_OF_BUS_WIDTH, LOG2_OF_TRANSACTIONS_PER_DATA_WORD, LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH);
		$display("BUS_WIDTH=%d, TRANSACTIONS_PER_DATA_WORD=%d, TRANSACTIONS_PER_ADDRESS_WORD=%d", BUS_WIDTH, TRANSACTIONS_PER_DATA_WORD, TRANSACTIONS_PER_ADDRESS_WORD);
		$display("%d banks", NUMBER_OF_BANKS);
	end
endmodule

module LBLS_tb;
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
	reg button = 1;
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
	LBLS #(.BUS_WIDTH(BUS_WIDTH), .ADDRESS_DEPTH(ADDRESS_DEPTH), .TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD), .TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD), .ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE), .TESTBENCH(1)) ampoliros (
		.clock100_p(clock100_p), .clock100_n(clock100_n),
		// .button(button),
		.diff_pair_left({ a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p, b_n, b_p, e_n, e_p }),
		.diff_pair_right({ m_p, m_n, l_p, l_n, j_p, j_n, g_p, g_n, k_p, k_n, h_p, h_n }),
		.single_ended_left({ z, y, x, w, v, u }),
		.single_ended_right({ n, p, q, r, s, t }),
		.bus(bus), .register_select(register_select), .read(read), .enable(enable), .ack_valid(ack_valid)
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

module myampoliros #(
	parameter NOTHING = 0
) (
	input clock100_p, clock100_n,
	output [3:1] outR, outF,
	inout [2:1] inoutM,
	input [3:1] inR, inF,
	output [3:1] tR, tF,
	// other IOs:
	output rpi_gpio22, // ack_valid
	input rpi_gpio23, // register_select
	input rpi_gpio4_gpclk0, // enable
	input rpi_gpio5, // read
	// 16 bit bus:
	inout rpi_gpio6_gpclk2, rpi_gpio7_spi_ce1, rpi_gpio8_spi_ce0, rpi_gpio9_spi_miso,
	inout rpi_gpio10_spi_mosi, rpi_gpio11_spi_sclk, rpi_gpio12, rpi_gpio13,
	inout rpi_gpio14, rpi_gpio15, rpi_gpio16, rpi_gpio17,
	inout rpi_gpio18, rpi_gpio19, rpi_gpio20, rpi_gpio21,
	// diff-pair IOs (toupee connectors):
	output
	a_p, b_p, c_p, d_p, e_p, f_p,
	a_n, b_n, c_n, d_n, e_n, f_n,
	// single-ended IOs (toupee connectors):
	output
	u, v, w, x, y, z,
	// 48 inputs for 4 PIN diode boxes:
	input [12:1] ap, an,
	input [12:1] bp, bn,
	input [12:1] cp, cn,
	input [12:1] dp, dn,
	// other IOs:
	input button,
	output ldac, ampen
);
	localparam BUS_WIDTH = 16;
	localparam BANK_ADDRESS_DEPTH = 13;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	assign { u, v, w, x, y, z } = 0;
	assign { a_p, a_n, b_p, b_n, c_p, c_n, d_p, d_n, e_p, e_n, f_p, f_n } = 0;
	wire [12:1] a, b, c, d;
	genvar i;
	for (i=1; i<=12; i=i+1) begin : inputs
		IBUFDS main_inputs_A (.I(ap[i]), .IB(an[i]), .O(a[i]));
		IBUFDS main_inputs_B (.I(bp[i]), .IB(bn[i]), .O(b[i]));
		IBUFDS main_inputs_C (.I(cp[i]), .IB(cn[i]), .O(c[i]));
		IBUFDS main_inputs_D (.I(dp[i]), .IB(dn[i]), .O(d[i]));
	end
	LBLS #(
		.TESTBENCH(0),
		.BUS_WIDTH(BUS_WIDTH), .BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) ampoliros (
		.clock100_p(clock100_p), .clock100_n(clock100_n),
		.button(button),
		.outF(outF), .outR(outR),
		.inoutM(inoutM),
		.inF(inF), .inR(inR),
		.tR(tR), .tF(tF),
		.bus({
			rpi_gpio21, rpi_gpio20, rpi_gpio19, rpi_gpio18,
			rpi_gpio17, rpi_gpio16, rpi_gpio15, rpi_gpio14,
			rpi_gpio13, rpi_gpio12, rpi_gpio11_spi_sclk, rpi_gpio10_spi_mosi,
			rpi_gpio9_spi_miso, rpi_gpio8_spi_ce0, rpi_gpio7_spi_ce1, rpi_gpio6_gpclk2
		}),
		.a(a), .b(b), .c(c), .d(d),
		.register_select(rpi_gpio23), .read(rpi_gpio5),
		.enable(rpi_gpio4_gpclk0), .ack_valid(rpi_gpio22),
		.ampen(ampen), .ldac(ldac)
	);
endmodule

