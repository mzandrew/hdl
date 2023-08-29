// written 2020-05-29 by mza
// based on mza-test014.duration-timer.uart.v
// and mza-test022.frequency-counter.uart.v
// updated 2020-05-30 by mza
// last updated 2023-08-29 by mza

`ifndef FREQUENCY_COUNTER_LIB
`define FREQUENCY_COUNTER_LIB
`timescale 1ns / 1ps

module frequency_counter #(
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
	output [31:0] frequency_of_unknown_clock,
	output reg valid = 0
);
	localparam MSB_OF_COUNTERS = LOG2_OF_DIVIDE_RATIO + 8; // 35
	localparam MSB_OF_ACCUMULATOR = LOG2_OF_MAXIMUM_EXPECTED_FREQUENCY + LOG2_OF_FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ + 3; // ~63
	localparam MSB_OF_RESULT = MSB_OF_ACCUMULATOR - LOG2_OF_DIVIDE_RATIO; // ~35
	reg [MSB_OF_ACCUMULATOR:0] accumulator = 0;
	reg [MSB_OF_ACCUMULATOR:0] previous_accumulator = 0;
	reg [LOG2_OF_DIVIDE_RATIO:0] reference_clock_counter = 0;
	wire trigger_active = reference_clock_counter[LOG2_OF_DIVIDE_RATIO];
	reg valid__unknown = 0;
	reg [4:0] valid__pipeline_reference = 0;
	always @(posedge reference_clock) begin
		reference_clock_counter <= reference_clock_counter + 1'b1;
		valid <= 0;
		if (valid__pipeline_reference[3:2]==2'b01) begin
			valid <= 1;
		end
		valid__pipeline_reference <= { valid__pipeline_reference[2:0], valid__unknown };
	end
	reg [3:0] trigger_stream = 0;
	always @(posedge unknown_clock) begin
		trigger_stream <= { trigger_stream[2:0], trigger_active };
	end
	always @(posedge unknown_clock) begin
		if (trigger_stream[2]) begin
			valid__unknown <= 0;
			accumulator <= accumulator + FREQUENCY_OF_REFERENCE_CLOCK_IN_N_HZ;
		end else if (trigger_stream[3:2]==2'b10) begin
			previous_accumulator <= accumulator;
			accumulator <= 0;
			valid__unknown <= 1;
		end
	end
	assign frequency_of_unknown_clock = previous_accumulator[MSB_OF_ACCUMULATOR:LOG2_OF_DIVIDE_RATIO];
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
	wire [LOG_BASE_2_OF_BIT_DEPTH:0] current_count = (zo==a?1'b1:0) + (zo==b?1'b1:0) + (zo==c?1'b1:0) + (zo==d?1'b1:0) + (zo==e?1'b1:0) + (zo==f?1'b1:0) + (zo==g?1'b1:0) + (zo==h?1'b1:0);
	reg [LOG_BASE_2_OF_BIT_DEPTH:0] current_count_reg = 0;
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
	wire [LOG_BASE_2_OF_BIT_DEPTH:0] current_count = (zo==a?1'b1:0) + (zo==b?1'b1:0) + (zo==c?1'b1:0) + (zo==d?1'b1:0) + (zo==e?1'b1:0) + (zo==f?1'b1:0) + (zo==g?1'b1:0) + (zo==h?1'b1:0);
	reg [LOG_BASE_2_OF_BIT_DEPTH:0] current_count_reg = 0;
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


`ifndef SYNTHESIS
module iserdes_counter_scaler_tb ();
	reg clock = 0;
	reg reset = 1;
	reg [7:0] iserdes_in_raw = 0;
	reg [7:0] iserdes_in = 0;
	wire [31:0] channel_counter;
	wire [31:0] channel_scaler;
	iserdes_counter #(.BIT_DEPTH(8), .REGISTER_WIDTH(32)) counter (.clock(clock), .reset(reset), .in(iserdes_in), .out(channel_counter));
	iserdes_scaler #(.BIT_DEPTH(8), .REGISTER_WIDTH(32), .CLOCK_PERIODS_TO_ACCUMULATE(4)) scaler (.clock(clock), .reset(reset), .in(iserdes_in), .out(channel_scaler));
	initial begin
		reset = 1;
		#100;
		reset = 0;
		#100;
		iserdes_in_raw <= 8'b00111100;
		#20;
		iserdes_in_raw <= 8'b00000000;
		#20;
		iserdes_in_raw <= 8'b00000110;
		#20;
		iserdes_in_raw <= 8'b00000000;
		#20;
		iserdes_in_raw <= 8'b10000000;
		#20;
		iserdes_in_raw <= 8'b00000000;
		#20;
		iserdes_in_raw <= 8'b10101010;
		#20;
		iserdes_in_raw <= 8'b00000000;
		#20;
		iserdes_in_raw <= 8'b01010101;
		#20;
		iserdes_in_raw <= 8'b00000000;
	end
	always begin
		#10;
		clock <= 1;
		#10;
		clock <= 0;
	end
	always @(posedge clock) begin
		iserdes_in <= iserdes_in_raw;
	end
endmodule
`endif

`endif

