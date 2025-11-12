`timescale 1ns / 1ps

// written 2025-11-07 by mza
// last updated 2025-11-12 by mza

`include "lib/generic.v"
`include "lib/debounce.v"

module protodune_LArPix_DAQ_laser_pulser #(
	parameter DESIRED_LASER_FREQUENCY_HZ = 10,
	parameter DESIRED_DELAY_INCREMENT_US = 100,
	parameter DESIRED_DELAY_FOR_LARPIX_TRIGGER_1_US = 1000,
	parameter DESIRED_DELAY_FOR_LARPIX_TRIGGER_2_US = 1000,
	// - - - - - - - - - - - - - - - - - - - - - - - - - - -
	parameter OSCILLATOR_FREQUENCY_HZ = 100000000,
	parameter DELAY_INCREMENT_COUNTS = OSCILLATOR_FREQUENCY_HZ / 1000 * DESIRED_DELAY_INCREMENT_US / 1000,
	parameter MAX_COUNT_FOR_LASER_TRIGGER = OSCILLATOR_FREQUENCY_HZ / DESIRED_LASER_FREQUENCY_HZ,
	parameter LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER = $clog2(MAX_COUNT_FOR_LASER_TRIGGER),
	parameter DELAY_COUNT_FOR_LARPIX_TRIGGER_1 = OSCILLATOR_FREQUENCY_HZ / 1000 * DESIRED_DELAY_FOR_LARPIX_TRIGGER_1_US / 1000,
	parameter DELAY_COUNT_FOR_LARPIX_TRIGGER_2 = OSCILLATOR_FREQUENCY_HZ / 1000 * DESIRED_DELAY_FOR_LARPIX_TRIGGER_2_US / 1000,
	parameter INITIAL_COUNT_FOR_LARPIX_TRIGGER_1 = MAX_COUNT_FOR_LASER_TRIGGER - DELAY_COUNT_FOR_LARPIX_TRIGGER_1,
	parameter INITIAL_COUNT_FOR_LARPIX_TRIGGER_2 = INITIAL_COUNT_FOR_LARPIX_TRIGGER_1 - DELAY_COUNT_FOR_LARPIX_TRIGGER_2
) (
	input clock100_p, clock100_n,
	input reset,
	input [3:1] pmod,
	output [5:0] coax,
	output [7:0] led
);
	wire clock;
	IBUFGDS clk (.I(clock100_p), .IB(clock100_n), .O(clock));
	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] counter = MAX_COUNT_FOR_LASER_TRIGGER;
	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_1 = INITIAL_COUNT_FOR_LARPIX_TRIGGER_1;
	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_2 = INITIAL_COUNT_FOR_LARPIX_TRIGGER_2;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] delay_increment = DELAY_INCREMENT_COUNTS;
	reg [7:0] trigger_counter = 0;
	reg trigger_laser = 0;
	reg trigger_larpix_1 = 0;
	reg trigger_larpix_2 = 0;
	wire A, B;
	debounce #(.CLOCK_FREQUENCY(OSCILLATOR_FREQUENCY_HZ), .TIMEOUT_IN_MILLISECONDS(10)) A_debounce (.clock(clock), .raw_button_input(pmod[2]), .polarity(1'b1), .button_activated_pulse(), .button_deactivated_pulse(), .button_active(A));
	debounce #(.CLOCK_FREQUENCY(OSCILLATOR_FREQUENCY_HZ), .TIMEOUT_IN_MILLISECONDS(10)) B_debounce (.clock(clock), .raw_button_input(pmod[1]), .polarity(1'b1), .button_activated_pulse(), .button_deactivated_pulse(), .button_active(B));
	wire i, d;
	wire [4:0] current_value;
	quadrature_decode #(.POLARITY(1'b0), .PULSES_PER_REVOLUTION(20)) qd (.clock(clock), .reset(reset), .A(A), .B(B), .increment(i), .decrement(d), .current_value(current_value));
	always @(posedge clock) begin
		trigger_laser <= 0;
		trigger_larpix_1 <= 0;
		trigger_larpix_2 <= 0;
		if (reset) begin
			counter <= MAX_COUNT_FOR_LASER_TRIGGER;
			larpix_counter_1 <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_1;
			larpix_counter_2 <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_2;
			trigger_counter <= 0;
		end else begin
			if (0<counter) begin
				counter <= counter - 1'b1;
				if (counter==larpix_counter_1) begin
					trigger_larpix_1 <= 1;
				end
				if (counter==larpix_counter_2) begin
					trigger_larpix_2 <= 1;
				end
			end else begin
				counter <= MAX_COUNT_FOR_LASER_TRIGGER;
				trigger_counter <= trigger_counter + 1'b1;
				trigger_laser <= 1;
			end
			if (i) begin
				larpix_counter_1 <= larpix_counter_1 - delay_increment;
			end
			if (d) begin
				larpix_counter_1 <= larpix_counter_1 + delay_increment;
			end
		end
	end
//	assign led = trigger_counter;
	assign led = current_value;
	assign coax[3] = trigger_laser;
	assign coax[2] = trigger_laser;
	assign coax[1] = trigger_larpix_1;
	assign coax[0] = trigger_larpix_2;
	assign coax[5:4] = 0;
	initial begin
		#10;
		$display("delay increment: %d", DELAY_INCREMENT_COUNTS);
		#10;
		$display("delay increment: %d", delay_increment);
	end
endmodule

