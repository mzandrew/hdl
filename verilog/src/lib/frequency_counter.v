// written 2020-05-29 by mza
// based on mza-test014.duration-timer.uart.v
// and mza-test022.frequency-counter.uart.v
// updated 2020-05-30 by mza
// last updated 2024-11-13 by mza

`ifndef FREQUENCY_COUNTER_LIB
`define FREQUENCY_COUNTER_LIB
`timescale 1ns / 1ps

`include "generic.v"

module frequency_counter #(
	parameter TRIGGER_STREAM_PICKOFF = 2,
	parameter VALID_PIPELINE_PICKOFF = 2,
	parameter WIDTH_OF_RESULT = 32,
	parameter FREQUENCY_OF_REFERENCE_CLOCK = 10000000,
	parameter LOG2_OF_DIVIDE_RATIO = 24, // 27 is good
	parameter MAXIMUM_EXPECTED_FREQUENCY = 250000000,
	parameter LOG2_OF_MAXIMUM_EXPECTED_FREQUENCY = $clog2(MAXIMUM_EXPECTED_FREQUENCY), // ~28
	parameter N = 100, // N for N_Hz calculations
	parameter FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ = FREQUENCY_OF_REFERENCE_CLOCK / N,
	parameter LOG2_OF_FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ = $clog2(FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ) // ~27
) (
	input reference_clock,
	input unknown_clock,
	output reg [WIDTH_OF_RESULT-1:0] frequency_of_unknown_clock,
	output reg valid = 0
);
	localparam MSB_OF_COUNTERS = LOG2_OF_DIVIDE_RATIO + 8; // 35
	localparam MSB_OF_ACCUMULATOR = LOG2_OF_MAXIMUM_EXPECTED_FREQUENCY + LOG2_OF_FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ + 3; // ~63
	localparam MSB_OF_RESULT = MSB_OF_ACCUMULATOR - LOG2_OF_DIVIDE_RATIO; // ~35
	reg [MSB_OF_ACCUMULATOR:0] accumulator = 0;
	reg [LOG2_OF_DIVIDE_RATIO:0] reference_clock_counter = 0;
	wire trigger_active = reference_clock_counter[LOG2_OF_DIVIDE_RATIO];
	reg valid__unknown = 0;
	reg [VALID_PIPELINE_PICKOFF+1:0] valid__pipeline_reference = 0;
	always @(posedge reference_clock) begin
		reference_clock_counter <= reference_clock_counter + 1'b1;
		valid <= 0;
		if (valid__pipeline_reference[VALID_PIPELINE_PICKOFF+1:VALID_PIPELINE_PICKOFF]==2'b01) begin
			valid <= 1;
		end
		valid__pipeline_reference <= { valid__pipeline_reference[VALID_PIPELINE_PICKOFF:0], valid__unknown };
	end
	reg [TRIGGER_STREAM_PICKOFF+1:0] trigger_stream = 0;
	always @(posedge unknown_clock) begin
		trigger_stream <= { trigger_stream[TRIGGER_STREAM_PICKOFF:0], trigger_active };
	end
	always @(posedge unknown_clock) begin
		if (trigger_stream[TRIGGER_STREAM_PICKOFF]) begin
			valid__unknown <= 0;
			accumulator <= accumulator + FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ;
		end else if (trigger_stream[TRIGGER_STREAM_PICKOFF+1:TRIGGER_STREAM_PICKOFF]==2'b10) begin
			frequency_of_unknown_clock <= accumulator[MSB_OF_ACCUMULATOR:LOG2_OF_DIVIDE_RATIO];
			accumulator <= 0;
			valid__unknown <= 1;
		end
	end
endmodule

`ifndef SYNTHESIS

//`include "lib/generic.v"

module frequency_counter_tb ();
	localparam FREQUENCY_OF_REFERENCE_CLOCK = 25000000;
	wire reference_clock;
	clock #(.FREQUENCY_OF_CLOCK_HZ(FREQUENCY_OF_REFERENCE_CLOCK)) ref (.clock(reference_clock));
	wire unknown_clock1;
	clock #(.FREQUENCY_OF_CLOCK_HZ( 1111111.0)) c1 (.clock(unknown_clock1));
	wire unknown_clock2;
	clock #(.FREQUENCY_OF_CLOCK_HZ(22222222.0)) c2 (.clock(unknown_clock2));
	wire unknown_clock3;
	clock #(.FREQUENCY_OF_CLOCK_HZ(  333333.0)) c3 (.clock(unknown_clock3));
	wire unknown_clock4;
	clock #(.FREQUENCY_OF_CLOCK_HZ(44444444.0)) c4 (.clock(unknown_clock4));
	wire unknown_clock;
	reg [1:0] sel = 2'b00;
	mux_4to1 #(.WIDTH(1)) m (.in0(unknown_clock1), .in1(unknown_clock2), .in2(unknown_clock3), .in3(unknown_clock4), .sel(sel), .out(unknown_clock));
	wire [31:0] frequency_of_unknown_clock;
	wire frequency_counter_sync;
	localparam LOG2_OF_DIVIDE_RATIO = 24;
	frequency_counter #(.FREQUENCY_OF_REFERENCE_CLOCK(FREQUENCY_OF_REFERENCE_CLOCK), .N(1), .LOG2_OF_DIVIDE_RATIO(LOG2_OF_DIVIDE_RATIO)) fc (.reference_clock(reference_clock), .unknown_clock(unknown_clock), .frequency_of_unknown_clock(frequency_of_unknown_clock), .valid(frequency_counter_sync));
	task automatic wait_for_sync;
		begin
			@(posedge frequency_counter_sync);
		end
	endtask
	initial begin
		#100;
		sel = 2'd0; wait_for_sync; $display("%t %9d", $time, frequency_of_unknown_clock); wait_for_sync; $display("%t %9d", $time, frequency_of_unknown_clock);
		sel = 2'd1; wait_for_sync; $display("%t %9d", $time, frequency_of_unknown_clock); wait_for_sync; $display("%t %9d", $time, frequency_of_unknown_clock);
		sel = 2'd2; wait_for_sync; $display("%t %9d", $time, frequency_of_unknown_clock); wait_for_sync; $display("%t %9d", $time, frequency_of_unknown_clock);
		sel = 2'd3; wait_for_sync; $display("%t %9d", $time, frequency_of_unknown_clock); wait_for_sync; $display("%t %9d", $time, frequency_of_unknown_clock);
		#100;
		$finish;
	end
endmodule
`endif

module ones_counter_array8 #(
	parameter BIT_DEPTH = 8,
	parameter REGISTER_WIDTH = $clog2(BIT_DEPTH)
) (
	input clock,
	input [BIT_DEPTH-1:0] in0, in1, in2, in3, in4, in5, in6, in7,
	output [REGISTER_WIDTH-1:0] out0, out1, out2, out3, out4, out5, out6, out7
);
	count_ones #(.WIDTH(BIT_DEPTH)) c0 (.clock(clock), .data_in(in0), .count_out(out0));
	count_ones #(.WIDTH(BIT_DEPTH)) c1 (.clock(clock), .data_in(in1), .count_out(out1));
	count_ones #(.WIDTH(BIT_DEPTH)) c2 (.clock(clock), .data_in(in2), .count_out(out2));
	count_ones #(.WIDTH(BIT_DEPTH)) c3 (.clock(clock), .data_in(in3), .count_out(out3));
	count_ones #(.WIDTH(BIT_DEPTH)) c4 (.clock(clock), .data_in(in4), .count_out(out4));
	count_ones #(.WIDTH(BIT_DEPTH)) c5 (.clock(clock), .data_in(in5), .count_out(out5));
	count_ones #(.WIDTH(BIT_DEPTH)) c6 (.clock(clock), .data_in(in6), .count_out(out6));
	count_ones #(.WIDTH(BIT_DEPTH)) c7 (.clock(clock), .data_in(in7), .count_out(out7));
endmodule

module iserdes_counter #(
	parameter REGISTER_WIDTH = 8,
	parameter BIT_DEPTH = 8,
	parameter LOG_BASE_2_OF_BIT_DEPTH = $clog2(BIT_DEPTH)
) (
	input clock, reset,
	input [BIT_DEPTH-1:0] in,
	output reg [REGISTER_WIDTH-1:0] out = 0
);
	reg previous_bit = 0;
	wire [1:0] a = { previous_bit, in[7] };
	wire [1:0] b = in[7:6];
	wire [1:0] c = in[6:5];
	wire [1:0] d = in[5:4];
	wire [1:0] e = in[4:3];
	wire [1:0] f = in[3:2];
	wire [1:0] g = in[2:1];
	wire [1:0] h = in[1:0];
	wire [1:0] zo = 2'b01;
	wire [LOG_BASE_2_OF_BIT_DEPTH-1:0] current_count = (zo==a?1'b1:0) + (zo==b?1'b1:0) + (zo==c?1'b1:0) + (zo==d?1'b1:0) + (zo==e?1'b1:0) + (zo==f?1'b1:0) + (zo==g?1'b1:0) + (zo==h?1'b1:0);
	reg [LOG_BASE_2_OF_BIT_DEPTH-1:0] current_count_reg = 0;
	always @(posedge clock) begin
		if (reset) begin
			out <= 0;
			current_count_reg <= 0;
			previous_bit <= 0;
		end else begin
			out <= out + current_count_reg;
			current_count_reg <= current_count;
			previous_bit <= in[0];
		end
	end
endmodule

module iserdes_counter_array8 #(
	parameter NUMBER_OF_CHANNELS = 8,
	parameter REGISTER_WIDTH = 8,
	parameter BIT_DEPTH = 8,
	parameter LOG_BASE_2_OF_BIT_DEPTH = $clog2(BIT_DEPTH)
) (
	input clock, reset,
	input [BIT_DEPTH-1:0] in0, in1, in2, in3, in4, in5, in6, in7,
	output [REGISTER_WIDTH-1:0] out0, out1, out2, out3, out4, out5, out6, out7
);
	iserdes_counter #(.BIT_DEPTH(BIT_DEPTH), .REGISTER_WIDTH(REGISTER_WIDTH)) c0 (.clock(clock), .reset(reset), .in(in0), .out(out0));
	iserdes_counter #(.BIT_DEPTH(BIT_DEPTH), .REGISTER_WIDTH(REGISTER_WIDTH)) c1 (.clock(clock), .reset(reset), .in(in1), .out(out1));
	iserdes_counter #(.BIT_DEPTH(BIT_DEPTH), .REGISTER_WIDTH(REGISTER_WIDTH)) c2 (.clock(clock), .reset(reset), .in(in2), .out(out2));
	iserdes_counter #(.BIT_DEPTH(BIT_DEPTH), .REGISTER_WIDTH(REGISTER_WIDTH)) c3 (.clock(clock), .reset(reset), .in(in3), .out(out3));
	iserdes_counter #(.BIT_DEPTH(BIT_DEPTH), .REGISTER_WIDTH(REGISTER_WIDTH)) c4 (.clock(clock), .reset(reset), .in(in4), .out(out4));
	iserdes_counter #(.BIT_DEPTH(BIT_DEPTH), .REGISTER_WIDTH(REGISTER_WIDTH)) c5 (.clock(clock), .reset(reset), .in(in5), .out(out5));
	iserdes_counter #(.BIT_DEPTH(BIT_DEPTH), .REGISTER_WIDTH(REGISTER_WIDTH)) c6 (.clock(clock), .reset(reset), .in(in6), .out(out6));
	iserdes_counter #(.BIT_DEPTH(BIT_DEPTH), .REGISTER_WIDTH(REGISTER_WIDTH)) c7 (.clock(clock), .reset(reset), .in(in7), .out(out7));
endmodule

// based on iserdes_counter
module iserdes_scaler #(
	parameter CLOCK_PERIODS_TO_ACCUMULATE = 25000,
	parameter LOG_BASE_2_OF_CLOCK_PERIODS_TO_ACCUMULATE = $clog2(CLOCK_PERIODS_TO_ACCUMULATE),
	parameter REGISTER_WIDTH = 8,
	parameter BIT_DEPTH = 8,
	parameter LOG_BASE_2_OF_BIT_DEPTH = $clog2(BIT_DEPTH)
) (
	input clock, reset,
	input [BIT_DEPTH-1:0] in,
	output reg [REGISTER_WIDTH-1:0] out = 0
);
	reg previous_bit = 0;
	wire [1:0] a = { previous_bit, in[7] };
	wire [1:0] b = in[7:6];
	wire [1:0] c = in[6:5];
	wire [1:0] d = in[5:4];
	wire [1:0] e = in[4:3];
	wire [1:0] f = in[3:2];
	wire [1:0] g = in[2:1];
	wire [1:0] h = in[1:0];
	wire [1:0] zo = 2'b01;
	wire [LOG_BASE_2_OF_BIT_DEPTH-1:0] current_count = (zo==a?1'b1:0) + (zo==b?1'b1:0) + (zo==c?1'b1:0) + (zo==d?1'b1:0) + (zo==e?1'b1:0) + (zo==f?1'b1:0) + (zo==g?1'b1:0) + (zo==h?1'b1:0);
	reg [LOG_BASE_2_OF_BIT_DEPTH-1:0] current_count_reg = 0;
	reg [LOG_BASE_2_OF_CLOCK_PERIODS_TO_ACCUMULATE:0] accumulation_counter = 0;
	reg [REGISTER_WIDTH-1:0] accumulator;
	always @(posedge clock) begin
		if (reset) begin
			out <= 0;
			accumulator <= 0;
			current_count_reg <= 0;
			previous_bit <= 0;
			accumulation_counter <= 0;
		end else begin
			if (accumulation_counter < CLOCK_PERIODS_TO_ACCUMULATE) begin
				accumulator <= accumulator + current_count_reg;
				current_count_reg <= current_count;
				accumulation_counter <= accumulation_counter + 1'b1;
			end else begin
				out <= accumulator;
				accumulator <= 0;
				current_count_reg <= 0;
				accumulation_counter <= 0;
			end
			previous_bit <= in[0];
		end
	end
endmodule

// based on iserdes_scaler
module iserdes_scaler_array8 #(
	parameter NUMBER_OF_CHANNELS = 8,
	parameter CLOCK_PERIODS_TO_ACCUMULATE = 25000,
	parameter LOG_BASE_2_OF_CLOCK_PERIODS_TO_ACCUMULATE = $clog2(CLOCK_PERIODS_TO_ACCUMULATE),
	parameter REGISTER_WIDTH = 8,
	parameter BIT_DEPTH = 8,
	parameter LOG_BASE_2_OF_BIT_DEPTH = $clog2(BIT_DEPTH)
) (
	input clock, reset,
	input [BIT_DEPTH-1:0] in0, in1, in2, in3, in4, in5, in6, in7,
	output [REGISTER_WIDTH-1:0] out0, out1, out2, out3, out4, out5, out6, out7
);
	genvar i;
	wire [BIT_DEPTH-1:0] in [NUMBER_OF_CHANNELS-1:0];
	assign in[0] = in0; assign in[1] = in1; assign in[2] = in2; assign in[3] = in3;
	assign in[4] = in4; assign in[5] = in5; assign in[6] = in6; assign in[7] = in7;
	reg [REGISTER_WIDTH-1:0] out [NUMBER_OF_CHANNELS-1:0];
	assign out0 = out[0]; assign out1 = out[1];  assign out2 = out[2];  assign out3 = out[3];
	assign out4 = out[4]; assign out5 = out[5];  assign out6 = out[6];  assign out7 = out[7];
	reg [NUMBER_OF_CHANNELS-1:0] previous_bit = 0;
	wire [1:0] a [NUMBER_OF_CHANNELS-1:0];
	wire [1:0] b [NUMBER_OF_CHANNELS-1:0];
	wire [1:0] c [NUMBER_OF_CHANNELS-1:0];
	wire [1:0] d [NUMBER_OF_CHANNELS-1:0];
	wire [1:0] e [NUMBER_OF_CHANNELS-1:0];
	wire [1:0] f [NUMBER_OF_CHANNELS-1:0];
	wire [1:0] g [NUMBER_OF_CHANNELS-1:0];
	wire [1:0] h [NUMBER_OF_CHANNELS-1:0];
	wire [1:0] zo = 2'b01;
	wire [LOG_BASE_2_OF_BIT_DEPTH-1:0] current_count [NUMBER_OF_CHANNELS-1:0];
	reg [LOG_BASE_2_OF_BIT_DEPTH-1:0] current_count_reg [NUMBER_OF_CHANNELS-1:0];
	reg [LOG_BASE_2_OF_CLOCK_PERIODS_TO_ACCUMULATE:0] accumulation_counter = 0;
	reg [REGISTER_WIDTH-1:0] accumulator [NUMBER_OF_CHANNELS-1:0];
	for (i=0; i<NUMBER_OF_CHANNELS; i=i+1) begin : scaler_array_mapping
		assign a[i] = { previous_bit[i], in[i][7] };
		assign b[i] = in[i][7:6];
		assign c[i] = in[i][6:5];
		assign d[i] = in[i][5:4];
		assign e[i] = in[i][4:3];
		assign f[i] = in[i][3:2];
		assign g[i] = in[i][2:1];
		assign h[i] = in[i][1:0];
		assign current_count[i] = (zo==a[i]?1'b1:1'b0) + (zo==b[i]?1'b1:1'b0) + (zo==c[i]?1'b1:1'b0) + (zo==d[i]?1'b1:1'b0) + (zo==e[i]?1'b1:1'b0) + (zo==f[i]?1'b1:1'b0) + (zo==g[i]?1'b1:1'b0) + (zo==h[i]?1'b1:1'b0);
		always @(posedge clock) begin
			if (reset) begin
				out[i] <= 0;
				accumulator[i] <= 0;
				current_count_reg[i] <= 0;
				previous_bit[i] <= 0;
				accumulation_counter <= 0;
			end else begin
				if (accumulation_counter < CLOCK_PERIODS_TO_ACCUMULATE) begin
					accumulator[i] <= accumulator[i] + current_count_reg[i];
					current_count_reg[i] <= current_count[i];
					accumulation_counter <= accumulation_counter + 1'b1;
				end else begin
					out[i] <= accumulator[i];
					accumulator[i] <= 0;
					current_count_reg[i] <= 0;
					accumulation_counter <= 0;
				end
				previous_bit[i] <= in[i][0];
			end
		end
	end
endmodule

// based on iserdes_scaler
// warning: goes from ch1 to ch12
module iserdes_scaler_array12 #(
	parameter NUMBER_OF_CHANNELS = 12,
	parameter CLOCK_PERIODS_TO_ACCUMULATE = 25000,
	parameter LOG_BASE_2_OF_CLOCK_PERIODS_TO_ACCUMULATE = $clog2(CLOCK_PERIODS_TO_ACCUMULATE),
	parameter REGISTER_WIDTH = 8,
	parameter BIT_DEPTH = 8,
	parameter LOG_BASE_2_OF_BIT_DEPTH = $clog2(BIT_DEPTH)
) (
	input clock, reset,
	input [BIT_DEPTH-1:0] in01, in02, in03, in04,
	input [BIT_DEPTH-1:0] in05, in06, in07, in08,
	input [BIT_DEPTH-1:0] in09, in10, in11, in12,
	output [REGISTER_WIDTH-1:0] out01, out02, out03, out04,
	output [REGISTER_WIDTH-1:0] out05, out06, out07, out08,
	output [REGISTER_WIDTH-1:0] out09, out10, out11, out12
);
	genvar i;
	wire [BIT_DEPTH-1:0] in [NUMBER_OF_CHANNELS:1];
	assign in[1] = in01; assign in[2]  = in02; assign in[3]  = in03; assign in[4]  = in04;
	assign in[5] = in05; assign in[6]  = in06; assign in[7]  = in07; assign in[8]  = in08;
	assign in[9] = in09; assign in[10] = in10; assign in[11] = in11; assign in[12] = in12;
	reg [REGISTER_WIDTH-1:0] out [NUMBER_OF_CHANNELS:1];
	assign out01 = out[1]; assign out02 = out[2];  assign out03 = out[3];  assign out04 = out[4];
	assign out05 = out[5]; assign out06 = out[6];  assign out07 = out[7];  assign out08 = out[8];
	assign out09 = out[9]; assign out10 = out[10]; assign out11 = out[11]; assign out12 = out[12];
	reg [NUMBER_OF_CHANNELS:1] previous_bit = 0;
	wire [1:0] a [NUMBER_OF_CHANNELS:1];
	wire [1:0] b [NUMBER_OF_CHANNELS:1];
	wire [1:0] c [NUMBER_OF_CHANNELS:1];
	wire [1:0] d [NUMBER_OF_CHANNELS:1];
	wire [1:0] e [NUMBER_OF_CHANNELS:1];
	wire [1:0] f [NUMBER_OF_CHANNELS:1];
	wire [1:0] g [NUMBER_OF_CHANNELS:1];
	wire [1:0] h [NUMBER_OF_CHANNELS:1];
	wire [1:0] zo = 2'b01;
	wire [LOG_BASE_2_OF_BIT_DEPTH-1:0] current_count [NUMBER_OF_CHANNELS:1];
	reg [LOG_BASE_2_OF_BIT_DEPTH-1:0] current_count_reg [NUMBER_OF_CHANNELS:1];
	reg [LOG_BASE_2_OF_CLOCK_PERIODS_TO_ACCUMULATE:0] accumulation_counter = 0;
	reg [REGISTER_WIDTH-1:0] accumulator [NUMBER_OF_CHANNELS:1];
	for (i=1; i<=NUMBER_OF_CHANNELS; i=i+1) begin : scaler_array_mapping
		assign a[i] = { previous_bit[i], in[i][7] };
		assign b[i] = in[i][7:6];
		assign c[i] = in[i][6:5];
		assign d[i] = in[i][5:4];
		assign e[i] = in[i][4:3];
		assign f[i] = in[i][3:2];
		assign g[i] = in[i][2:1];
		assign h[i] = in[i][1:0];
		assign current_count[i] = (zo==a[i]?1'b1:1'b0) + (zo==b[i]?1'b1:1'b0) + (zo==c[i]?1'b1:1'b0) + (zo==d[i]?1'b1:1'b0) + (zo==e[i]?1'b1:1'b0) + (zo==f[i]?1'b1:1'b0) + (zo==g[i]?1'b1:1'b0) + (zo==h[i]?1'b1:1'b0);
		always @(posedge clock) begin
			if (reset) begin
				out[i] <= 0;
				accumulator[i] <= 0;
				current_count_reg[i] <= 0;
				previous_bit[i] <= 0;
				accumulation_counter <= 0;
			end else begin
				if (accumulation_counter < CLOCK_PERIODS_TO_ACCUMULATE) begin
					accumulator[i] <= accumulator[i] + current_count_reg[i];
					current_count_reg[i] <= current_count[i];
					accumulation_counter <= accumulation_counter + 1'b1;
				end else begin
					out[i] <= accumulator[i];
					accumulator[i] <= 0;
					current_count_reg[i] <= 0;
					accumulation_counter <= 0;
				end
				previous_bit[i] <= in[i][0];
			end
		end
	end
endmodule

`ifndef SYNTHESIS
module iserdes_counter_scaler_tb ();
	localparam NUMBER_OF_CHANNELS = 12;
	genvar i;
	reg clock = 0;
	reg reset = 1;
	reg [7:0] iserdes_in_raw = 0;
	reg [7:0] iserdes_in_raw_array [NUMBER_OF_CHANNELS:1];
	reg [7:0] iserdes_in = 0;
	reg [7:0] iserdes_in_array [NUMBER_OF_CHANNELS:1];
	wire [31:0] channel_counter;
	wire [31:0] channel_scaler;
	wire [31:0] channel_scaler_array [NUMBER_OF_CHANNELS:1];
	iserdes_counter #(.BIT_DEPTH(8), .REGISTER_WIDTH(32)) counter (.clock(clock), .reset(reset), .in(iserdes_in), .out(channel_counter));
	iserdes_scaler #(.BIT_DEPTH(8), .REGISTER_WIDTH(32), .CLOCK_PERIODS_TO_ACCUMULATE(4)) scaler (.clock(clock), .reset(reset), .in(iserdes_in), .out(channel_scaler));
	iserdes_scaler_array12 #(.BIT_DEPTH(8), .REGISTER_WIDTH(32), .CLOCK_PERIODS_TO_ACCUMULATE(4), .NUMBER_OF_CHANNELS(NUMBER_OF_CHANNELS)) scaler12 (
		.clock(clock), .reset(reset),
		.in01(iserdes_in_array[1]), .in02(iserdes_in_array[2]), .in03(iserdes_in_array[3]), .in04(iserdes_in_array[4]),
		.in05(iserdes_in_array[5]), .in06(iserdes_in_array[6]), .in07(iserdes_in_array[7]), .in08(iserdes_in_array[8]),
		.in09(iserdes_in_array[9]), .in10(iserdes_in_array[10]), .in11(iserdes_in_array[11]), .in12(iserdes_in_array[12]),
		.out01(channel_scaler_array[1]), .out02(channel_scaler_array[2]),
		.out03(channel_scaler_array[3]), .out04(channel_scaler_array[4]),
		.out05(channel_scaler_array[5]), .out06(channel_scaler_array[6]),
		.out07(channel_scaler_array[7]), .out08(channel_scaler_array[8]),
		.out09(channel_scaler_array[9]), .out10(channel_scaler_array[10]),
		.out11(channel_scaler_array[11]), .out12(channel_scaler_array[12])
	);
//	for (i=3; i<=NUMBER_OF_CHANNELS; i=i+1) begin : another
//		assign iserdes_in_raw_array[i] = 0;
//	end
	initial begin
		iserdes_in_raw_array[1] <= 0;
		iserdes_in_raw_array[2] <= 0;
		reset = 1;
		#100;
		reset = 0;
		#100;
		iserdes_in_raw <= 8'b00111100;
		iserdes_in_raw_array[1] <= 8'b00111100;
		iserdes_in_raw_array[2] <= 8'b00111101;
		#20;
		iserdes_in_raw <= 8'b00000000;
		iserdes_in_raw_array[1] <= 8'b00000000;
		iserdes_in_raw_array[2] <= 8'b00000000;
		#20;
		iserdes_in_raw <= 8'b00000110;
		iserdes_in_raw_array[1] <= 8'b00000000;
		iserdes_in_raw_array[2] <= 8'b00000000;
		#20;
		iserdes_in_raw <= 8'b00000000;
		iserdes_in_raw_array[1] <= 8'b00000000;
		iserdes_in_raw_array[2] <= 8'b00000000;
		#20;
		iserdes_in_raw <= 8'b10000000;
		iserdes_in_raw_array[1] <= 8'b10000000;
		iserdes_in_raw_array[2] <= 8'b10000001;
		#20;
		iserdes_in_raw <= 8'b00000000;
		iserdes_in_raw_array[1] <= 8'b00000000;
		iserdes_in_raw_array[2] <= 8'b00000000;
		#20;
		iserdes_in_raw <= 8'b10101010;
		iserdes_in_raw_array[1] <= 8'b10101010;
		iserdes_in_raw_array[2] <= 8'b10101011;
		#20;
		iserdes_in_raw <= 8'b00000000;
		iserdes_in_raw_array[1] <= 8'b00000000;
		iserdes_in_raw_array[2] <= 8'b00000000;
		#20;
		iserdes_in_raw <= 8'b01010101;
		iserdes_in_raw_array[1] <= 8'b01010101;
		iserdes_in_raw_array[2] <= 8'b01010110;
		#20;
		iserdes_in_raw <= 8'b00000000;
		iserdes_in_raw_array[1] <= 8'b00000000;
		iserdes_in_raw_array[2] <= 8'b00000000;
	end
	always begin
		#10;
		clock <= 1;
		#10;
		clock <= 0;
	end
	for (i=1; i<=NUMBER_OF_CHANNELS; i=i+1) begin : blah
		always @(posedge clock) begin
			iserdes_in <= iserdes_in_raw;
			iserdes_in_array[i] <= iserdes_in_raw_array[i];
		end
	end
endmodule
`endif

`endif

