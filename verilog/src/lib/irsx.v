// written 2023-10-09 by mza
// last updated 2024-06-03 by mza

`ifndef IRSX_LIB
`define IRSX_LIB

//`include "lib/RAM8.v"
`include "RAM8.v"
`include "frequency_counter.v"

//module irsx_hs_data_out #(
//) (
//);
//				data_stream[i] <= { data_stream[i][DATASTREAM_LENGTH-1-8:0], iserdes_word_in[i] };
//endmodule

//irsx_scaler_counter_interface #(.COUNTER_WIDTH(8), .SCALER_WIDTH(4), .CLOCK_PERIODS_TO_ACCUMULATE(16)) irsx_scaler_counter (
//	.clock(clock), .reset(reseT), .clear_channel_counters(clear_channel_counters),
//	.iserdes_word_in0(in0), .iserdes_word_in1(in1), .iserdes_word_in2(in2), .iserdes_word_in3(in3),
//	.iserdes_word_in4(in4), .iserdes_word_in5(in5), .iserdes_word_in6(in6), .iserdes_word_in7(in7),
//	.sc0(sc0), .sc1(sc1), .sc2(sc2), .sc3(sc3), .sc4(sc4), .sc5(sc5), .sc6(sc6), .sc7(sc7),
//	.c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7));
module irsx_scaler_counter_dual_trigger_interface #(
	parameter TRIGSTREAM_LENGTH = 50,
	parameter LOG2_OF_TRIGSTREAM_LENGTH = $clog2(TRIGSTREAM_LENGTH),
	parameter NUMBER_OF_CHANNELS = 8,
	parameter COUNTER_WIDTH = 32,
	parameter SCALER_WIDTH = 16,
	parameter CLOCK_PERIODS_TO_ACCUMULATE = 2**15
) (
	input clock, reset,
	input clear_channel_counters,
	input [7:0] iserdes_word_in0, iserdes_word_in1, iserdes_word_in2, iserdes_word_in3,
	input [7:0] iserdes_word_in4, iserdes_word_in5, iserdes_word_in6, iserdes_word_in7,
	input [LOG2_OF_TRIGSTREAM_LENGTH:0] even_channel_trigger_width,
	input [LOG2_OF_TRIGSTREAM_LENGTH:0] odd_channel_trigger_width,
	output [SCALER_WIDTH-1:0] sc0, sc1, sc2, sc3, sc4, sc5, sc6, sc7,
	output [COUNTER_WIDTH-1:0] c0, c1, c2, c3, c4, c5, c6, c7,
	output reg [NUMBER_OF_CHANNELS-1:0] even_channel_hit = 0,
	output reg [NUMBER_OF_CHANNELS-1:0] odd_channel_hit = 0
);
	iserdes_counter_array8 #(
		.BIT_DEPTH(8), .REGISTER_WIDTH(COUNTER_WIDTH), .NUMBER_OF_CHANNELS(8)
	) counters (
		.clock(clock), .reset(reset || clear_channel_counters),
		.in0(iserdes_word_in0), .in1(iserdes_word_in1), .in2(iserdes_word_in2), .in3(iserdes_word_in3),
		.in4(iserdes_word_in4), .in5(iserdes_word_in5), .in6(iserdes_word_in6), .in7(iserdes_word_in7),
		.out0(c0), .out1(c1), .out2(c2), .out3(c3), .out4(c4), .out5(c5), .out6(c6), .out7(c7)
	);
	iserdes_scaler_array8 #(
		.BIT_DEPTH(8), .REGISTER_WIDTH(SCALER_WIDTH), .CLOCK_PERIODS_TO_ACCUMULATE(CLOCK_PERIODS_TO_ACCUMULATE), .NUMBER_OF_CHANNELS(8)
	) scalers (
		.clock(clock), .reset(reset),
		.in0(iserdes_word_in0), .in1(iserdes_word_in1), .in2(iserdes_word_in2), .in3(iserdes_word_in3),
		.in4(iserdes_word_in4), .in5(iserdes_word_in5), .in6(iserdes_word_in6), .in7(iserdes_word_in7),
		.out0(sc0), .out1(sc1), .out2(sc2), .out3(sc3), .out4(sc4), .out5(sc5), .out6(sc6), .out7(sc7)
	);
	wire [8-1:0] iserdes_word_in [NUMBER_OF_CHANNELS-1:0];
	assign iserdes_word_in[0] = iserdes_word_in0;
	assign iserdes_word_in[1] = iserdes_word_in1;
	assign iserdes_word_in[2] = iserdes_word_in2;
	assign iserdes_word_in[3] = iserdes_word_in3;
	assign iserdes_word_in[4] = iserdes_word_in4;
	assign iserdes_word_in[5] = iserdes_word_in5;
	assign iserdes_word_in[6] = iserdes_word_in6;
	assign iserdes_word_in[7] = iserdes_word_in7;
	reg [TRIGSTREAM_LENGTH-1:0] trigger_stream [NUMBER_OF_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-2:0] trigger_stream_offset2 [NUMBER_OF_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-3:0] trigger_stream_offset3 [NUMBER_OF_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-4:0] trigger_stream_offset4 [NUMBER_OF_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-5:0] trigger_stream_offset5 [NUMBER_OF_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-6:0] trigger_stream_offset6 [NUMBER_OF_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-7:0] trigger_stream_offset7 [NUMBER_OF_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-8:0] trigger_stream_offset8 [NUMBER_OF_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-9:0] trigger_stream_offset9 [NUMBER_OF_CHANNELS-1:0];
	genvar i;
	for (i=0; i<NUMBER_OF_CHANNELS; i=i+1) begin : trigger_stream_offset_mapping
		assign trigger_stream_offset2[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:2];
		assign trigger_stream_offset3[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:3];
		assign trigger_stream_offset4[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:4];
		assign trigger_stream_offset5[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:5];
		assign trigger_stream_offset6[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:6];
		assign trigger_stream_offset7[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:7];
		assign trigger_stream_offset8[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:8];
		assign trigger_stream_offset9[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:9];
	end
	for (i=0; i<NUMBER_OF_CHANNELS; i=i+1) begin : trigger_stream_mapping
		always @(posedge clock) begin
			even_channel_hit[i] <= 0;
			odd_channel_hit[i] <= 0;
			if (reset) begin
				trigger_stream[i] <= 0;
			end else begin
				if (trigger_stream[i][1:0]==2'b10) begin
					if (trigger_stream_offset2[i][even_channel_trigger_width]) begin
						odd_channel_hit[i] <= 1'b1;
						even_channel_hit[i] <= 1'b1;
					end else if (trigger_stream_offset2[i][odd_channel_trigger_width]) begin
						even_channel_hit[i] <= 1'b1;
					end else begin
						odd_channel_hit[i] <= 1'b1;
					end
				end else if (trigger_stream[i][2:1]==2'b10) begin
					if (trigger_stream_offset3[i][even_channel_trigger_width]) begin
						odd_channel_hit[i] <= 1'b1;
						even_channel_hit[i] <= 1'b1;
					end else if (trigger_stream_offset3[i][odd_channel_trigger_width]) begin
						even_channel_hit[i] <= 1'b1;
					end else begin
						odd_channel_hit[i] <= 1'b1;
					end
				end else if (trigger_stream[i][3:2]==2'b10) begin
					if (trigger_stream_offset4[i][even_channel_trigger_width]) begin
						odd_channel_hit[i] <= 1'b1;
						even_channel_hit[i] <= 1'b1;
					end else if (trigger_stream_offset4[i][odd_channel_trigger_width]) begin
						even_channel_hit[i] <= 1'b1;
					end else begin
						odd_channel_hit[i] <= 1'b1;
					end
				end else if (trigger_stream[i][4:3]==2'b10) begin
					if (trigger_stream_offset5[i][even_channel_trigger_width]) begin
						odd_channel_hit[i] <= 1'b1;
						even_channel_hit[i] <= 1'b1;
					end else if (trigger_stream_offset5[i][odd_channel_trigger_width]) begin
						even_channel_hit[i] <= 1'b1;
					end else begin
						odd_channel_hit[i] <= 1'b1;
					end
				end else if (trigger_stream[i][5:4]==2'b10) begin
					if (trigger_stream_offset6[i][even_channel_trigger_width]) begin
						odd_channel_hit[i] <= 1'b1;
						even_channel_hit[i] <= 1'b1;
					end else if (trigger_stream_offset6[i][odd_channel_trigger_width]) begin
						even_channel_hit[i] <= 1'b1;
					end else begin
						odd_channel_hit[i] <= 1'b1;
					end
				end else if (trigger_stream[i][6:5]==2'b10) begin
					if (trigger_stream_offset7[i][even_channel_trigger_width]) begin
						odd_channel_hit[i] <= 1'b1;
						even_channel_hit[i] <= 1'b1;
					end else if (trigger_stream_offset7[i][odd_channel_trigger_width]) begin
						even_channel_hit[i] <= 1'b1;
					end else begin
						odd_channel_hit[i] <= 1'b1;
					end
				end else if (trigger_stream[i][7:6]==2'b10) begin
					if (trigger_stream_offset8[i][even_channel_trigger_width]) begin
						odd_channel_hit[i] <= 1'b1;
						even_channel_hit[i] <= 1'b1;
					end else if (trigger_stream_offset8[i][odd_channel_trigger_width]) begin
						even_channel_hit[i] <= 1'b1;
					end else begin
						odd_channel_hit[i] <= 1'b1;
					end
				end else if (trigger_stream[i][8:7]==2'b10) begin
					if (trigger_stream_offset9[i][even_channel_trigger_width]) begin
						odd_channel_hit[i] <= 1'b1;
						even_channel_hit[i] <= 1'b1;
					end else if (trigger_stream_offset9[i][odd_channel_trigger_width]) begin
						even_channel_hit[i] <= 1'b1;
					end else begin
						odd_channel_hit[i] <= 1'b1;
					end
				end
				trigger_stream[i] <= { trigger_stream[i][TRIGSTREAM_LENGTH-1-8:0], iserdes_word_in[i] };
			end
		end
	end
endmodule

module irsx_scaler_counter_dual_trigger_interface_tb #(
	parameter NUMBER_OF_CHANNELS = 8,
	parameter TRIGSTREAM_LENGTH = 40,
	parameter LOG2_OF_TRIGSTREAM_LENGTH = $clog2(TRIGSTREAM_LENGTH),
	parameter ACCUMULATOR_WIDTH = 4,
	parameter RUNNING_TOTAL_WIDTH = ACCUMULATOR_WIDTH + 2,
	parameter COUNTER_WIDTH = 8,
	parameter SCALER_WIDTH = 4,
	parameter CLOCK_PERIODS_TO_ACCUMULATE = 16,
	parameter HALF_CLOCK_PERIOD = 7.861/2,
	parameter WHOLE_CLOCK_PERIOD = 2*HALF_CLOCK_PERIOD,
	parameter TIME_PASSES = 7*WHOLE_CLOCK_PERIOD
) ();
	reg clock = 0;
	reg reset = 1;
	reg [7:0] pre_in0 = 0; reg [7:0] pre_in1 = 0; reg [7:0] pre_in2 = 0; reg [7:0] pre_in3 = 0;
	reg [7:0] pre_in4 = 0; reg [7:0] pre_in5 = 0; reg [7:0] pre_in6 = 0; reg [7:0] pre_in7 = 0;
	reg [7:0] in0, in1, in2, in3, in4, in5, in6, in7;
	reg clear_channel_counters = 0;
	wire [RUNNING_TOTAL_WIDTH-1:0] t0, t1, t2, t3, t4, t5, t6, t7;
	wire [COUNTER_WIDTH-1:0] c0, c1, c2, c3, c4, c5, c6, c7;
	wire [SCALER_WIDTH-1:0] sc0, sc1, sc2, sc3, sc4, sc5, sc6, sc7;
	reg [LOG2_OF_TRIGSTREAM_LENGTH:0] even_channel_trigger_width = 20;
	reg [LOG2_OF_TRIGSTREAM_LENGTH:0] odd_channel_trigger_width = 10;
	wire [NUMBER_OF_CHANNELS-1:0] even_channel_hit;
	wire [NUMBER_OF_CHANNELS-1:0] odd_channel_hit;
	always begin
		#HALF_CLOCK_PERIOD; clock <= ~clock;
	end
	always @(posedge clock) begin
		in0 <= pre_in0; in1 <= pre_in1; in2 <= pre_in2; in3 <= pre_in3;
		in4 <= pre_in4; in5 <= pre_in5; in6 <= pre_in6; in7 <= pre_in7;
	end
	initial begin
		#TIME_PASSES;
		reset <= 0;
		pre_in0 <= 8'b01100110; #WHOLE_CLOCK_PERIOD; pre_in0 <= 0; #WHOLE_CLOCK_PERIOD;
		#TIME_PASSES;
		pre_in0 <= 8'b00000100; #WHOLE_CLOCK_PERIOD; pre_in0 <= 0; #WHOLE_CLOCK_PERIOD;
		#TIME_PASSES;
		pre_in0 <= 8'b00111100; #WHOLE_CLOCK_PERIOD; pre_in0 <= 0; #WHOLE_CLOCK_PERIOD;
		#TIME_PASSES;
		pre_in0 <= 8'b10101010; #WHOLE_CLOCK_PERIOD; pre_in0 <= 0; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b01010101; #WHOLE_CLOCK_PERIOD; pre_in0 <= 0; #WHOLE_CLOCK_PERIOD;
		#TIME_PASSES;
		pre_in0 <= 8'b01010101; #WHOLE_CLOCK_PERIOD; pre_in0 <= 0; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b10101010; #WHOLE_CLOCK_PERIOD; pre_in0 <= 0; #WHOLE_CLOCK_PERIOD;
		#TIME_PASSES;
		#TIME_PASSES;
		#TIME_PASSES;
		// even trigger only:
		pre_in0 <= 8'b00000000; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00011111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b11111000; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00000000; #WHOLE_CLOCK_PERIOD;
		#TIME_PASSES;
		#TIME_PASSES;
		// odd trigger only:
		pre_in0 <= 8'b00000000; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00111111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b11111111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b11111100; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00000000; #WHOLE_CLOCK_PERIOD;
		#TIME_PASSES;
		#TIME_PASSES;
		// almost dual trigger:
		pre_in0 <= 8'b00000000; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00111111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b11111111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b11111100; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00000000; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00011111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b11111000; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00000000; #WHOLE_CLOCK_PERIOD;
		#TIME_PASSES;
		#TIME_PASSES;
		#TIME_PASSES;
		// dual trigger:
		pre_in0 <= 8'b00000000; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00111111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b11111111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b11111111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b11111111; #WHOLE_CLOCK_PERIOD;
		pre_in0 <= 8'b00000000; #WHOLE_CLOCK_PERIOD;
		#TIME_PASSES;
		#TIME_PASSES;
		#TIME_PASSES;
		#TIME_PASSES;
		$finish;
	end
	irsx_scaler_counter_dual_trigger_interface #(.TRIGSTREAM_LENGTH(TRIGSTREAM_LENGTH), .COUNTER_WIDTH(COUNTER_WIDTH), .SCALER_WIDTH(SCALER_WIDTH), .CLOCK_PERIODS_TO_ACCUMULATE(CLOCK_PERIODS_TO_ACCUMULATE)) irsx_scaler_counter (
		.clock(clock), .reset(reset), .clear_channel_counters(clear_channel_counters),
		.iserdes_word_in0(in0), .iserdes_word_in1(in1), .iserdes_word_in2(in2), .iserdes_word_in3(in3),
		.iserdes_word_in4(in4), .iserdes_word_in5(in5), .iserdes_word_in6(in6), .iserdes_word_in7(in7),
		.odd_channel_trigger_width(odd_channel_trigger_width), .even_channel_trigger_width(even_channel_trigger_width),
		.sc0(sc0), .sc1(sc1), .sc2(sc2), .sc3(sc3), .sc4(sc4), .sc5(sc5), .sc6(sc6), .sc7(sc7),
		.c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7),
		.even_channel_hit(even_channel_hit), .odd_channel_hit(odd_channel_hit));
endmodule

module irsx_register_interface #(
	parameter TESTBENCH = 0,
	parameter NUMBER_OF_ASIC_ADDRESS_BITS = 8,
	parameter MAX_REGISTER_ADDRESS = 2**NUMBER_OF_ASIC_ADDRESS_BITS - 1, // 255
	parameter NUMBER_OF_ASIC_DATA_BITS = 12,
	parameter NUMBER_OF_SIN_WORD_BITS = NUMBER_OF_ASIC_ADDRESS_BITS + NUMBER_OF_ASIC_DATA_BITS, // 20
	parameter EXTRA_STATE_COUNTER_INITIAL_VALUE = 4,
	parameter EXTRA_STATE_COUNTER_PICKOFF = $clog2(EXTRA_STATE_COUNTER_INITIAL_VALUE) + 1, // 6
	parameter CLOCK_DIVISOR_COUNTER_PICKOFF = 7
) (
	input clock, reset,
	input [NUMBER_OF_ASIC_ADDRESS_BITS-1:0] address,
	input [NUMBER_OF_ASIC_DATA_BITS-1:0] intended_data_in,
	output [NUMBER_OF_ASIC_DATA_BITS-1:0] intended_data_out,
	output [NUMBER_OF_ASIC_DATA_BITS-1:0] readback_data_out,
	output reg [NUMBER_OF_SIN_WORD_BITS-1:0] last_erroneous_readback,
	output reg [31:0] number_of_transactions = 0,
	input [CLOCK_DIVISOR_COUNTER_PICKOFF:0] clock_divider_initial_value_for_register_transactions,
	input [7:0] max_retries,
	input verify_with_shout,
	input write_enable,
	output reg sin = 0,
	output reg pclk = 0,
	output reg regclr = 1,
	output sclk,
	output reg [31:0] number_of_readback_errors = 0,
	input shout
);
	reg [CLOCK_DIVISOR_COUNTER_PICKOFF:0] clock_divisor_counter = 0;
	// both following addresses are 10 bits to easily address a whole single block ram
	wire [9:0] upstream_address_10 = { 2'b00, address }; // the address from the hdrb interface that reads from and writes to the "intended_values" bram
	reg [9:0] address_10 = 0; // the address that our state machine uses to look through the two brams to check for differences
	wire [11:0] data_intended; // from "intended_values" block ram at address address_10
	wire [11:0] data_readback; // from "actual_readback" block ram at address address_10
	reg [11:0] data_intended_copy = 0;
	reg [11:0] data_readback_copy = 0;
	RAM_s6_1k_12bit_12bit intended_values (.reset(reset),
		.clock_a(clock), .address_a(upstream_address_10), .data_in_a(intended_data_in), .write_enable_a(write_enable), .data_out_a(intended_data_out),
		.clock_b(clock), .address_b(address_10), .data_out_b(data_intended));
	wire [0:NUMBER_OF_SIN_WORD_BITS-1] sin_word = { address_10[NUMBER_OF_ASIC_ADDRESS_BITS-1:0], data_intended_copy };
	reg [5:0] sin_counter = 0;
	reg [3:0] pclk_counter = 0;
	reg [0:NUMBER_OF_SIN_WORD_BITS-1] shout_word = 0;
	localparam SHOUT_PIPELINE1_PICKOFF = 1;
	localparam SHOUT_PIPELINE2_PICKOFF = NUMBER_OF_SIN_WORD_BITS;
	reg [SHOUT_PIPELINE1_PICKOFF:0] shout_pipeline1 = 0; // runs at clock frequency; just to reduce metastability
	reg [SHOUT_PIPELINE2_PICKOFF:0] shout_pipeline2 = 0; // runs at SCLK
	wire [11:0] data_from_shout;
	assign data_from_shout = shout_word[8:NUMBER_OF_SIN_WORD_BITS-1]; // OSH and SSHSH in misc_reg168 default to 0 on powerup and that's the right thing to get shout
	reg shout_write = 0;
	RAM_s6_1k_12bit_12bit actual_readback (.reset(reset),
		.clock_a(clock), .address_a(address_10), .data_in_a(data_from_shout), .write_enable_a(shout_write), .data_out_a(data_readback), // for comparisons
		.clock_b(clock), .address_b(upstream_address_10), .data_out_b(readback_data_out)); // to readout to hdrb
	reg [1:0] mode = 0;
	assign sclk = sin_counter[0];
	reg [1:0] bram_wait_state = 2;
	reg [7:0] retries_remaining = 1;
	always @(posedge clock) begin
		regclr <= 0;
		shout_write <= 0;
		if (reset) begin
			mode <= 2'b00; // scan for differences
			regclr <= 1;
			sin <= 0;
			pclk <= 0;
			address_10 <= 0;
			bram_wait_state <= 2;
			sin_counter <= 0;
			pclk_counter <= 0;
			clock_divisor_counter <= 0;
			number_of_transactions <= 0;
			number_of_readback_errors <= 0;
			data_intended_copy <= 0;
			data_readback_copy <= 0;
			retries_remaining <= 1;
			last_erroneous_readback <= 0;
			shout_word <= 0;
			shout_pipeline1 <= 0;
			shout_pipeline2 <= 0;
		end else begin
			shout_pipeline1 <= { shout_pipeline1[SHOUT_PIPELINE1_PICKOFF-1:0], shout };
			if (mode==2'b00) begin // scan for differences
				if (bram_wait_state==0) begin
					if (data_intended_copy!=data_readback_copy) begin // checking two block rams against each other at address address_10
						if (0<retries_remaining) begin
							mode <= 2'b01; // difference found, so write updated value to asic
							sin <= 0;
							pclk <= 0;
							sin_counter <= 2;
							pclk_counter <= 0;
							sin <= sin_word[0]; // must get this ready before the first sclk
							clock_divisor_counter <= clock_divider_initial_value_for_register_transactions;
							bram_wait_state <= 2; // just to force it to copy from the block ram again
							retries_remaining <= retries_remaining - 1'b1;
						end else begin
							last_erroneous_readback <= shout_word;
							shout_word <= data_intended_copy; // give up on this one
							shout_write <= 1; // write it into the "actual_readback" block ram
							bram_wait_state <= 2; // just to force it to copy from the block ram again
							retries_remaining <= 1;
						end
					end else begin
						if (address_10<=MAX_REGISTER_ADDRESS) begin
							address_10 <= address_10 + 1'b1;
						end else begin
							address_10 <= 0;
						end
						bram_wait_state <= 2; // after every address_10 change
						retries_remaining <= max_retries + 1'b1;
					end
				end else if (bram_wait_state==1) begin
					data_intended_copy <= data_intended;
					data_readback_copy <= data_readback;
					bram_wait_state <= bram_wait_state - 1'b1;
				end else begin
					bram_wait_state <= bram_wait_state - 1'b1;
				end
			end else begin
				if (mode==2'b01) begin // difference found, so write updated value to asic
					if (clock_divisor_counter==0) begin
						clock_divisor_counter <= clock_divider_initial_value_for_register_transactions;
						if (sin_counter<2*NUMBER_OF_SIN_WORD_BITS) begin
							if (sclk) begin
								sin <= sin_word[sin_counter[5:1]];
							end
							sin_counter <= sin_counter + 1'b1;
						end else if (sin_counter<2*NUMBER_OF_SIN_WORD_BITS+2) begin
							pclk_counter <= 0;
							sin_counter <= sin_counter + 1'b1; // the last sclk
						end else begin
							if (pclk_counter==0) begin
								sin <= 0;
							end else if (pclk_counter==1) begin
								pclk <= 1; // "latch" a.k.a. "load bus register"
							end else if (pclk_counter==2) begin
								pclk <= 0;
							end else if (pclk_counter==3) begin
								sin <= 1;
							end else if (pclk_counter==4) begin
								pclk <= 1; // "load" a.k.a. "load destination/address node"
							end else if (pclk_counter==5) begin
								pclk <= 0;
							end else if (pclk_counter==6) begin
								sin <= 0;
							end else if (pclk_counter==7) begin
								if (verify_with_shout) begin
									mode <= 2'b10; // readback shout
								end else begin
									shout_word <= data_intended_copy;
									shout_write <= 1; // write it into the "actual_readback" block ram
									bram_wait_state <= 2;
									mode <= 2'b00; // scan for differences
								end
								number_of_transactions <= number_of_transactions + 1'b1;
								sin_counter <= 0;
							end
							pclk_counter <= pclk_counter + 1'b1;
						end
					end else begin
						clock_divisor_counter <= clock_divisor_counter - 1'b1;
					end
				end else if (mode==2'b10) begin // readback shout
					if (clock_divisor_counter==0) begin
						clock_divisor_counter <= clock_divider_initial_value_for_register_transactions + 2'd2;
						if (sin_counter<2*NUMBER_OF_SIN_WORD_BITS) begin
							if (sclk==0) begin
								shout_pipeline2 <= { shout_pipeline2[SHOUT_PIPELINE2_PICKOFF-1:0], shout_pipeline1[SHOUT_PIPELINE1_PICKOFF] };
							end
							sin_counter <= sin_counter + 1'b1;
							pclk_counter <= 0;
						end else if (pclk_counter==0) begin
							shout_pipeline2 <= { shout_pipeline2[SHOUT_PIPELINE2_PICKOFF-1:0], shout_pipeline1[SHOUT_PIPELINE1_PICKOFF] };
							pclk_counter <= pclk_counter + 1'b1;
						end else if (pclk_counter==1) begin
							shout_word <= shout_pipeline2[SHOUT_PIPELINE2_PICKOFF-:NUMBER_OF_SIN_WORD_BITS];
							shout_write <= 1; // write it into the "actual_readback" block ram
							pclk_counter <= pclk_counter + 1'b1;
						end else begin
							if (sin_word!=shout_word) begin
								number_of_readback_errors <= number_of_readback_errors + 1'b1;
							end
							mode <= 2'b00; // scan for differences
							bram_wait_state <= 2;
						end
					end else begin
						clock_divisor_counter <= clock_divisor_counter - 1'b1;
					end
				end else begin // extra state
					mode <= 2'b00; // scan for differences
				end
			end
		end
	end
endmodule

module irsx_register_interface_tb ();
	localparam HALF_CLOCK_PERIOD = 7.861/2;
	localparam WHOLE_CLOCK_PERIOD = 2*HALF_CLOCK_PERIOD;
	localparam SEVERAL_CLOCK_PERIODS = 2*WHOLE_CLOCK_PERIOD;
	localparam MANY_CLOCK_PERIODS = 100*WHOLE_CLOCK_PERIOD;
	localparam REALLY_A_LOT_OF_CLOCK_PERIODS = 1400*WHOLE_CLOCK_PERIOD;
	localparam DELAY_BETWEEN_SCLK_IN_AND_SHOUT_OUT = 16; // 10 ns, measured (scope_45.png)
	reg clock = 0;
	reg raw_reset = 1;
	reg reset = 1;
	reg shout = 0;
	wire sin, sclk, pclk, regclr;
	reg [11:0] raw_write_data_word = 0;
	reg [11:0] write_data_word = 0;
	wire [11:0] read_data_word;
	reg [7:0] raw_address_word = 0;
	reg [7:0] address_word = 0;
	reg raw_write_strobe = 0;
	reg write_strobe = 0;
	reg [19:0] shift_register = 0;
	wire [11:0] readback_data_word;
	wire [31:0] number_of_register_transactions;
	reg [7:0] clock_divider_initial_value_for_register_transactions = 0;
	wire [31:0] number_of_readback_errors;
	reg [7:0] max_retries = 5;
	reg verify_with_shout = 0;
	irsx_register_interface #(.TESTBENCH(1)) irsx_reg (.clock(clock), .reset(reset),
		.intended_data_in(write_data_word), .intended_data_out(read_data_word), .readback_data_out(readback_data_word),
		.number_of_transactions(number_of_register_transactions),
		.number_of_readback_errors(number_of_readback_errors), .last_erroneous_readback(last_erroneous_readback),
		.clock_divider_initial_value_for_register_transactions(clock_divider_initial_value_for_register_transactions),
		.max_retries(max_retries), .verify_with_shout(verify_with_shout),
		.address(address_word), .write_enable(write_strobe),
		.sin(sin), .sclk(sclk), .pclk(pclk), .regclr(regclr), .shout(shout));
	wire pre_shout = shift_register[18];
	always @(posedge clock) begin
		reset <= raw_reset;
		address_word <= raw_address_word;
		write_data_word <= raw_write_data_word;
		write_strobe <= raw_write_strobe;
	end
	always @(posedge sclk) begin
		shift_register <= { shift_register[18:0], sin };
	end
	always @(posedge sclk) begin
		shout <= #DELAY_BETWEEN_SCLK_IN_AND_SHOUT_OUT pre_shout;
	end
	always begin
		clock <= 1;
		#HALF_CLOCK_PERIOD;
		clock <= 0;
		#HALF_CLOCK_PERIOD;
	end
	initial begin
		repeat (50) begin // block ram needs a certain minimum clock cycles in reset?!?
			#WHOLE_CLOCK_PERIOD;
		end
		raw_reset <= 0;
		#500; //  wait until after the internal comparison of address_10 with 0x43
		// -----------------------
		#MANY_CLOCK_PERIODS;
		clock_divider_initial_value_for_register_transactions <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h765;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h98;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h210;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h43;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#5000; // gotta wait until the previous transactions with the asic have actually finished before changing clock_divider_initial_value_for_register_transactions
		clock_divider_initial_value_for_register_transactions <= 1;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h345;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h0a;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h567;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h13;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 0;
		raw_write_data_word <= 0;
		#6000; // gotta wait until the previous transactions with the asic have actually finished before changing clock_divider_initial_value_for_register_transactions
		clock_divider_initial_value_for_register_transactions <= 3;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h444;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h33;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_write_data_word <= 12'h777;
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 8'h66;
		#SEVERAL_CLOCK_PERIODS;
		raw_write_strobe <= 1'b1;
		#WHOLE_CLOCK_PERIOD;
		raw_write_strobe <= 1'b0;
		raw_write_data_word <= 0;
		raw_address_word <= 0;
		// -----------------------
		#SEVERAL_CLOCK_PERIODS;
		raw_address_word <= 0;
		raw_write_data_word <= 0;
		#SEVERAL_CLOCK_PERIODS;
		if (0) begin
			repeat (255) begin
				raw_address_word <= raw_address_word + 1'b1;
				raw_write_data_word <= raw_write_data_word + 1'b1;
				#WHOLE_CLOCK_PERIOD;
				raw_write_strobe <= 1'b1;
				#WHOLE_CLOCK_PERIOD;
				raw_write_strobe <= 0;
				#WHOLE_CLOCK_PERIOD;
			end
		end
		// -----------------------
		#REALLY_A_LOT_OF_CLOCK_PERIODS;
		raw_address_word <= 8'h98;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h43;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h0a;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h13;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h66;
		#MANY_CLOCK_PERIODS;
		raw_address_word <= 8'h33;
		#MANY_CLOCK_PERIODS;
		$finish;
	end
endmodule

`endif

