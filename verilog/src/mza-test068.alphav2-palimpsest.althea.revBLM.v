`timescale 1ns / 1ps

// written 2022-11-16 by mza
// based on mza-test067.alphav2.althea.revBLM.v and mza-test066.palimpsest.protodune-LBLS-DAQ.ampoliros48.revA.v
// last updated 2024-11-21 by mza

`include "lib/reset.v"
`include "lib/debounce.v"
`include "lib/generic.v"
`include "lib/alpha.v"
`include "lib/plldcm.v"
`include "lib/i2c.v"
`include "lib/fifo.v"
`include "lib/half_duplex_rpi_bus.v"

module ALPHAtestPALIMPSEST #(
	parameter BUS_WIDTH = 16,
	parameter LOG2_OF_BUS_WIDTH = $clog2(BUS_WIDTH),
	parameter TRANSACTIONS_PER_DATA_WORD = 2,
	parameter LOG2_OF_TRANSACTIONS_PER_DATA_WORD = $clog2(TRANSACTIONS_PER_DATA_WORD),
	parameter TRANSACTIONS_PER_ADDRESS_WORD = 1,
	parameter BANK_ADDRESS_DEPTH = 13,
	parameter LOG2_OF_NUMBER_OF_BANKS = BUS_WIDTH*TRANSACTIONS_PER_ADDRESS_WORD - BANK_ADDRESS_DEPTH, // 3
	parameter NUMBER_OF_BANKS = 1<<LOG2_OF_NUMBER_OF_BANKS, // 2^3 = 8
	parameter ADDRESS_AUTOINCREMENT_MODE = 1,
	parameter ERROR_COUNT_PICKOFF = 7,
	parameter ALPHA_V = 2
) (
	// althea revBLM:
	input clock100_p, clock100_n,
//	input button,
	output [5:0] coax,
	output [3:0] coax_led,
	output [7:0] led,
	input [3:0] rot,
	inout [23:4] rpi_gpio,
	// alpha_eval revC / revD:
	output sysclk_p, sysclk_n,
	output ls_i2c,
	output scl,
	inout sda,
	output sin,
	output actual_sclk,
	output actual_pclk,
//	input shout,
	output sstclk_p, sstclk_n,
	output tok_a_in,
	input tok_a_out,
	output actual_auxtrig,
	output sync,
	output trigin_p, trigin_n,
	input data_a_out_p, data_a_out_n
);
	wire clock100;
	IBUFGDS clock_in_diff (.I(clock100_p), .IB(clock100_n), .O(clock100)); // WARNING:Xst:2957 - There are clock and non-clock loads on clock signal clock100_BUFG. This is not a recommended design practice, that may cause excessive delay, skew or unroutable situations.
	// ----------------------------------------------------------------------
	wire sysclk_raw, sysclk180_raw, sstclk_raw, sstclk180_raw;
	wire sysclk, sysclk180, sstclk, sstclk180, first_pll_locked, reset;
	localparam RESET_COUNTER_PICKOFF = 9;
	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(RESET_COUNTER_PICKOFF)) reset100_wait4pll (.reset1_input(1'b0), .pll_locked1_input(first_pll_locked), .clock1_input(clock100), .clock2_input(sysclk), .reset2_output(reset));
	simplepll_BASE #(.PERIOD(10.0), .OVERALL_DIVIDE(1), .MULTIPLY(10), .COMPENSATION("INTERNAL"),
		// 9->111 MHz; 8->125 MHz; 7->143 MHz; 6->167 MHz; 5->200 MHz; 4->250 MHz
		.DIVIDE0(7), .DIVIDE1(7),
		.DIVIDE2(4), .DIVIDE3(4),
		.DIVIDE4(4), .DIVIDE5(4),
		.PHASE0(0.0), .PHASE1(180.0),
		.PHASE2(0.0), .PHASE3(180.0),
		.PHASE4(0.0), .PHASE5(0.0)
	) pll_sys_sst (.clockin(clock100), .reset(1'b0), .locked(first_pll_locked),
		.clock0out(sysclk_raw), .clock1out(sysclk180_raw),
		.clock2out(sstclk_raw), .clock3out(sstclk180_raw),
		.clock4out(), .clock5out()
	);
	BUFG sysraw (.I(sysclk_raw), .O(sysclk));
	BUFG sys180 (.I(sysclk180_raw), .O(sysclk180));
	BUFG sstraw (.I(sstclk_raw), .O(sstclk));
	BUFG sst180 (.I(sstclk180_raw), .O(sstclk180));
	clock_ODDR_out_diff sysclk_ODDR (.clock_in_p(sysclk), .clock_in_n(sysclk180), .clock_enable(1'b1), .clock_out_p(sysclk_p), .clock_out_n(sysclk_n));
	clock_ODDR_out_diff sstclk_ODDR (.clock_in_p(sstclk), .clock_in_n(sstclk180), .clock_enable(1'b1), .clock_out_p(sstclk_p), .clock_out_n(sstclk_n));
//	ODDR2 #(.DDR_ALIGNMENT("NONE")) oddr2_clock (.C0(sysclk), .C1(sysclk180), .CE(1'b1), .D0(1'b1), .D1(1'b0), .R(reset), .S(1'b0), .Q(coax[3]));
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
		.register_select(rpi_gpio[23]), // 0=address;  1=data
		      .ack_valid(rpi_gpio[22]),
		            .bus(rpi_gpio[21:6]),
		           .read(rpi_gpio[5]),  // 0=write;    1=read
		         .enable(rpi_gpio[4]),  // 0=inactive; 1=active
		.write_strobe(write_strobe), .read_strobe(read_strobe), .bank(bank), .clock(sysclk), .reset(reset),
		.write_data_word(write_data_word), .read_data_word(read_data_word[bank]), .address_word_reg(address_word_full),
		.read_errors(hdrb_read_errors), .write_errors(hdrb_write_errors), .address_errors(hdrb_address_errors)
	);
/*
	wire [31:0] bank_r_strobe_counter [7:0];
	wire [31:0] bank_w_strobe_counter [7:0];
	counter_level bank0_r_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(read_strobe[0]),  .counter(bank_r_strobe_counter[0]));
	counter_level bank1_r_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(read_strobe[1]),  .counter(bank_r_strobe_counter[1]));
	counter_level bank2_r_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(read_strobe[2]),  .counter(bank_r_strobe_counter[2]));
	counter_level bank3_r_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(read_strobe[3]),  .counter(bank_r_strobe_counter[3]));
	counter_level bank4_r_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(read_strobe[4]),  .counter(bank_r_strobe_counter[4]));
	counter_level bank5_r_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(read_strobe[5]),  .counter(bank_r_strobe_counter[5]));
	counter_level bank6_r_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(read_strobe[6]),  .counter(bank_r_strobe_counter[6]));
	counter_level bank7_r_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(read_strobe[7]),  .counter(bank_r_strobe_counter[7]));
	counter_level bank0_w_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(write_strobe[0]), .counter(bank_w_strobe_counter[0]));
	counter_level bank1_w_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(write_strobe[1]), .counter(bank_w_strobe_counter[1]));
	counter_level bank2_w_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(write_strobe[2]), .counter(bank_w_strobe_counter[2]));
	counter_level bank3_w_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(write_strobe[3]), .counter(bank_w_strobe_counter[3]));
	counter_level bank4_w_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(write_strobe[4]), .counter(bank_w_strobe_counter[4]));
	counter_level bank5_w_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(write_strobe[5]), .counter(bank_w_strobe_counter[5]));
	counter_level bank6_w_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(write_strobe[6]), .counter(bank_w_strobe_counter[6]));
	counter_level bank7_w_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(write_strobe[7]), .counter(bank_w_strobe_counter[7]));
*/
	// ----------------------------------------------------------------------
	genvar i;
	// ----------------------------------------------------------------------
	wire [31:0] bank0 [15:0]; // general settings
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank0 (.clock(sysclk), .reset(reset),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[0]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[0]),
		.data_out_b_0(bank0[0]),  .data_out_b_1(bank0[1]),  .data_out_b_2(bank0[2]),  .data_out_b_3(bank0[3]),
		.data_out_b_4(bank0[4]),  .data_out_b_5(bank0[5]),  .data_out_b_6(bank0[6]),  .data_out_b_7(bank0[7]),
		.data_out_b_8(bank0[8]),  .data_out_b_9(bank0[9]),  .data_out_b_a(bank0[10]), .data_out_b_b(bank0[11]),
		.data_out_b_c(bank0[12]), .data_out_b_d(bank0[13]), .data_out_b_e(bank0[14]), .data_out_b_f(bank0[15]));
	assign ls_i2c = bank0[0][0]; // 0=i2c; 1=ls
	// ----------------------------------------------------------------------
	wire [31:0] bank1 [15:0]; // status
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank1 (.clock(sysclk),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[1]),
		.data_in_b_0(bank1[0]),  .data_in_b_1(bank1[1]),  .data_in_b_2(bank1[2]),  .data_in_b_3(bank1[3]),
		.data_in_b_4(bank1[4]),  .data_in_b_5(bank1[5]),  .data_in_b_6(bank1[6]),  .data_in_b_7(bank1[7]),
		.data_in_b_8(bank1[8]),  .data_in_b_9(bank1[9]),  .data_in_b_a(bank1[10]), .data_in_b_b(bank1[11]),
		.data_in_b_c(bank1[12]), .data_in_b_d(bank1[13]), .data_in_b_e(bank1[14]), .data_in_b_f(bank1[15]),
		.write_strobe_b(1'b1));
	wire [7:0] status8;
	reg [7:0] number_of_triggers_since_reset = 0;
//	wire fifo_empty;
//	wire [:] fifo_pending;
	wire [31:0] asic_output_strobe_counter;
	wire [31:0] fifo_output_strobe_counter;
	wire [31:0] alfa_counter;
	wire [31:0] omga_counter;
	assign bank1[0] = { hdrb_read_errors[ERROR_COUNT_PICKOFF:0], hdrb_write_errors[ERROR_COUNT_PICKOFF:0], hdrb_address_errors[ERROR_COUNT_PICKOFF:0], status8 };
	assign bank1[1][7:0] = number_of_triggers_since_reset; assign bank1[1][31:8] = 0;
	assign bank1[2] = 0; // was fifo_empty
	assign bank1[3] = 0;
	assign bank1[4] = 0; // was fifo_error_count
	assign bank1[5] = asic_output_strobe_counter;
	assign bank1[6] = fifo_output_strobe_counter;
	assign bank1[7] = alfa_counter;
	assign bank1[8] = omga_counter;
	for (i=9; i<16; i=i+1) begin : bank1_unused
		assign bank1[i] = 0;
	end
	// ----------------------------------------------------------------------
	wire [15:0] bank2; // things that just need a pulse for 1 clock cycle
	// WARNING:Xst:2677 - Node <pulse_out_4> of sequential type is unconnected in block <pulsed_things_bank2>.
	assign read_data_word[2] = 0;
	memory_bank_interface_with_pulse_outputs #(.ADDR_WIDTH(4)) pulsed_things_bank2 (.clock(sysclk),
		.address(address_word_full[3:0]), .strobe(write_strobe[2]), .pulse_out(bank2));
	wire should_initiate_dreset_sequence        = bank2[0];
	wire should_initiate_legacy_serial_sequence = bank2[1];
	wire should_initiate_i2c_transfer           = bank2[2];
	wire should_trigger                         = bank2[3];
	// ----------------------------------------------------------------------
	wire [31:0] bank3 [15:0]; // i2c registers
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank3 (.clock(sysclk), .reset(reset),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[3]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[3]),
		.data_out_b_0(bank3[0]),  .data_out_b_1(bank3[1]),  .data_out_b_2(bank3[2]),  .data_out_b_3(bank3[3]),
		.data_out_b_4(bank3[4]),  .data_out_b_5(bank3[5]),  .data_out_b_6(bank3[6]),  .data_out_b_7(bank3[7]),
		.data_out_b_8(bank3[8]),  .data_out_b_9(bank3[9]),  .data_out_b_a(bank3[10]), .data_out_b_b(bank3[11]),
		.data_out_b_c(bank3[12]), .data_out_b_d(bank3[13]), .data_out_b_e(bank3[14]), .data_out_b_f(bank3[15]));
	wire [4:0] I2CupAddr             = bank3[1][7:3];
	wire LVDSB_pwr                   = bank3[1][2];
	wire LVDSA_pwr                   = bank3[1][1];
	wire SRCsel                      = bank3[1][0]; // set this to zero or the data will come from data_b (you probably don't want that)
	wire TMReg_Reset                 = bank3[2][0];
	wire [7:0] samples_after_trigger = bank3[3][7:0];
	wire [7:0] lookback_windows      = bank3[4][7:0];
	wire [7:0] number_of_samples     = bank3[5][7:0];
	wire [7:0] PCLK_period                   = bank3[11][7:0];
	wire [7:0] least_significant_nybbles     = bank3[12][7:0];
	wire [7:0] most_significant_nybble       = bank3[13][7:0];
	wire [7:0] PCLK_4DACs                    = bank3[14][7:0];
	wire [15:0] i2c_address_register_enables = bank3[15][15:0];
	// ----------------------------------------------------------------------
	wire [31:0] bank4 [15:0]; // legacy serial registers
	RAM_inferred_with_register_outputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwro_bank4 (.clock(sysclk), .reset(reset),
		.waddress_a(address_word_full[3:0]), .data_in_a(write_data_word), .write_strobe_a(write_strobe[4]),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[4]),
		.data_out_b_0(bank4[0]),  .data_out_b_1(bank4[1]),  .data_out_b_2(bank4[2]),  .data_out_b_3(bank4[3]),
		.data_out_b_4(bank4[4]),  .data_out_b_5(bank4[5]),  .data_out_b_6(bank4[6]),  .data_out_b_7(bank4[7]),
		.data_out_b_8(bank4[8]),  .data_out_b_9(bank4[9]),  .data_out_b_a(bank4[10]), .data_out_b_b(bank4[11]),
		.data_out_b_c(bank4[12]), .data_out_b_d(bank4[13]), .data_out_b_e(bank4[14]), .data_out_b_f(bank4[15]));
	wire [11:0] CMPbias = bank4[0][11:0]; // 1000
	wire [11:0] ISEL    = bank4[1][11:0]; // 0xa80
	wire [11:0] SBbias  = bank4[2][11:0]; // 1300
	wire [11:0] DBbias  = bank4[3][11:0]; // 1300
	// ----------------------------------------------------------------------
	// bank5 asic fifo data
	wire [15:0] asic_data_from_fifo;
	assign read_data_word[5] = { 16'd0, asic_data_from_fifo };
	wire fifo_read_strobe = read_strobe[5];
	// ----------------------------------------------------------------------
	wire [31:0] bank6 [15:0]; // status
	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri_bank6 (.clock(sysclk),
		.raddress_a(address_word_full[3:0]), .data_out_a(read_data_word[6]),
		.data_in_b_0(bank6[0]),  .data_in_b_1(bank6[1]),  .data_in_b_2(bank6[2]),  .data_in_b_3(bank6[3]),
		.data_in_b_4(bank6[4]),  .data_in_b_5(bank6[5]),  .data_in_b_6(bank6[6]),  .data_in_b_7(bank6[7]),
		.data_in_b_8(bank6[8]),  .data_in_b_9(bank6[9]),  .data_in_b_a(bank6[10]), .data_in_b_b(bank6[11]),
		.data_in_b_c(bank6[12]), .data_in_b_d(bank6[13]), .data_in_b_e(bank6[14]), .data_in_b_f(bank6[15]),
		.write_strobe_b(1'b1));
/*
	assign bank6[0] = bank_r_strobe_counter[0];
	assign bank6[1] = bank_r_strobe_counter[1];
	assign bank6[2] = bank_r_strobe_counter[2];
	assign bank6[3] = bank_r_strobe_counter[3];
	assign bank6[4] = bank_r_strobe_counter[4];
	assign bank6[5] = bank_r_strobe_counter[5];
	assign bank6[6] = bank_r_strobe_counter[6];
	assign bank6[7] = bank_r_strobe_counter[7];
	assign bank6[8]  = bank_w_strobe_counter[0];
	assign bank6[9]  = bank_w_strobe_counter[1];
	assign bank6[10] = bank_w_strobe_counter[2];
	assign bank6[11] = bank_w_strobe_counter[3];
	assign bank6[12] = bank_w_strobe_counter[4];
	assign bank6[13] = bank_w_strobe_counter[5];
	assign bank6[14] = bank_w_strobe_counter[6];
	assign bank6[15] = bank_w_strobe_counter[7];
*/
	for (i=0; i<16; i=i+1) begin : bank6_unused
		assign bank6[i] = 0;
	end
	// ----------------------------------------------------------------------
	assign read_data_word[7] = 0;
	// bank7 pollable memory
	if (0) begin
		RAM_s6_8k_32bit_8bit #(.ENDIANNESS("BIG")) mem_bank7 (.reset(reset),
			.clock_a(sysclk), .address_a(address_word_narrow), .data_in_a(write_data_word), .write_enable_a(write_strobe[7]), .data_out_a(read_data_word[7]),
			.clock_b(sysclk), .address_b(15'd0), .data_out_b());
	end
	// ----------------------------------------------------------------------
	wire trigin;
	OBUFDS obuf_trigin (.I(trigin), .O(trigin_p), .OB(trigin_n));
	wire auxtrig, pclk, sclk;
	wire dreset; // auxtrig, pclk, sclk;
	// defaults ---------------------------------
	assign auxtrig = 0;
	assign actual_pclk = pclk | dreset;
	assign actual_sclk = sclk | dreset;
	assign actual_auxtrig = auxtrig | dreset;
	// ----------------------------------------------------------------------
	wire should_allow_i2c_transfer = 1;
	wire should_allow_dreset_sequence = 1;
	wire should_allow_legacy_serial_sequence = 1;
	wire should_allow_trigger = 1;
	reg initiate_i2c_transfer = 0;
	reg initiate_dreset_sequence = 0;
	reg initiate_legacy_serial_sequence = 0;
	reg initiate_trigger = 0;
	reg i2c_transfer_has_occurred = 0;
	reg dreset_sequence_has_occurred = 0;
	reg legacy_serial_sequence_has_occurred = 0;
	reg trigger_has_occurred = 0;
	assign status8[7] = ~first_pll_locked;
	assign status8[6:4] = { 1'b0, 1'b0, 1'b0 };
	assign status8[3] = dreset_sequence_has_occurred;
	assign status8[2] = legacy_serial_sequence_has_occurred;
	assign status8[1] = i2c_transfer_has_occurred;
	assign status8[0] = trigger_has_occurred;
	assign led = status8;
	// ----------------------------------------------------------------------
	wire something_happened = initiate_dreset_sequence || initiate_legacy_serial_sequence || initiate_trigger || initiate_i2c_transfer;
	wire anything_that_is_going_on = tok_a_out || pclk || sclk || sin || dreset || auxtrig || trigin || something_happened;
	wire data_a;
	IBUFDS data_in (.I(data_a_out_p), .IB(data_a_out_n), .O(data_a));
//	wire [3:0] nybble;
//	wire [1:0] nybble_counter;
	wire [15:0] data_word_from_asic;
	wire header, meat, footer, fifo_write_strobe, msn; // msn = most significant nybble
	alpha_readout alpha_readout (.clock(sysclk), .reset(reset), .data_a(data_a), .header(header), .meat(meat), .footer(footer), .alfa_counter(alfa_counter), .omga_counter(omga_counter), .strobe(fifo_write_strobe), .msn(msn), .nybble(), .nybble_counter(), .data_word(data_word_from_asic));
	counter_level asic_output_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(fifo_write_strobe), .counter(asic_output_strobe_counter));
	localparam LOG2_OF_DEPTH = 13+2; // $clog2(4200)
	fifo_single_clock #(.DATA_WIDTH(16), .LOG2_OF_DEPTH(LOG2_OF_DEPTH)) fsc (.clock(sysclk), .reset(reset),
		.data_in(data_word_from_asic), .write_enable(fifo_write_strobe && msn), .full(),
		.data_out(asic_data_from_fifo), .read_enable(fifo_read_strobe), .empty());
	counter_level fifo_output_strobe_counter_thing (.clock(sysclk), .reset(reset), .in(fifo_read_strobe), .counter(fifo_output_strobe_counter));
	// tok_a_in tok_a_out anything_that_is_going_on msn header footer meat
	// ----------------------------------------------------------------------
	wire i2c_busy, i2c_nack, i2c_error;
	// ----------------------------------------------------------------------
	if (0) begin
		assign coax[0] = scl; // always reads as 0 because scl declared as an output, not an inout, so the pullup doesn't affect coax[0]
		assign coax[1] = sda;
		assign coax[2] = i2c_busy;
		assign coax[3] = i2c_nack;
		assign coax[4] = i2c_error;
		assign coax[5] = initiate_i2c_transfer;
	end else if (1) begin
		assign coax[0] = trigin;
		assign coax[1] = data_a;
		assign coax[2] = tok_a_in;
		assign coax[3] = tok_a_out;
		assign coax[4] = 0;
		assign coax[5] = 0;
	end else if (1) begin
		assign coax[0] = data_a;
		assign coax[1] = header;
		assign coax[2] = footer;
		assign coax[3] = meat;
		assign coax[4] = msn;
		assign coax[5] = tok_a_out;
	end else begin
		assign coax[0] = rpi_gpio[4];  // enable          0=inactive; 1=active
		assign coax[1] = rpi_gpio[23]; // register_select 0=address;  1=data
		assign coax[2] = rpi_gpio[5];  // read            0=write;    1=read
		assign coax[3] = rpi_gpio[22]; // ack_valid
		assign coax[4] = 0;
		assign coax[5] = 0;
	end
	reg [3:0] rot_buffered_a = 0;
	reg [3:0] rot_buffered_b = 0;
	always @(posedge sysclk) begin
		if (reset) begin
			rot_buffered_a <= 0;
			rot_buffered_b <= 0;
		end else begin
			rot_buffered_b <= rot_buffered_a;
			rot_buffered_a <= ~rot;
		end
	end
	assign coax_led[3] = rot_buffered_b[3];
	assign coax_led[2] = rot_buffered_b[2];
	assign coax_led[1] = rot_buffered_b[1];
	assign coax_led[0] = rot_buffered_b[0];
	// ----------------------------------------------------------------------
	always @(posedge sysclk) begin
		initiate_dreset_sequence <= 0;
		if (reset) begin
			dreset_sequence_has_occurred <= 0;
		end else if (should_initiate_dreset_sequence) begin
			if (should_allow_dreset_sequence) begin
				initiate_dreset_sequence <= 1'b1;
				dreset_sequence_has_occurred <= 1'b1;
			end
		end
	end
	// ----------------------------------------------------------------------
	always @(posedge sysclk) begin
		initiate_legacy_serial_sequence <= 0;
		if (reset) begin
			legacy_serial_sequence_has_occurred <= 0;
		end else if (should_initiate_legacy_serial_sequence) begin
			if (should_allow_legacy_serial_sequence) begin
				initiate_legacy_serial_sequence <= 1'b1;
				legacy_serial_sequence_has_occurred <= 1'b1;
			end
		end
	end
	// ----------------------------------------------------------------------
	always @(posedge sysclk) begin
		initiate_i2c_transfer <= 0;
		if (reset) begin
			i2c_transfer_has_occurred <= 0;
		end else if (should_initiate_i2c_transfer) begin
			if (should_allow_i2c_transfer) begin
				initiate_i2c_transfer <= 1'b1;
				i2c_transfer_has_occurred <= 1'b1;
			end
		end
	end
	// ----------------------------------------------------------------------
	always @(posedge sysclk) begin
		initiate_trigger <= 0;
		if (reset) begin
			trigger_has_occurred <= 0;
			number_of_triggers_since_reset <= 0;
		end else if (should_trigger) begin
			if (should_allow_trigger) begin
				initiate_trigger <= 1'b1;
				trigger_has_occurred <= 1'b1;
				number_of_triggers_since_reset <= number_of_triggers_since_reset + 1'b1;
			end
		end
	end
	// ----------------------------------------------------------------------
	alpha_control alpha_control (.clock(sysclk), .reset(reset), .sync(sync), .dreset(dreset), .tok_a_in(tok_a_in),
		.initiate_trigger(initiate_trigger), .trig(trigin), .initiate_dreset_sequence(initiate_dreset_sequence),
		.scl(scl), .sda(sda),
		.i2c_busy(i2c_busy), .i2c_nack(i2c_nack), .i2c_error(i2c_error), .initiate_i2c_transfer(initiate_i2c_transfer),
		.i2c_address_register_enables(i2c_address_register_enables),
		.sin(sin), .pclk(pclk), .sclk(sclk), .initiate_legacy_serial_sequence(initiate_legacy_serial_sequence),
		.I2CupAddr(I2CupAddr), .LVDSA_pwr(LVDSA_pwr), .LVDSB_pwr(LVDSB_pwr), .SRCsel(SRCsel), .TMReg_Reset(TMReg_Reset), 
		.samples_after_trigger(samples_after_trigger), .lookback_windows(lookback_windows), .number_of_samples(number_of_samples), 
		.PCLK_period(PCLK_period), .PCLK_4DACs(PCLK_4DACs),
		.least_significant_nybbles(least_significant_nybbles), .most_significant_nybble(most_significant_nybble),
		.CMPbias(CMPbias), .ISEL(ISEL), .SBbias(SBbias), .DBbias(DBbias));
endmodule

