`timescale 1ns / 1ps

// written 2025-11-07 by mza
// last updated 2026-02-10 by mza

`include "lib/generic.v"
`include "lib/debounce.v"
`include "lib/plldcm.v"
`include "lib/reset.v"

module protodune_LArPix_DAQ_laser_pulser #(
	parameter SIMULATION = 0,
	parameter DESIRED_LASER_FREQUENCY_HZ = 20, // 20 Hz
	parameter LASER_PULSE_LENGTH_US  = 100, // 100 us
	parameter SYNC_LENGTH_NS         = 200, // 200 ns
	parameter DINKY_LENGTH_NS        = 200, // 200 ns
	parameter LARPIX_PULSE_LENGTH_NS = 200, // 200 ns
	parameter DESIRED_DELAY_FOR_SYNC_SIGNAL_NS      =   675000, // 675 us after start of laser signal
	parameter DESIRED_DELAY_FOR_DINKY_SIGNAL_NS     =      750 +                  DESIRED_DELAY_FOR_SYNC_SIGNAL_NS, // 750 ns after beginning of sync
	parameter DESIRED_DELAY_FOR_LARPIX_TRIGGER_1_NS =   500000 + SYNC_LENGTH_NS + DESIRED_DELAY_FOR_SYNC_SIGNAL_NS, // 500 us after end of sync
	parameter DESIRED_DELAY_FOR_LARPIX_TRIGGER_2_NS =  1000000 + SYNC_LENGTH_NS + DESIRED_DELAY_FOR_SYNC_SIGNAL_NS, // 1000 us after end of sync
	parameter DESIRED_DELAY_FOR_LARPIX_TRIGGER_3_NS = 25000000 + SYNC_LENGTH_NS + DESIRED_DELAY_FOR_SYNC_SIGNAL_NS, // 25 ms after end of sync
	parameter OCCASIONALNESS_A = 4,
	parameter OCCASIONALNESS_B = 3,
	// - - - - - - - - - - - - - - - - - - - - - - - - - - -
	parameter RAW_OSCILLATOR_FREQUENCY_HZ = 100000000, // 100 MHz
	parameter DIVIDE = 1,
	parameter CLOCK_FREQUENCY_HZ = RAW_OSCILLATOR_FREQUENCY_HZ / DIVIDE, // 100000000
	parameter MAX_COUNT_FOR_LASER_TRIGGER = CLOCK_FREQUENCY_HZ / DESIRED_LASER_FREQUENCY_HZ, // 5000000
	parameter LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER = $clog2(MAX_COUNT_FOR_LASER_TRIGGER), // 23
	parameter COUNT_FOR_LASER_TRIGGER_ON  = MAX_COUNT_FOR_LASER_TRIGGER,
	parameter COUNT_FOR_LASER_TRIGGER_OFF = MAX_COUNT_FOR_LASER_TRIGGER - CLOCK_FREQUENCY_HZ / 1000 * LASER_PULSE_LENGTH_US / 1000,
	parameter COUNT_FOR_SYNC_ON  = MAX_COUNT_FOR_LASER_TRIGGER - CLOCK_FREQUENCY_HZ / 1000000 * DESIRED_DELAY_FOR_SYNC_SIGNAL_NS / 1000,
	parameter COUNT_FOR_SYNC_OFF = COUNT_FOR_SYNC_ON - CLOCK_FREQUENCY_HZ / 1000 * SYNC_LENGTH_NS / 1000000,
	parameter COUNT_FOR_DINKY_ON  = MAX_COUNT_FOR_LASER_TRIGGER - CLOCK_FREQUENCY_HZ / 1000000 * DESIRED_DELAY_FOR_DINKY_SIGNAL_NS / 1000,
	parameter COUNT_FOR_DINKY_OFF = COUNT_FOR_DINKY_ON - CLOCK_FREQUENCY_HZ / 1000 * DINKY_LENGTH_NS / 1000000,
	parameter LARPIX_PULSE_LENGTH_COUNTS = CLOCK_FREQUENCY_HZ / 1000 * LARPIX_PULSE_LENGTH_NS / 1000000,
	parameter COUNT_FOR_LARPIX_TRIGGER_1_ON = MAX_COUNT_FOR_LASER_TRIGGER - CLOCK_FREQUENCY_HZ / 1000000 * DESIRED_DELAY_FOR_LARPIX_TRIGGER_1_NS / 1000,
	parameter COUNT_FOR_LARPIX_TRIGGER_1_OFF = COUNT_FOR_LARPIX_TRIGGER_1_ON - LARPIX_PULSE_LENGTH_COUNTS,
	parameter COUNT_FOR_LARPIX_TRIGGER_2_ON = MAX_COUNT_FOR_LASER_TRIGGER - CLOCK_FREQUENCY_HZ / 1000000 * DESIRED_DELAY_FOR_LARPIX_TRIGGER_2_NS / 1000,
	parameter COUNT_FOR_LARPIX_TRIGGER_2_OFF = COUNT_FOR_LARPIX_TRIGGER_2_ON - LARPIX_PULSE_LENGTH_COUNTS,
	parameter COUNT_FOR_LARPIX_TRIGGER_3_ON = MAX_COUNT_FOR_LASER_TRIGGER - CLOCK_FREQUENCY_HZ / 10000000 * DESIRED_DELAY_FOR_LARPIX_TRIGGER_3_NS / 100,
	parameter COUNT_FOR_LARPIX_TRIGGER_3_OFF = COUNT_FOR_LARPIX_TRIGGER_3_ON - LARPIX_PULSE_LENGTH_COUNTS,
	parameter COUNTER100_BIT_PICKOFF = SIMULATION ? 5 : 23
) (
	input clock100_p, clock100_n,
	input button,
	input [7:0] pmod,
	output [5:0] coax,
	input [3:0] rot,
	output [7:0] led
);
	wire clock100, rawclock, clock, reset, pll_locked;
	IBUFGDS clk (.I(clock100_p), .IB(clock100_n), .O(clock100));
	simplepll_BASE #(.OVERALL_DIVIDE(1), .MULTIPLY(4), .DIVIDE0(4*DIVIDE), .PHASE0(0.0), .PERIOD(10.0)) other (.clockin(clock100), .reset(~button), .clock0out(rawclock), .clock1out(), .clock2out(), .clock3out(), .clock4out(), .clock5out(), .locked(pll_locked)); // *4 then /4 just to keep the Vco happy
	BUFG vampire (.I(rawclock), .O(clock));
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset_wait4pll (.reset_input(~button), .pll_locked_input(pll_locked), .clock_input(clock), .reset_output(reset));
	reg [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] counter = MAX_COUNT_FOR_LASER_TRIGGER;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] laser_counter_on  = COUNT_FOR_LASER_TRIGGER_ON;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] laser_counter_off = COUNT_FOR_LASER_TRIGGER_OFF;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] sync_counter_on  = COUNT_FOR_SYNC_ON;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] sync_counter_off = COUNT_FOR_SYNC_OFF;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] dinky_counter_on  = COUNT_FOR_DINKY_ON;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] dinky_counter_off = COUNT_FOR_DINKY_OFF;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_1_on  = COUNT_FOR_LARPIX_TRIGGER_1_ON;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_1_off = COUNT_FOR_LARPIX_TRIGGER_1_OFF;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_2_on  = COUNT_FOR_LARPIX_TRIGGER_2_ON;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_2_off = COUNT_FOR_LARPIX_TRIGGER_2_OFF;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_3_on  = COUNT_FOR_LARPIX_TRIGGER_3_ON;
	wire [LOG2_OF_MAX_COUNT_FOR_LASER_TRIGGER:0] larpix_counter_3_off = COUNT_FOR_LARPIX_TRIGGER_3_OFF;
	reg [7:0] trigger_counter = 0;
	reg trigger_laser = 0, sync = 0, dinky = 0;
	reg trigger_larpix_1 = 0, trigger_larpix_2 = 0, trigger_larpix_3 = 0;
	reg occasional_larpix_a = 0, occasional_larpix_b = 0;
//	reg [3:0] buffered_rot = 0;
//	wire A, B, pushbutton;
//	debounce #(.CLOCK_FREQUENCY(CLOCK_FREQUENCY_HZ), .TIMEOUT_IN_MILLISECONDS(10)) A_debounce (.clock(clock), .raw_button_input(pmod[2]), .polarity(1'b1), .button_activated_pulse(), .button_deactivated_pulse(), .button_active(A));
//	debounce #(.CLOCK_FREQUENCY(CLOCK_FREQUENCY_HZ), .TIMEOUT_IN_MILLISECONDS(10)) B_debounce (.clock(clock), .raw_button_input(pmod[1]), .polarity(1'b1), .button_activated_pulse(), .button_deactivated_pulse(), .button_active(B));
//	debounce #(.CLOCK_FREQUENCY(CLOCK_FREQUENCY_HZ), .TIMEOUT_IN_MILLISECONDS(10)) PB_debounce (.clock(clock), .raw_button_input(pmod[3]), .polarity(1'b1), .button_activated_pulse(), .button_deactivated_pulse(), .button_active(pushbutton));
//	wire i, d;
//	wire [4:0] current_value;
//	quadrature_decode #(.POLARITY(1'b1), .PULSES_PER_REVOLUTION(20)) qd (.clock(clock), .reset(reset), .A(A), .B(B), .increment(i), .decrement(d), .current_value(current_value));
	reg [OCCASIONALNESS_A-1:0] one_hot_A = { {OCCASIONALNESS_A-1{1'b0}}, 1'b1 };
	reg [OCCASIONALNESS_B-1:0] one_hot_B = { {OCCASIONALNESS_B-1{1'b0}}, 1'b1 };
	always @(posedge clock) begin
		if (reset) begin
//			buffered_rot <= 0;
			counter <= MAX_COUNT_FOR_LASER_TRIGGER;
			trigger_counter <= 0;
			one_hot_A <= { {OCCASIONALNESS_A-1{1'b0}}, 1'b1 };
			one_hot_B <= { {OCCASIONALNESS_B-1{1'b0}}, 1'b1 };
		end else begin
//			buffered_rot <= ~rot;
			if (0<counter) begin
				counter <= counter - 1'b1;
				if (counter==laser_counter_on)  begin trigger_laser <= 1; end
				if (counter==laser_counter_off) begin trigger_laser <= 0; end
				if (counter==sync_counter_on)  begin sync <= 1; end
				if (counter==sync_counter_off) begin sync <= 0; end
				if (counter==dinky_counter_on)  begin dinky <= 1; end
				if (counter==dinky_counter_off) begin dinky <= 0; end
				if (counter==larpix_counter_1_on)  begin trigger_larpix_1 <= 1; end
				if (counter==larpix_counter_1_off) begin trigger_larpix_1 <= 0; end
				if (counter==larpix_counter_2_on)  begin trigger_larpix_2 <= 1; end
				if (counter==larpix_counter_2_off) begin trigger_larpix_2 <= 0; end
				if (counter==larpix_counter_3_on)  begin trigger_larpix_3 <= 1; end
				if (counter==larpix_counter_3_off) begin trigger_larpix_3 <= 0; end
			end else begin
				counter <= MAX_COUNT_FOR_LASER_TRIGGER;
				trigger_counter <= trigger_counter + 1'b1;
				one_hot_A <= { one_hot_A[OCCASIONALNESS_A-2:0], one_hot_A[OCCASIONALNESS_A-1] };
				one_hot_B <= { one_hot_B[OCCASIONALNESS_B-2:0], one_hot_B[OCCASIONALNESS_B-1] };
			end
		end
	end
	assign led = trigger_counter;
//	assign led = current_value;
//	assign led = { 4'd0, buffered_rot };
	wire occasional_trigger_larpix_2 = one_hot_A[0] & trigger_larpix_2;
	assign coax[5] = sync; // left sma connector
	assign coax[4] = trigger_laser; // right sma connector
	assign coax[3] = dinky; // leftmost lemo connector
	assign coax[2] = sync || trigger_larpix_3;
	assign coax[1] = sync || trigger_larpix_1 || occasional_trigger_larpix_2;
	assign coax[0] = one_hot_B[0] & (sync || trigger_larpix_1 || trigger_larpix_2); // rightmost lemo connector
	initial begin
		#10;
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

