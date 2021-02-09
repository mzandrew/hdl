// written 2020-05-29 by mza
// based on mza-test014.duration-timer.uart.v
// and mza-test022.frequency-counter.uart.v
// updated 2020-05-30 by mza
// last updated 2021-02-09 by mza

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
module clock #(
	parameter FREQUENCY_OF_CLOCK_HZ = 10000000.0,
	parameter PERIOD_OF_CLOCK_NS = 1000000000.0/FREQUENCY_OF_CLOCK_HZ,
	parameter HALF_PERIOD_OF_CLOCK_NS = PERIOD_OF_CLOCK_NS / 2.0
) (
	output reg clock = 0
);
	initial begin
		$display("creating clock with half period of %f ns", HALF_PERIOD_OF_CLOCK_NS);
	end
	always begin
		#HALF_PERIOD_OF_CLOCK_NS;
		clock = ~clock;
	end
endmodule

`include "lib/generic.v"

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

`endif

