`timescale 1ns / 1ps
// from http://svn.clifford.at/handicraft/2015/ringosc/ringosc.v
// last updated 2025-01-09 by mza

`define icestick

module top(
	input CLK,
	input DTRn, RTSn, RX, IR_RX,
	output DCDn, DSRn, CTSn, TX, IR_TX, IR_SD,
	output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
	output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
	output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
	output LED5, LED1, LED2, LED3, LED4
);
	assign TX = RX; assign DCDn = 1'b1; assign DSRn = 1'b1; assign CTSn = 1'b1;
	assign IR_TX = IR_RX; assign IR_SD = 1'b1; // IR_SD = shut down
	assign J1_3 = 1'b0; assign J1_4 = 1'b0; assign J1_5 = 1'b0; assign J1_6 = 1'b0; assign J1_7 = 1'b0; assign J1_8 = 1'b0; assign J1_9 = 1'b0;
	assign J2_1 = 1'b0; assign J2_2 = 1'b0; assign J2_3 = 1'b0; assign J2_4 = 1'b0; assign J2_7 = 1'b0; assign J2_8 = 1'b0; assign J2_9 = 1'b0; assign J2_10 = 1'b0;
	assign J3_3 = 1'b0; assign J3_4 = 1'b0; assign J3_5 = 1'b0; assign J3_6 = 1'b0; assign J3_7 = 1'b0; assign J3_8 = 1'b0; assign J3_9 = 1'b0; assign J3_10 = 1'b0;
	wire chain_in, chain_out, resetn;
	assign J1_10 = chain_out;
	// reset generator
	reg [7:0] reset_count = 0;
	assign resetn = &reset_count;
	always @(posedge CLK) begin
		if (!(&reset_count))
			reset_count <= reset_count + 1;
	end
	// ring oscillator
	wire [99:0] buffers_in, buffers_out;
	assign buffers_in = {buffers_out[98:0], chain_in};
	assign chain_out = buffers_out[99];
	assign chain_in = resetn ? !chain_out : 0;
	SB_LUT4 #(
		.LUT_INIT(16'd2)
	) buffers [99:0] (
		.O(buffers_out),
		.I0(buffers_in),
		.I1(1'b0),
		.I2(1'b0),
		.I3(1'b0)
	);
	// frequency counter
	reg [19:0] counter = 23;
	reg do_count, do_reset;
	always @(posedge chain_out) begin
		if (do_reset)
			counter <= 0;
		else if (do_count)
			counter <= counter + 1;
	end
	// control
	reg [1:0] state;
	reg [15:0] wait_cnt;
	reg [19:0] last_counter;
	reg [19:0] this_counter;
	reg [2:0] debounce;
	reg [4:0] leds;
	assign {LED4, LED3, LED2, LED1, LED5} = leds;
	always @(posedge CLK) begin
		wait_cnt <= wait_cnt + 1;
		do_reset <= state == 0;
		do_count <= state == 1;
		if (!resetn) begin
			state <= 0;
			wait_cnt <= 0;
			leds <= 1;
		end else
		if (&wait_cnt) begin
			if (state == 2) begin
				last_counter <= this_counter;
				this_counter <= counter;
			end
			if (state == 3) begin
				if (last_counter > this_counter+5) begin
					if (!debounce)
						leds <= {1'b1, leds[0], leds[3:1]};
					debounce <= ~0;
				end else begin
					if (debounce)
						debounce <= debounce-1;
					else
						leds[4] <= 0;
				end
			end
			state <= state + 1;
		end
	end
endmodule

