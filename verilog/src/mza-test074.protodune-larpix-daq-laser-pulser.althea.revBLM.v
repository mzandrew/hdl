`timescale 1ns / 1ps

// written 2025-11-07 by mza
// last updated 2025-11-12 by mza

module protodune_LArPix_DAQ_laser_pulser (
	input clock100_p, clock100_n,
	input reset,
	output [5:0] coax,
	output [7:0] led
);
	wire clock;
	IBUFGDS clk (.I(clock100_p), .IB(clock100_n), .O(clock));
	// - - - - - - - - - - - - - - - - - - - - - - - - - - -
	localparam DESIRED_LASER_FREQUENCY_HZ = 10;
	localparam DESIRED_DELAY_FOR_LARPIX_TRIGGER_1_US = 1000;
	localparam DESIRED_DELAY_FOR_LARPIX_TRIGGER_2_US = 1000;
	// - - - - - - - - - - - - - - - - - - - - - - - - - - -
	localparam OSCILLATOR_FREQUENCY_HZ = 100000000;
	localparam MAX_COUNT_FOR_LASER_TRIGGER = OSCILLATOR_FREQUENCY_HZ / DESIRED_LASER_FREQUENCY_HZ;
	localparam DELAY_COUNT_FOR_LARPIX_TRIGGER_1 = OSCILLATOR_FREQUENCY_HZ / 1000 * DESIRED_DELAY_FOR_LARPIX_TRIGGER_1_US / 1000;
	localparam DELAY_COUNT_FOR_LARPIX_TRIGGER_2 = OSCILLATOR_FREQUENCY_HZ / 1000 * DESIRED_DELAY_FOR_LARPIX_TRIGGER_2_US / 1000;
	localparam COUNT_FOR_LARPIX_TRIGGER_1 = MAX_COUNT_FOR_LASER_TRIGGER - DELAY_COUNT_FOR_LARPIX_TRIGGER_1;
	localparam COUNT_FOR_LARPIX_TRIGGER_2 = COUNT_FOR_LARPIX_TRIGGER_1 - DELAY_COUNT_FOR_LARPIX_TRIGGER_2;
	reg [31:0] counter = MAX_COUNT_FOR_LASER_TRIGGER;
	reg [7:0] trigger_counter = 0;
	reg trigger_laser = 0;
	reg trigger_larpix_1 = 0;
	reg trigger_larpix_2 = 0;
	always @(posedge clock) begin
		trigger_laser <= 0;
		trigger_larpix_1 <= 0;
		trigger_larpix_2 <= 0;
		if (reset) begin
			counter <= MAX_COUNT_FOR_LASER_TRIGGER;
			trigger_counter <= 0;
		end else begin
			if (0<counter) begin
				counter <= counter - 1'b1;
				if (counter==COUNT_FOR_LARPIX_TRIGGER_1) begin
					trigger_larpix_1 <= 1;
				end
				if (counter==COUNT_FOR_LARPIX_TRIGGER_2) begin
					trigger_larpix_2 <= 1;
				end
			end else begin
				counter <= MAX_COUNT_FOR_LASER_TRIGGER;
				trigger_counter <= trigger_counter + 1'b1;
				trigger_laser <= 1;
			end
		end
	end
	assign led = trigger_counter;
	assign coax[3] = trigger_laser;
	assign coax[2] = trigger_laser;
	assign coax[1] = trigger_larpix_1;
	assign coax[0] = trigger_larpix_2;
	assign coax[5:4] = 0;
endmodule

