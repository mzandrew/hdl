// written 2023-10-09 by mza
// last updated 2024-10-18 by mza

`ifndef IRSX_LIB
`define IRSX_LIB

//`include "lib/RAM8.v"
`include "RAM8.v"
`include "frequency_counter.v"

module irsx_write_to_storage #(
) (
);
endmodule

//	irsx_wilkinson_convert #() wilkie (.gcc_clock(), .reset(), .should_start_wilkinson_conversion_now(), .convert(), .done_out(), .done_out_buffered(), .convert_counter(), .done_out_counter());
module irsx_wilkinson_convert #(
	parameter CONVERT_DURATION_IN_GCC_CLOCKS = 4000,
	parameter LOG_BASE2_OF_CONVERT_DURATION_IN_GCC_CLOCKS = $clog2(CONVERT_DURATION_IN_GCC_CLOCKS),
	parameter DONE_OUT_PIPELINE_DEPTH = 8
) (
	input gcc_clock, // 254 MHz
	input reset,
	input should_start_wilkinson_conversion_now,
	output reg [31:0] convert_counter,
	output reg [31:0] done_out_counter,
	output reg convert,
	input done_out,
	output reg done_out_buffered
);
	reg [15:0] should_start_wilkinson_conversion_now_pipeline = 0;
	reg [LOG_BASE2_OF_CONVERT_DURATION_IN_GCC_CLOCKS:0] convert_duration_counter = 0;
	reg [DONE_OUT_PIPELINE_DEPTH-1:0] done_out_pipeline = 0;
	always @(posedge gcc_clock) begin
		done_out_buffered <= 0;
		convert <= 0;
		if (reset) begin
			convert_counter <= 0;
			done_out_counter <= 0;
			done_out_pipeline <= 0;
			convert_duration_counter <= 0;
			should_start_wilkinson_conversion_now_pipeline <= 0;
		end else begin
			if (should_start_wilkinson_conversion_now_pipeline[15:14]==2'b01) begin
				convert_counter <= convert_counter + 1'b1;
				convert_duration_counter <= CONVERT_DURATION_IN_GCC_CLOCKS;
			end
			if (convert_duration_counter) begin
				convert <= 1'b1;
				convert_duration_counter <= convert_duration_counter - 1'b1;
			end
			if (done_out_pipeline[DONE_OUT_PIPELINE_DEPTH-1:DONE_OUT_PIPELINE_DEPTH-2]==2'b01) begin
				done_out_counter <= done_out_counter + 1'b1;
				done_out_buffered <= 1'b1;
			end
			done_out_pipeline <= { done_out_pipeline[DONE_OUT_PIPELINE_DEPTH-2:0], done_out };
			should_start_wilkinson_conversion_now_pipeline <= { should_start_wilkinson_conversion_now_pipeline[14:0], should_start_wilkinson_conversion_now }; // this assumes gcc_clock is faster than word_clock
		end
	end
endmodule

module irsx_read_hs_data_from_storage #(
	parameter TESTBENCH = 0,
	parameter DATA_WIDTH = 12,
	parameter LOG2_OF_DEPTH = 9, // 9 = 64 samples by 8 channels
	parameter SERIES = "spartan6",
	parameter BIT_DEPTH = 8,
	parameter HS_DATA_INTENDED_NUMBER_OF_BITS = 25,
	parameter HS_DATA_EXTRA_BITS_TO_CAPTURE = 28,
	parameter HS_DATA_RATIO = 4,
	parameter HS_DATA_PICKOFF = HS_DATA_INTENDED_NUMBER_OF_BITS*HS_DATA_RATIO+HS_DATA_EXTRA_BITS_TO_CAPTURE, // sampling at 1018 MHz; hs_clk is 254 MHz
	parameter COUNTERWORD_BIT_PICKOFF = TESTBENCH ? 5 : 23
) (
	input hs_data,
	input hs_bit_clk_raw,
	input hs_word_clock,
	input input_pll_locked,
	input [6:0] hs_data_offset,
	input [4:0] hs_data_ss_incr,
	input [4:0] hs_data_capture,
	input [LOG2_OF_DEPTH-1:0] read_address,
	output [DATA_WIDTH-1:0] data_out,
	output reg [HS_DATA_PICKOFF:0] buffered_hs_data_stream = 0,
	output reg ss_incr = 1,
	output hs_pll_is_locked_and_strobe_is_aligned,
	output [HS_DATA_INTENDED_NUMBER_OF_BITS-1:0] hs_data_word_decimated
);
	genvar i;
	wire hs_bit_clk, hs_bit_strobe;
	BUFPLL #(
		.ENABLE_SYNC("TRUE"), // synchronizes strobe to gclk input
		.DIVIDE(BIT_DEPTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
	) hs_bufpll_inst (
		.PLLIN(hs_bit_clk_raw), // PLL Clock input
		.GCLK(hs_word_clock), // Global Clock input
		.LOCKED(input_pll_locked), // Clock0 locked input
		.IOCLK(hs_bit_clk), // Output PLL Clock
		.LOCK(hs_pll_is_locked_and_strobe_is_aligned), // BUFPLL Clock and strobe locked
		.SERDESSTROBE(hs_bit_strobe) // Output SERDES strobe
	);
	wire hs_reset = 1'b0;
//	reset_wait4pll_synchronized #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset1_input(1'b0), .pll_locked1_input(input_pll_locked), .clock1_input(word_clock), .clock2_input(hs_word_clock), .reset2_output(hs_reset));
	// ----------------------------------------------------------------------
	wire [7:0] hs_data_word;
	iserdes_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE("p")) hs_data_iserdes (.bit_clock(hs_bit_clk), .bit_strobe(hs_bit_strobe), .word_clock(hs_word_clock), .reset(hs_reset), .data_in(hs_data), .word_out(hs_data_word));
	reg [HS_DATA_PICKOFF:0] hs_data_stream = 0;
	reg [4:0] hs_data_counter = 0;
	reg [LOG2_OF_DEPTH-1:0] write_address = 0;
	reg write_strobe = 0;
	always @(posedge hs_word_clock) begin
		ss_incr <= 1;
		write_strobe <= 0;
		if (hs_reset) begin
			hs_data_stream <= 0;
			hs_data_counter <= 0;
			write_address <= 0;
		end else begin
			if (hs_data_counter==hs_data_ss_incr) begin
				ss_incr <= 0;
			end
			if (hs_data_counter==hs_data_capture) begin
				buffered_hs_data_stream <= hs_data_stream;
				write_strobe <= 1;
				write_address <= write_address + 1'b1;
			end
			hs_data_stream <= { hs_data_stream[HS_DATA_PICKOFF-8:0], hs_data_word };
			hs_data_counter <= hs_data_counter + 1'b1;
		end
	end
	for (i=0; i<HS_DATA_INTENDED_NUMBER_OF_BITS; i=i+1) begin : hs_data_decimation
		assign hs_data_word_decimated[i] = buffered_hs_data_stream[HS_DATA_RATIO*i+hs_data_offset];
	end
	wire [11:0] data_12bit = hs_data_word_decimated[HS_DATA_INTENDED_NUMBER_OF_BITS-1-:12];
	wire [LOG2_OF_DEPTH:0] write_address10 = { 1'b0, write_address };
	wire [LOG2_OF_DEPTH:0] read_address10  = { 1'b0, read_address };
	wire [15:0] data_in16 = { 4'b0, data_12bit };
	wire [15:0] data_out16;
	assign data_out = data_out16[DATA_WIDTH-1:0];
	RAM_unidirectional  #(.DATA_WIDTH_A(16), .DATA_WIDTH_B(16), .ADDRESS_WIDTH_A(LOG2_OF_DEPTH+1), .SERIES(SERIES)) chock_a_block ( .reset(hs_reset),
		.clock_a(hs_word_clock), .address_a(write_address10), .data_in_a(data_in16), .write_enable_a(write_strobe),
		.clock_b(hs_word_clock), .address_b(read_address10), .data_out_b(data_out16));
endmodule

//irsx_scaler_counter_interface #(.COUNTER_WIDTH(8), .SCALER_WIDTH(4), .CLOCK_PERIODS_TO_ACCUMULATE(16)) irsx_scaler_counter (
//	.clock(clock), .reset(reset), .clear_channel_counters(clear_channel_counters), .timeout(timeout),
//	.iserdes_word_in0(in0), .iserdes_word_in1(in1), .iserdes_word_in2(in2), .iserdes_word_in3(in3),
//	.sc0(sc0), .sc1(sc1), .sc2(sc2), .sc3(sc3), .sc4(sc4), .sc5(sc5), .sc6(sc6), .sc7(sc7),
//	.c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7),
//	.t0(t0), .t1(t1), .t2(t2), .t3(t3), .t4(t4), .t5(t5), .t6(t6), .t7(t7));
module irsx_scaler_counter_dual_trigger_interface #(
	parameter TRIGSTREAM_LENGTH = 50,
	parameter LOG2_OF_TRIGSTREAM_LENGTH = $clog2(TRIGSTREAM_LENGTH) - 1, // 5
	parameter NUMBER_OF_TRIGGER_CHANNELS = 4,
	parameter NUMBER_OF_CHANNELS = 8,
	parameter COUNTER_WIDTH = 32,
	parameter SCALER_WIDTH = 16,
	parameter CLOCK_PERIODS_TO_ACCUMULATE = 2**15
) (
	input clock, reset,
	input clear_channel_counters, // also acts as a sync for the scalers
	input [7:0] iserdes_word_in0, iserdes_word_in1, iserdes_word_in2, iserdes_word_in3,
	input [LOG2_OF_TRIGSTREAM_LENGTH:0] even_channel_trigger_width,
	input [LOG2_OF_TRIGSTREAM_LENGTH:0] odd_channel_trigger_width,
	input [31:0] timeout,
	output reg scaler_valid = 0,
	output [SCALER_WIDTH-1:0] sc0, sc1, sc2, sc3, sc4, sc5, sc6, sc7,
	output [COUNTER_WIDTH-1:0] c0, c1, c2, c3, c4, c5, c6, c7,
	output t0, t1, t2, t3, t4, t5, t6, t7
);
	genvar i;
	wire [NUMBER_OF_CHANNELS-1:0] t;
	assign t[0] = t0; assign t[1] = t1; assign t[2] = t2; assign t[3] = t3;
	assign t[4] = t4; assign t[5] = t5; assign t[6] = t6; assign t[7] = t7;
	reg [COUNTER_WIDTH-1:0] c [NUMBER_OF_CHANNELS-1:0];
	assign c0 = c[0]; assign c1 = c[1]; assign c2 = c[2]; assign c3 = c[3];
	assign c4 = c[4]; assign c5 = c[5]; assign c6 = c[6]; assign c7 = c[7];
	reg [SCALER_WIDTH-1:0] sc [NUMBER_OF_CHANNELS-1:0];
	assign sc0 = sc[0]; assign sc1 = sc[1]; assign sc2 = sc[2]; assign sc3 = sc[3];
	assign sc4 = sc[4]; assign sc5 = sc[5]; assign sc6 = sc[6]; assign sc7 = sc[7];
	reg [31:0] timer = 0;
	reg [SCALER_WIDTH-1:0] temporary_counter [NUMBER_OF_CHANNELS-1:0];
	for (i=0; i<NUMBER_OF_CHANNELS; i=i+1) begin : scalers_counters
		always @(posedge clock) begin
			scaler_valid <= 0;
			if (reset || clear_channel_counters) begin
				temporary_counter[i] <= 0;
				c[i] <= 0;
				sc[i] <= 0;
				timer <= timeout;
			end else begin
				timer <= timer - 1'b1;
				if (t[i]) begin
					temporary_counter[i] <= temporary_counter[i] + 1'b1;
					c[i] <= c[i] + 1'b1;
				end
				if (timer==0) begin
					timer <= timeout;
					sc[i] <= temporary_counter[i];
					scaler_valid <= 1'b1;
					temporary_counter[i] <= 0;
				end
			end
		end
	end
	wire [8-1:0] iserdes_word_in [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	assign iserdes_word_in[0] = iserdes_word_in0;
	assign iserdes_word_in[1] = iserdes_word_in1;
	assign iserdes_word_in[2] = iserdes_word_in2;
	assign iserdes_word_in[3] = iserdes_word_in3;
	reg [TRIGSTREAM_LENGTH-1:0] trigger_stream [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-2:0] trigger_stream_offset2 [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-3:0] trigger_stream_offset3 [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-4:0] trigger_stream_offset4 [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-5:0] trigger_stream_offset5 [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-6:0] trigger_stream_offset6 [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-7:0] trigger_stream_offset7 [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-8:0] trigger_stream_offset8 [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	wire [TRIGSTREAM_LENGTH-1-9:0] trigger_stream_offset9 [NUMBER_OF_TRIGGER_CHANNELS-1:0];
	for (i=0; i<NUMBER_OF_TRIGGER_CHANNELS; i=i+1) begin : trigger_stream_offset_mapping
		assign trigger_stream_offset2[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:2];
		assign trigger_stream_offset3[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:3];
		assign trigger_stream_offset4[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:4];
		assign trigger_stream_offset5[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:5];
		assign trigger_stream_offset6[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:6];
		assign trigger_stream_offset7[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:7];
		assign trigger_stream_offset8[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:8];
		assign trigger_stream_offset9[i] = trigger_stream[i][TRIGSTREAM_LENGTH-1:9];
	end
	reg [NUMBER_OF_TRIGGER_CHANNELS-1:0] even_channel_hit = 0;
	reg [NUMBER_OF_TRIGGER_CHANNELS-1:0] odd_channel_hit = 0;
	for (i=0; i<NUMBER_OF_TRIGGER_CHANNELS; i=i+1) begin : trigger_stream_mapping
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
	assign t0 = even_channel_hit[0];
	assign t2 = even_channel_hit[1];
	assign t4 = even_channel_hit[2];
	assign t6 = even_channel_hit[3];
	assign t1 = odd_channel_hit[0];
	assign t3 = odd_channel_hit[1];
	assign t5 = odd_channel_hit[2];
	assign t7 = odd_channel_hit[3];
endmodule

module irsx_scaler_counter_dual_trigger_interface_tb #(
	parameter N4UMBER_OF_TRIGGER_CHANNELS = 4,
	parameter TRIGSTREAM_LENGTH = 40,
	parameter LOG2_OF_TRIGSTREAM_LENGTH = $clog2(TRIGSTREAM_LENGTH) - 1,
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
	reg [7:0] in0 = 0, in1 = 0, in2 = 0, in3 = 0;
	reg clear_channel_counters = 0;
	wire [COUNTER_WIDTH-1:0] c0, c1, c2, c3, c4, c5, c6, c7;
	wire [SCALER_WIDTH-1:0] sc0, sc1, sc2, sc3, sc4, sc5, sc6, sc7;
	wire t0, t1, t2, t3, t4, t5, t6, t7;
	reg [LOG2_OF_TRIGSTREAM_LENGTH:0] even_channel_trigger_width = 20;
	reg [LOG2_OF_TRIGSTREAM_LENGTH:0] odd_channel_trigger_width = 10;
	reg [31:0] timeout = 25;
	wire scaler_valid;
	always begin
		#HALF_CLOCK_PERIOD; clock <= ~clock;
	end
	always @(posedge clock) begin
		in0 <= pre_in0; in1 <= pre_in1; in2 <= pre_in2; in3 <= pre_in3;
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
		clear_channel_counters <= 1'b1; #WHOLE_CLOCK_PERIOD; clear_channel_counters <= 0;
		#TIME_PASSES;
		#TIME_PASSES;
		$finish;
	end
	irsx_scaler_counter_dual_trigger_interface #(.TRIGSTREAM_LENGTH(TRIGSTREAM_LENGTH), .COUNTER_WIDTH(COUNTER_WIDTH), .SCALER_WIDTH(SCALER_WIDTH), .CLOCK_PERIODS_TO_ACCUMULATE(CLOCK_PERIODS_TO_ACCUMULATE)) irsx_scaler_counter (
		.clock(clock), .reset(reset), .clear_channel_counters(clear_channel_counters), .timeout(timeout), .scaler_valid(scaler_valid),
		.iserdes_word_in0(in0), .iserdes_word_in1(in1), .iserdes_word_in2(in2), .iserdes_word_in3(in3),
		.odd_channel_trigger_width(odd_channel_trigger_width), .even_channel_trigger_width(even_channel_trigger_width),
		.sc0(sc0), .sc1(sc1), .sc2(sc2), .sc3(sc3), .sc4(sc4), .sc5(sc5), .sc6(sc6), .sc7(sc7),
		.c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7),
		.t0(t0), .t1(t1), .t2(t2), .t3(t3), .t4(t4), .t5(t5), .t6(t6), .t7(t7));
endmodule

module irsx_register_interface #(
	parameter TESTBENCH = 0,
	parameter NUMBER_OF_ASIC_ADDRESS_BITS = 8,
	parameter NUMBER_OF_ASIC_REGISTERS = 2**NUMBER_OF_ASIC_ADDRESS_BITS, // 256
	parameter MAX_REGISTER_ADDRESS = NUMBER_OF_ASIC_REGISTERS - 1, // 255
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
	input force_write_registers_again,
	input [CLOCK_DIVISOR_COUNTER_PICKOFF:0] clock_divider_initial_value_for_register_transactions,
	input [7:0] max_retries,
	input [7:0] min_tries,
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
	reg [7:0] tries_remaining = 0;
	reg [MAX_REGISTER_ADDRESS:0] forced_rewrite = 0;
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
			retries_remaining <= max_retries + 1'b1;
			tries_remaining <= min_tries;
			last_erroneous_readback <= 0;
			shout_word <= 0;
			shout_pipeline1 <= 0;
			shout_pipeline2 <= 0;
			forced_rewrite <= 0;
		end else begin
			if (force_write_registers_again) begin
				forced_rewrite <= {NUMBER_OF_ASIC_REGISTERS{1'b1}};
			end
			shout_pipeline1 <= { shout_pipeline1[SHOUT_PIPELINE1_PICKOFF-1:0], shout };
			if (mode==2'b00) begin // scan for differences
				if (bram_wait_state==0) begin
					if (data_intended_copy!=data_readback_copy || forced_rewrite[address_10[7:0]]) begin // checking two block rams against each other at address address_10
						if (0<retries_remaining) begin
							mode <= 2'b01; // difference found, so write updated value to asic
							sin <= 1'b0;
							pclk <= 1'b0;
							sin_counter <= 2;
							pclk_counter <= 0;
							sin <= sin_word[0]; // must get this ready before the first sclk
							clock_divisor_counter <= clock_divider_initial_value_for_register_transactions;
							if (0<tries_remaining) begin
								tries_remaining <= tries_remaining - 1'b1;
								forced_rewrite[address_10[7:0]] <= 1'b1;
							end else begin
								retries_remaining <= retries_remaining - 1'b1;
								bram_wait_state <= 2; // just to force it to copy from the block ram again
							end
						end else begin
							last_erroneous_readback <= shout_word;
							shout_word <= data_intended_copy; // give up on this one
							shout_write <= 1'b1; // write it into the "actual_readback" block ram
							bram_wait_state <= 2; // just to force it to copy from the block ram again
//							retries_remaining <= 1; // is this just so that it does a readback/compare against the forced correct value?
//							tries_remaining <= 0;
						end
					end else begin
						if (address_10<=MAX_REGISTER_ADDRESS) begin
							address_10 <= address_10 + 1'b1;
						end else begin
							address_10 <= 0;
						end
						bram_wait_state <= 2; // after every address_10 change
						retries_remaining <= max_retries + 1'b1;
						tries_remaining <= min_tries;
					end
				end else if (bram_wait_state==1) begin
					data_intended_copy <= data_intended;
					data_readback_copy <= data_readback;
					bram_wait_state <= bram_wait_state - 1'b1;
				end else begin
					bram_wait_state <= bram_wait_state - 1'b1;
				end
			end else if (mode==2'b01) begin // difference found, so write updated value to asic
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
							if (0==tries_remaining) begin
								forced_rewrite[address_10[7:0]] <= 0;
							end
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
endmodule

module irsx_register_interface_tb ();
	localparam HALF_CLOCK_PERIOD = 7.861/2;
	localparam WHOLE_CLOCK_PERIOD = 2*HALF_CLOCK_PERIOD;
	localparam SEVERAL_CLOCK_PERIODS = 2*WHOLE_CLOCK_PERIOD;
	localparam MANY_CLOCK_PERIODS = 100*WHOLE_CLOCK_PERIOD;
	localparam REALLY_A_LOT_OF_CLOCK_PERIODS = 1400*WHOLE_CLOCK_PERIOD;
	localparam SO_MANY_CLOCK_PERIODS = 3*55000*WHOLE_CLOCK_PERIOD;
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
	reg [7:0] min_tries = 3;
	reg verify_with_shout = 0;
	reg force_write_registers_again = 0;
	wire [19:0] last_erroneous_readback;
	irsx_register_interface #(.TESTBENCH(1)) irsx_reg (.clock(clock), .reset(reset),
		.intended_data_in(write_data_word), .intended_data_out(read_data_word), .readback_data_out(readback_data_word),
		.number_of_transactions(number_of_register_transactions), .force_write_registers_again(force_write_registers_again),
		.number_of_readback_errors(number_of_readback_errors), .last_erroneous_readback(last_erroneous_readback),
		.clock_divider_initial_value_for_register_transactions(clock_divider_initial_value_for_register_transactions),
		.max_retries(max_retries), .min_tries(min_tries), .verify_with_shout(verify_with_shout),
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
		// -----------------------
		#REALLY_A_LOT_OF_CLOCK_PERIODS;
		force_write_registers_again <= 1'b1; #WHOLE_CLOCK_PERIOD; force_write_registers_again <= 0;
		#SO_MANY_CLOCK_PERIODS;
		$finish;
	end
endmodule

`endif

