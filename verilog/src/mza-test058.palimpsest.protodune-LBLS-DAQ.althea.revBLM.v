// written 2022-10-14 by mza
// based on mza-test057.palimpsest.protodune-LBLS-DAQ.althea.revB.v
// based on mza-test066.palimpsest.protodune-LBLS-DAQ.ampoliros48.revA.v
// and mza-test035.SCROD_XRM_clock_and_revo_receiver_frame9_and_trigger_generator.v
// last updated 2024-05-08 by mza

`define althea_revBLM
`include "lib/duneLBLS.v"
`include "lib/generic.v"
`include "lib/RAM8.v"
`include "lib/fifo.v"
//`include "lib/RAM.sv" // ise does not and will not support systemverilog
`include "lib/plldcm.v"
`include "lib/serdes_pll.v"
`include "lib/half_duplex_rpi_bus.v"
`include "lib/sequencer.v"
`include "lib/reset.v"
//`include "lib/edge_to_pulse.v"
`include "lib/frequency_counter.v"

module LBLS12 #(
	parameter COUNTER_WIDTH = 32,
	parameter SCALER_WIDTH = 16,
	// PLL_ADV VCO range is 400 MHz to 1080 MHz
	parameter PERIOD = 10.0, // 100 MHz
	parameter MULTIPLY = 10, // 1000 MHz
	parameter DIVIDE = 1, // 1000 MHz
	//parameter EXTRA_DIVIDE = 1, // 1000 MHz bit clock; 125 MHz word clock (fails timing by 52 ps)
	parameter EXTRA_DIVIDE = 2, // 500 MHz bit clock; 62.5 MHz word clock
	parameter OSCILLATOR_FREQUENCY_HZ = 100_000_000,
	parameter WORD_CLOCK_FREQUENCY_HZ = $int(OSCILLATOR_FREQUENCY_HZ * MULTIPLY / DIVIDE / EXTRA_DIVIDE),
	parameter GUI_UPDATE_PERIOD = 0.2,
	parameter CLOCK_PERIODS_TO_ACCUMULATE = $int(WORD_CLOCK_FREQUENCY_HZ * GUI_UPDATE_PERIOD), // should be roughly same duration as gui update period (0.2s)
	parameter ROTATED = 0,
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
//	input button,
	inout [5:0] coax,
//	input [2:0] rot,
	inout [BUS_WIDTH-1:0] bus,
	input read, // 0=write; 1=read
	input register_select, // 0=address; 1=data
	input enable, // 1=active; 0=inactive
	output ack_valid,
	input [12:1] signal, // only on set of 12 channels (bankA) on this board
	output [12:1] indicator,
	output other,
//	output [7-LEFT_DAC_OUTER*4:4-LEFT_DAC_OUTER*4] led,
	output [3:0] coax_led
);
	genvar i;
	localparam SCOPE = "GLOBAL"; // "GLOBAL" (400 MHz), "BUFIO2" (525 MHz), "BUFPLL" (1080 MHz)
//	wire [7:0] pattern [12:1];
//	reg [7:0] status [12:1];
	localparam ERROR_COUNT_PICKOFF = 7;
	wire [3:0] status4;
	wire [7:0] status8;
	wire reset;
	wire pll_oserdes_locked;
	// ----------------------------------------------------------------------
	wire reset100;
	wire clock100;
	IBUFGDS mybuf0 (.I(clock100_p), .IB(clock100_n), .O(clock100));
	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset100_wait4pll (.reset1_input(reset), .pll_locked1_input(1'b1), .clock1_input(clock100), .clock2_input(clock100), .reset2_output(reset100));
	wire word_clock;
	// ----------------------------------------------------------------------
	wire reset_word;
	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset1_input(reset100), .pll_locked1_input(pll_oserdes_locked), .clock1_input(clock100), .clock2_input(word_clock), .reset2_output(reset_word));
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
	wire [31:0] bank1 [15:0];
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
	wire [31:0] bank2 [15:0];
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
	wire [31:0] bank3 [15:0];
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
	wire [31:0] bank4 [15:0];
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
	wire [31:0] bank5 [15:0];
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank5 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[5]),
		.data_in_b_0(bank5[0]),  .data_in_b_1(bank5[1]),  .data_in_b_2(bank5[2]),  .data_in_b_3(bank5[3]),
		.data_in_b_4(bank5[4]),  .data_in_b_5(bank5[5]),  .data_in_b_6(bank5[6]),  .data_in_b_7(bank5[7]),
		.data_in_b_8(bank5[8]),  .data_in_b_9(bank5[9]),  .data_in_b_a(bank5[10]), .data_in_b_b(bank5[11]),
		.data_in_b_c(bank5[12]), .data_in_b_d(bank5[13]), .data_in_b_e(bank5[14]), .data_in_b_f(bank5[15]),
		.write_strobe_b(1'b1));
	assign bank5[0] = 0;
	assign bank5[13] = 0;
	assign bank5[14] = 0;
	assign bank5[15] = 0;
//	for (i=0; i<=15; i=i+1) begin : dummy_bank5
//		assign bank5[i] = 0;
//	end
	wire [31:0] bank6 [15:0];
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank6 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[6]),
		.data_in_b_0(bank6[0]),  .data_in_b_1(bank6[1]),  .data_in_b_2(bank6[2]),  .data_in_b_3(bank6[3]),
		.data_in_b_4(bank6[4]),  .data_in_b_5(bank6[5]),  .data_in_b_6(bank6[6]),  .data_in_b_7(bank6[7]),
		.data_in_b_8(bank6[8]),  .data_in_b_9(bank6[9]),  .data_in_b_a(bank6[10]), .data_in_b_b(bank6[11]),
		.data_in_b_c(bank6[12]), .data_in_b_d(bank6[13]), .data_in_b_e(bank6[14]), .data_in_b_f(bank6[15]),
		.write_strobe_b(1'b1));
	assign bank6[0] = 0;
	assign bank6[13] = 0;
	assign bank6[14] = 0;
	assign bank6[15] = 0;
//	for (i=0; i<=15; i=i+1) begin : dummy_bank6
//		assign bank6[i] = 0;
//	end
	wire [31:0] bank7 [15:0];
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank7 (.clock(word_clock),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[7]),
		.data_in_b_0(bank7[0]),  .data_in_b_1(bank7[1]),  .data_in_b_2(bank7[2]),  .data_in_b_3(bank7[3]),
		.data_in_b_4(bank7[4]),  .data_in_b_5(bank7[5]),  .data_in_b_6(bank7[6]),  .data_in_b_7(bank7[7]),
		.data_in_b_8(bank7[8]),  .data_in_b_9(bank7[9]),  .data_in_b_a(bank7[10]), .data_in_b_b(bank7[11]),
		.data_in_b_c(bank7[12]), .data_in_b_d(bank7[13]), .data_in_b_e(bank7[14]), .data_in_b_f(bank7[15]),
		.write_strobe_b(1'b1));
	assign bank7[0] = 0;
	assign bank7[13] = 0;
	assign bank7[14] = 0;
	assign bank7[15] = 0;
//	for (i=0; i<=15; i=i+1) begin : dummy_bank7
//		assign bank7[i] = 0;
//	end
	for (i=1; i<=12; i=i+1) begin : dummy_567
		assign bank5[i] = 32'h5;
		assign bank6[i] = 32'h6;
		assign bank7[i] = 32'h7;
	end
		// ----------------------------------------------------------------------
	wire raw_trigger = 0;
	localparam TRIGGER_TRAIN_PICKOFF = 4;
	reg [TRIGGER_TRAIN_PICKOFF:0] trigger_train = 0;
	wire trigger = trigger_train[TRIGGER_TRAIN_PICKOFF];
	always @(posedge word_clock) begin
		if (reset_word) begin
			trigger_train <= 0;
		end else begin
			trigger_train <= { trigger_train[TRIGGER_TRAIN_PICKOFF-1:0], raw_trigger };
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
	wire raw_gate = 1;
	localparam GATE_TRAIN_PICKOFF = 4;
	reg [GATE_TRAIN_PICKOFF:0] gate_train = 0;
	wire gate = gate_train[GATE_TRAIN_PICKOFF];
	reg [31:0] gate_counter = 0;
//	reg [31:0] gate_counter_buffered = 0;
	always @(posedge word_clock) begin
		if (reset_word) begin
			gate_train <= 0;
		end else begin
			gate_train <= { gate_train[GATE_TRAIN_PICKOFF-1:0], raw_gate };
		end
	end
	always @(posedge word_clock) begin
		if (reset_word) begin
			gate_counter <= 0;
//			gate_counter_buffered <= 0;
		end else begin
			if (clear_gate_counter) begin
				gate_counter <= 0;
//				gate_counter_buffered <= 0;
			end else begin
//				gate_counter_buffered <= gate_counter;
				if (2'b01==gate_train[GATE_TRAIN_PICKOFF:GATE_TRAIN_PICKOFF-1]) begin
					gate_counter <= gate_counter + 1'b1;
				end
			end
		end
	end
	// ----------------------------------------------------------------------
	wire [7:0] wa [12:1]; // word_A output from iserdes for bankA
	wire pll_oserdes_locked_copy_on_word_clock;
	ssynchronizer #(.WIDTH(1)) mysin (.clock1(clock100), .clock2(word_clock), .reset1(reset100), .reset2(reset_word), .in1(pll_oserdes_locked), .out2(pll_oserdes_locked_copy_on_word_clock));
	iserdes_dodecahedron_input #(
		.BIT_DEPTH(8), .PERIOD(PERIOD), .MULTIPLY(MULTIPLY), .DIVIDE(DIVIDE), .EXTRA_DIVIDE(EXTRA_DIVIDE), .SCOPE(SCOPE), .SPLIT_BANKS(1)
	) inputs_bankA (
		.clock_in(clock100), .reset(reset100), .locked(pll_oserdes_locked), .word_clock_out(word_clock), .bit_in(signal),
		.word_out_1(wa[1]), .word_out_2(wa[2]), .word_out_3(wa[3]),  .word_out_4(wa[4]),   .word_out_5(wa[5]),   .word_out_6(wa[6]),
		.word_out_7(wa[7]), .word_out_8(wa[8]), .word_out_9(wa[9]), .word_out_10(wa[10]), .word_out_11(wa[11]), .word_out_12(wa[12])
	);
	// ----------------------------------------------------------------------
	wire [SCALER_WIDTH-1:0] sca [12:1]; // channel_scaler_a
	wire [COUNTER_WIDTH-1:0] ca [12:1]; // channel_counter_a
	wire [7:0] tota [12:1]; // time-over-threshold for bankA
	wire any;
	LBLS_bank #(.COUNTER_WIDTH(COUNTER_WIDTH), .SCALER_WIDTH(SCALER_WIDTH), .CLOCK_PERIODS_TO_ACCUMULATE(CLOCK_PERIODS_TO_ACCUMULATE)) logic_bankA (
		.clock(word_clock), .reset(reset_word),
		.inversion_mask(inversion_mask), .hit_mask(hit_mask), .gate(gate), .clear_channel_counters(clear_channel_counters), .trigger_active(trigger_active),
		.win1(wa[1]), .win2(wa[2]), .win3(wa[3]), .win4(wa[4]), .win5(wa[5]), .win6(wa[6]), .win7(wa[7]), .win8(wa[8]), .win9(wa[9]), .win10(wa[10]), .win11(wa[11]), .win12(wa[12]),
		.sc1(sca[1]), .sc2(sca[2]), .sc3(sca[3]), .sc4(sca[4]), .sc5(sca[5]), .sc6(sca[6]), .sc7(sca[7]), .sc8(sca[8]), .sc9(sca[9]), .sc10(sca[10]), .sc11(sca[11]), .sc12(sca[12]),
		.c1(ca[1]), .c2(ca[2]), .c3(ca[3]), .c4(ca[4]), .c5(ca[5]), .c6(ca[6]), .c7(ca[7]), .c8(ca[8]), .c9(ca[9]), .c10(ca[10]), .c11(ca[11]), .c12(ca[12]),
		.tot1(tota[1]), .tot2(tota[2]), .tot3(tota[3]), .tot4(tota[4]), .tot5(tota[5]), .tot6(tota[6]), .tot7(tota[7]), .tot8(tota[8]), .tot9(tota[9]), .tot10(tota[10]), .tot11(tota[11]), .tot12(tota[12]),
		.any(any)
	);
	// ----------------------------------------------------------------------
	for (i=0; i<=5; i=i+1) begin : dummy_coax
		assign coax[i] = 0;
	end
	for (i=1; i<=12; i=i+1) begin : dummy_indicator
		assign indicator[i] = 0;
	end
	assign other = 0;
	assign reset = 0;
/*
	for (i=0; i<4; i=i+1) begin : coax_mux_mapping
		always @(posedge word_clock) begin
			if (reset_word) begin
				coax_oserdes[i] <= 0;
			end else begin
				if (coax_mux[i]==4'd0) begin
					coax_oserdes[i] <= {8{any}};
				end else if (coax_mux[i]==4'd13) begin
					coax_oserdes[i] <= iserdes_in_buffered_and_maybe_inverted_b[12];
				end else if (coax_mux[i]==4'd14) begin
					coax_oserdes[i] <= channel_counter[12][7:0];
				end else if (coax_mux[i]==4'd15) begin
					coax_oserdes[i] <= channel_scaler[12][7:0];
				end else begin
					coax_oserdes[i] <= previous_time_over_threshold[coax_mux[i]];
				end
//				coax_oserdes[2] <= {8{iserdes_word_hit[12]}};
			end
		end
	end
*/
	// ----------------------------------------------------------------------
	for (i=1; i<=12; i=i+1) begin : mapping
		assign bank1[i] = { 16'b0, sca[i] }; // scalers
		assign bank2[i] = 32'b0;
		assign bank3[i] = { 24'b0, tota[i] }; // time-over-threshold
		assign bank4[i] = ca[i]; // counters
	end
	// ----------------------------------------------------------------------
	if (1) begin
		assign status4[3] = ~pll_oserdes_locked_copy_on_word_clock;
		assign status4[2] = trigger_active;
		assign status4[1] = 0;
		assign status4[0] = any;
		// -------------------------------------
		assign status8[7] = 0;
		assign status8[6] = 0;
		assign status8[5] = 0;
		assign status8[4] = 0;
		// -------------------------------------
		assign status8[3] = ~pll_oserdes_locked_copy_on_word_clock;
		assign status8[2] = trigger_active;
		assign status8[1] = 0;
		assign status8[0] = any;
	end
	assign coax_led = status4;
	initial begin
		#100;
		$display("%d = %d + %d + %d - %d", ADDRESS_DEPTH_OSERDES, BANK_ADDRESS_DEPTH, LOG2_OF_BUS_WIDTH, LOG2_OF_TRANSACTIONS_PER_DATA_WORD, LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH);
		$display("BUS_WIDTH=%d, TRANSACTIONS_PER_DATA_WORD=%d, TRANSACTIONS_PER_ADDRESS_WORD=%d", BUS_WIDTH, TRANSACTIONS_PER_DATA_WORD, TRANSACTIONS_PER_ADDRESS_WORD);
		$display("%d banks", NUMBER_OF_BANKS);
	end
endmodule

module TESTBENCH_LBLS12_tb;
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
	LBLS12 #(.BUS_WIDTH(BUS_WIDTH), .ADDRESS_DEPTH(ADDRESS_DEPTH), .TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD), .TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD), .ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE), .TESTBENCH(1)) althea12 (
		.clock100_p(clock100_p), .clock100_n(clock100_n),
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

module DUNELBLS12 #(
	parameter ROTATED = 0,
	parameter NOTHING = 0
) (
	input clock100_p, clock100_n,
	inout [5:0] coax,
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
	input
	a_p, b_p, c_p, d_p, e_p, f_p,
	g_p, h_p, j_p, k_p, l_p, m_p,
	a_n, b_n, c_n, d_n, e_n, f_n,
	g_n, h_n, j_n, k_n, l_n, m_n,
	// single-ended IOs (toupee connectors):
	output
	n, p, q, r, s, t,
	u, v, w, x, y, z,
	// other IOs:
	//input [2:0] rot
//	input button, // reset
	output other, // goes to PMOD connector
//	output [7-LEFT_DAC_OUTER*4:4-LEFT_DAC_OUTER*4] led,
	output [3:0] coax_led
);
	localparam BUS_WIDTH = 16;
	localparam BANK_ADDRESS_DEPTH = 13;
	localparam TRANSACTIONS_PER_DATA_WORD = 2;
	localparam TRANSACTIONS_PER_ADDRESS_WORD = 1;
	localparam ADDRESS_AUTOINCREMENT_MODE = 1;
	wire [3:0] internal_coax_led;
	//wire [7:0] internal_led;
	//assign led = internal_led;
	assign coax_led = internal_coax_led;
	wire [12:1] signal;
	wire [12:1] indicator;
	//assign { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p } = signal;
	//assign { t, s, r, q, p, n, u, v, w, x, y, z } = indicator;
	//assign { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p } = signal;
//	assign signal = { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p };
	if (ROTATED) begin
		IBUFDS ibufds12 (.I(f_p), .IB(f_n), .O(signal[12])); // p141, p142 - near "other"
		IBUFDS ibufds11 (.I(e_p), .IB(e_n), .O(signal[11])); // p133, p134
		IBUFDS ibufds10 (.I(d_p), .IB(d_n), .O(signal[10])); // p139, p140
		IBUFDS ibufds09 (.I(c_p), .IB(c_n), .O(signal[9]));  // p131, p132
		IBUFDS ibufds08 (.I(b_p), .IB(b_n), .O(signal[8]));  // p123, p124
		IBUFDS ibufds07 (.I(a_p), .IB(a_n), .O(signal[7]));  // p116, p117 - near gpio15, gpio18
		IBUFDS ibufds06 (.I(g_p), .IB(g_n), .O(signal[6]));  // p40, p41
		IBUFDS ibufds05 (.I(h_p), .IB(h_n), .O(signal[5]));  // p43, p44
		IBUFDS ibufds04 (.I(j_p), .IB(j_n), .O(signal[4]));  // p45, p46
		IBUFDS ibufds03 (.I(l_p), .IB(l_n), .O(signal[3]));  // p47, p48
		IBUFDS ibufds02 (.I(k_p), .IB(k_n), .O(signal[2]));  // p55, p56
		IBUFDS ibufds01 (.I(m_p), .IB(m_n), .O(signal[1]));  // p57, p58 - near gpio16
		assign { u, v, w, x, y, z, t, s, r, q, p, n } = indicator;
	end else begin
		IBUFDS ibufds01 (.I(f_p), .IB(f_n), .O(signal[1]));  // p141, p142
		IBUFDS ibufds02 (.I(e_p), .IB(e_n), .O(signal[2]));  // p133, p134
		IBUFDS ibufds03 (.I(d_p), .IB(d_n), .O(signal[3]));  // p139, p140
		IBUFDS ibufds04 (.I(c_p), .IB(c_n), .O(signal[4]));  // p131, p132
		IBUFDS ibufds05 (.I(b_p), .IB(b_n), .O(signal[5]));  // p123, p124
		IBUFDS ibufds06 (.I(a_p), .IB(a_n), .O(signal[6]));  // p116, p117
		IBUFDS ibufds07 (.I(g_p), .IB(g_n), .O(signal[7]));  // p40, p41
		IBUFDS ibufds08 (.I(h_p), .IB(h_n), .O(signal[8]));  // p43, p44
		IBUFDS ibufds09 (.I(j_p), .IB(j_n), .O(signal[9]));  // p45, p46
		IBUFDS ibufds10 (.I(l_p), .IB(l_n), .O(signal[10])); // p47, p48
		IBUFDS ibufds11 (.I(k_p), .IB(k_n), .O(signal[11])); // p55, p56
		IBUFDS ibufds12 (.I(m_p), .IB(m_n), .O(signal[12])); // p57, p58
		assign { t, s, r, q, p, n, u, v, w, x, y, z } = indicator;
	end
	LBLS12 #(
		.TESTBENCH(0), .ROTATED(ROTATED),
		.BUS_WIDTH(BUS_WIDTH), .BANK_ADDRESS_DEPTH(BANK_ADDRESS_DEPTH),
		.TRANSACTIONS_PER_DATA_WORD(TRANSACTIONS_PER_DATA_WORD),
		.TRANSACTIONS_PER_ADDRESS_WORD(TRANSACTIONS_PER_ADDRESS_WORD),
		.ADDRESS_AUTOINCREMENT_MODE(ADDRESS_AUTOINCREMENT_MODE)
	) althea12 (
		.clock100_p(clock100_p), .clock100_n(clock100_n),
//		.button(button),
		.coax(coax),
		.bus({
			rpi_gpio21, rpi_gpio20, rpi_gpio19, rpi_gpio18,
			rpi_gpio17, rpi_gpio16, rpi_gpio15, rpi_gpio14,
			rpi_gpio13, rpi_gpio12, rpi_gpio11_spi_sclk, rpi_gpio10_spi_mosi,
			rpi_gpio9_spi_miso, rpi_gpio8_spi_ce0, rpi_gpio7_spi_ce1, rpi_gpio6_gpclk2
		}),
		.signal(signal),
		.indicator(indicator),
		.register_select(rpi_gpio23), .read(rpi_gpio5),
		.enable(rpi_gpio4_gpclk0), .ack_valid(rpi_gpio22),
//		.rot(rot),
		.other(other),
//		.led(internal_led),
		.coax_led(internal_coax_led)
	);
endmodule

