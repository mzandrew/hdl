`timescale 1ns / 1ps

// written 2025-11-07 by mza
// last updated 2026-01-13 by mza

`include "lib/generic.v"
`include "lib/debounce.v"
`include "lib/plldcm.v"
`include "lib/reset.v"

module protodune_LArPix_DAQ_laser_pulser #(
	parameter DESIRED_LASER_FREQUENCY_HZ = 20, // 10 Hz or 20 Hz
	parameter DESIRED_DELAY_INCREMENT_US = 1,
	parameter DESIRED_INITIAL_DELAY_FOR_LARPIX_TRIGGER_1_US = 176, // 0.5+175+0.07=175.57 us
	parameter DESIRED_INITIAL_DELAY_FOR_LARPIX_TRIGGER_2_US = 675, // 500+175+0.07=675.07 us
//	parameter DESIRED_INITIAL_DELAY_FOR_LARPIX_TRIGGER_3_US = 500 + DESIRED_INITIAL_DELAY_FOR_LARPIX_TRIGGER_2_US,
	parameter LASER_PULSE_LENGTH_US = 100,
	parameter SHORT_LASER_PULSE_LENGTH_NS = 200,
	parameter LARPIX_PULSE_LENGTH_NS = 200,
	parameter HOTNESS = 5,
	// - - - - - - - - - - - - - - - - - - - - - - - - - - -
	parameter RAW_OSCILLATOR_FREQUENCY_HZ = 100000000,
	parameter DIVIDE = 1,
	parameter OSCILLATOR_FREQUENCY_HZ = RAW_OSCILLATOR_FREQUENCY_HZ / DIVIDE,
	parameter DELAY_INCREMENT_COUNTS = OSCILLATOR_FREQUENCY_HZ / 1000 * DESIRED_DELAY_INCREMENT_US / 1000,
	parameter MAX_COUNT_FOR_LASER_TRIGGER = OSCILLATOR_FREQUENCY_HZ / DESIRED_LASER_FREQUENCY_HZ,
	parameter LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER = $clog2(MAX_COUNT_FOR_LASER_TRIGGER),
	parameter LASER_PULSE_LENGTH_COUNTS = OSCILLATOR_FREQUENCY_HZ / 1000 * LASER_PULSE_LENGTH_US / 1000,
	parameter SHORT_LASER_PULSE_LENGTH_COUNTS = OSCILLATOR_FREQUENCY_HZ / 1000 * SHORT_LASER_PULSE_LENGTH_NS / 1000000,
	parameter COUNT_FOR_LASER_TRIGGER_ON = MAX_COUNT_FOR_LASER_TRIGGER,
	parameter COUNT_FOR_LASER_TRIGGER_OFF = MAX_COUNT_FOR_LASER_TRIGGER - LASER_PULSE_LENGTH_COUNTS,
	parameter COUNT_FOR_SHORT_LASER_TRIGGER_OFF = MAX_COUNT_FOR_LASER_TRIGGER - SHORT_LASER_PULSE_LENGTH_COUNTS,
	parameter DELAY_COUNT_FOR_LARPIX_TRIGGER_1 = OSCILLATOR_FREQUENCY_HZ / 1000 * DESIRED_INITIAL_DELAY_FOR_LARPIX_TRIGGER_1_US / 1000,
	parameter DELAY_COUNT_FOR_LARPIX_TRIGGER_2 = OSCILLATOR_FREQUENCY_HZ / 1000 * DESIRED_INITIAL_DELAY_FOR_LARPIX_TRIGGER_2_US / 1000,
//	parameter DELAY_COUNT_FOR_LARPIX_TRIGGER_3 = OSCILLATOR_FREQUENCY_HZ / 1000 * DESIRED_INITIAL_DELAY_FOR_LARPIX_TRIGGER_3_US / 1000,
	parameter LARPIX_PULSE_LENGTH_COUNTS = OSCILLATOR_FREQUENCY_HZ / 1000 * LARPIX_PULSE_LENGTH_NS / 1000000,
	parameter INITIAL_COUNT_FOR_LARPIX_TRIGGER_1_ON = MAX_COUNT_FOR_LASER_TRIGGER - DELAY_COUNT_FOR_LARPIX_TRIGGER_1,
	parameter INITIAL_COUNT_FOR_LARPIX_TRIGGER_1_OFF = INITIAL_COUNT_FOR_LARPIX_TRIGGER_1_ON - LARPIX_PULSE_LENGTH_COUNTS,
	parameter INITIAL_COUNT_FOR_LARPIX_TRIGGER_2_ON = MAX_COUNT_FOR_LASER_TRIGGER - DELAY_COUNT_FOR_LARPIX_TRIGGER_2,
	parameter INITIAL_COUNT_FOR_LARPIX_TRIGGER_2_OFF = INITIAL_COUNT_FOR_LARPIX_TRIGGER_2_ON - LARPIX_PULSE_LENGTH_COUNTS,
//	parameter INITIAL_COUNT_FOR_LARPIX_TRIGGER_3_ON = MAX_COUNT_FOR_LASER_TRIGGER - DELAY_COUNT_FOR_LARPIX_TRIGGER_3,
//	parameter INITIAL_COUNT_FOR_LARPIX_TRIGGER_3_OFF = INITIAL_COUNT_FOR_LARPIX_TRIGGER_3_ON - LARPIX_PULSE_LENGTH_COUNTS,
	parameter SIMULATION = 0,
	parameter COUNTER100_BIT_PICKOFF = SIMULATION ? 5 : 23
) (
	input clock100_p, clock100_n,
	input reset,
	input [3:1] pmod,
	output [5:0] coax,
	input [3:0] rot,
	output [7:0] led
);
	wire clock100, rawclock, clock10, reset10, pll_locked;
	IBUFGDS clk (.I(clock100_p), .IB(clock100_n), .O(clock100));
	simplepll_BASE #(.OVERALL_DIVIDE(1), .MULTIPLY(4), .DIVIDE0(4*DIVIDE), .PHASE0(0.0), .PERIOD(10.0)) other (.clockin(clock100), .reset(reset), .clock0out(rawclock), .locked(pll_locked)); // *4 then /4 just to keep the Vco happy
	BUFG vampire (.I(rawclock), .O(clock10));
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset_wait4pll (.reset_input(reset), .pll_locked_input(pll_locked), .clock_input(clock10), .reset_output(reset10));
	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] counter = MAX_COUNT_FOR_LASER_TRIGGER;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] laser_counter_on  = COUNT_FOR_LASER_TRIGGER_ON;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] laser_counter_off = COUNT_FOR_LASER_TRIGGER_OFF;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] short_laser_counter_off = COUNT_FOR_SHORT_LASER_TRIGGER_OFF;
	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_1_on  = INITIAL_COUNT_FOR_LARPIX_TRIGGER_1_ON;
	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_1_off = INITIAL_COUNT_FOR_LARPIX_TRIGGER_1_OFF;
	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_2_on  = INITIAL_COUNT_FOR_LARPIX_TRIGGER_2_ON;
	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_2_off = INITIAL_COUNT_FOR_LARPIX_TRIGGER_2_OFF;
//	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_3_on  = INITIAL_COUNT_FOR_LARPIX_TRIGGER_3_ON;
//	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_3_off = INITIAL_COUNT_FOR_LARPIX_TRIGGER_3_OFF;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] delay_increment = DELAY_INCREMENT_COUNTS;
	reg [7:0] trigger_counter = 0;
	reg trigger_laser = 0, short_trigger_laser = 0;
	reg trigger_larpix_1 = 0, trigger_larpix_2 = 0, trigger_larpix_3 = 0;
	reg [3:0] buffered_rot = 0;
	wire A, B, pushbutton;
	debounce #(.CLOCK_FREQUENCY(OSCILLATOR_FREQUENCY_HZ), .TIMEOUT_IN_MILLISECONDS(10)) A_debounce (.clock(clock10), .raw_button_input(pmod[2]), .polarity(1'b1), .button_activated_pulse(), .button_deactivated_pulse(), .button_active(A));
	debounce #(.CLOCK_FREQUENCY(OSCILLATOR_FREQUENCY_HZ), .TIMEOUT_IN_MILLISECONDS(10)) B_debounce (.clock(clock10), .raw_button_input(pmod[1]), .polarity(1'b1), .button_activated_pulse(), .button_deactivated_pulse(), .button_active(B));
	debounce #(.CLOCK_FREQUENCY(OSCILLATOR_FREQUENCY_HZ), .TIMEOUT_IN_MILLISECONDS(10)) PB_debounce (.clock(clock10), .raw_button_input(pmod[3]), .polarity(1'b1), .button_activated_pulse(), .button_deactivated_pulse(), .button_active(pushbutton));
	wire i, d;
	wire [4:0] current_value;
	quadrature_decode #(.POLARITY(1'b1), .PULSES_PER_REVOLUTION(20)) qd (.clock(clock10), .reset(reset10), .A(A), .B(B), .increment(i), .decrement(d), .current_value(current_value));
	reg [HOTNESS-1:0] one_hot = { {HOTNESS-1{1'b0}}, 1'b1 };
	always @(posedge clock10) begin
		larpix_counter_2_on  <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_2_ON  - delay_increment * buffered_rot;
		larpix_counter_2_off <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_2_OFF - delay_increment * buffered_rot;
//		larpix_counter_3_on  <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_3_ON  - delay_increment * buffered_rot;
//		larpix_counter_3_off <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_3_OFF - delay_increment * buffered_rot;
		if (reset10) begin
			buffered_rot <= 0;
			counter <= MAX_COUNT_FOR_LASER_TRIGGER;
			larpix_counter_1_on  <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_1_ON;
			larpix_counter_1_off <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_1_OFF;
			trigger_counter <= 0;
			one_hot <= { {HOTNESS-1{1'b0}}, 1'b1 };
		end else begin
			buffered_rot <= ~rot;
			if (0<counter) begin
				counter <= counter - 1'b1;
				if (counter==larpix_counter_1_on)  begin trigger_larpix_1 <= 1; end
				if (counter==larpix_counter_1_off) begin trigger_larpix_1 <= 0; end
				if (counter==larpix_counter_2_on)  begin trigger_larpix_2 <= 1; end
				if (counter==larpix_counter_2_off) begin trigger_larpix_2 <= 0; end
//				if (counter==larpix_counter_3_on)  begin trigger_larpix_3 <= 1; end
//				if (counter==larpix_counter_3_off) begin trigger_larpix_3 <= 0; end
				if (counter==laser_counter_on)  begin trigger_laser <= 1; short_trigger_laser <= 1; end
				if (counter==laser_counter_off) begin trigger_laser <= 0; end
				if (counter==short_laser_counter_off) begin short_trigger_laser <= 0; end
			end else begin
				counter <= MAX_COUNT_FOR_LASER_TRIGGER;
				trigger_counter <= trigger_counter + 1'b1;
				one_hot <= { one_hot[HOTNESS-2:0], one_hot[HOTNESS-1] };
			end
			if (i) begin
				larpix_counter_1_on  <= larpix_counter_1_on  - delay_increment;
				larpix_counter_1_off <= larpix_counter_1_off - delay_increment;
			end
			if (d) begin
				larpix_counter_1_on  <= larpix_counter_1_on  + delay_increment;
				larpix_counter_1_off <= larpix_counter_1_off + delay_increment;
			end
			if (pushbutton) begin
				larpix_counter_1_on  <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_1_ON;
				larpix_counter_1_off <= INITIAL_COUNT_FOR_LARPIX_TRIGGER_1_OFF;
			end
		end
	end
//	assign led = trigger_counter;
//	assign led = current_value;
	assign led = { 4'd0, buffered_rot };
	assign coax[3] = trigger_laser; // leftmost connector
	assign coax[2] = short_trigger_laser;
	assign coax[1] = trigger_larpix_1;
	wire occasional_trigger_larpix_2 = one_hot[0] & trigger_larpix_2;
	wire trigger_larpix = trigger_larpix_1 || occasional_trigger_larpix_2;
	assign coax[0] = trigger_larpix; // rightmost connector
	assign coax[5:4] = 0;
	initial begin
		#10;
		$display("delay increment: %d", DELAY_INCREMENT_COUNTS);
		#10;
		$display("delay increment: %d", delay_increment);
	end
endmodule

module protodune_LArPix_DAQ_laser_pulser_tb;
	reg clock = 0, clock_p = 0, clock_n = 1'b1;
	reg reset = 1'b1;
	always begin
		#5; clock <= ~clock;
		clock_p = clock;
		clock_n = ~clock;
	end
	initial begin
		#20;
		reset <= 0;
		#20;
		#1000000;
		$finish;
	end
	wire [5:0] coax;
	protodune_LArPix_DAQ_laser_pulser #(.SIMULATION(1), .DESIRED_LASER_FREQUENCY_HZ(1000)) tubbs (.clock100_p(clock_p), .clock100_n(clock_n), .reset(reset), .coax(coax), .led(), .rot(4'b0), .pmod(8'b0));
endmodule

