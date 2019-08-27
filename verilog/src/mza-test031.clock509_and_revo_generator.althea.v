`timescale 1ns / 1ps
// written 2019-08-26 by mza
// last updated 2019-08-26 by mza

module mza_test031_clock509_and_revo_generator_althea (
	input local_clock50_in_p,
	input local_clock50_in_n,
	input local_clock509_in_p,
	input local_clock509_in_n,
	output clock509_out_p,
	output clock509_out_n,
	output revo_out_p,
	output revo_out_n,
	output reg lemo,
	output led_0,
	output led_1,
	output led_2,
	output led_3,
	output led_4,
	output led_5,
	output led_6,
	output led_7
);
	wire clock50;
	wire clock509;
	IBUFGDS local_input_clock50_instance (.I(local_clock50_in_p), .IB(local_clock50_in_n), .O(clock50));
	IBUFGDS local_input_clock509_instance (.I(local_clock509_in_p), .IB(local_clock509_in_n), .O(clock509));
	reg reset = 1;
	reg [12:0] reset_counter = 0;
	always @(posedge clock50) begin
		if (reset_counter[10]) begin
			reset <= 0;
		end
		reset_counter <= reset_counter + 1'b1;
	end
	wire rawclock127;
	wire rawclock127b;
	wire locked;
	simplepll_BASE #(.overall_divide(2), .multiply(4), .divide1(8), .divide2(4), .period(1.965), .compensation("INTERNAL")) mypll (.clockin(clock509), .reset(reset), .clock1out(rawclock127), .clock1out180(rawclock127b), .clock2out(), .clock2out180(), .locked(locked));
	wire clock127;
	wire clock127b;
	BUFG mybufg1 (.I(rawclock127), .O(clock127));
	BUFG mybufg2 (.I(rawclock127b), .O(clock127b));
	reg [7:0] revo_word = 0;
//	reg [12:0] bunch_counter = 5120;
//	always @(posedge clock509) begin
//		if (bunch_counter>0) begin
//			bunch_counter <= bunch_counter - 1'b1;
//			revo_word <= 8'b00000000;
//			lemo <= 0;
//		end else begin
//			bunch_counter <= 5120;
//			revo_word <= 8'b11110000;
//			lemo <= 1;
//		end
//	end
	reg [10:0] quad_bunch_counter = 1280;
	always @(posedge word_clock) begin
		if (quad_bunch_counter>0) begin
			quad_bunch_counter <= quad_bunch_counter - 1'b1;
			revo_word <= 8'b00000000;
			lemo <= 0;
		end else begin
			quad_bunch_counter <= 1280;
			revo_word <= 8'b11111111;
			lemo <= 1;
		end
	end
	assign led_7 = reset;
	assign led_6 = 0;
	assign led_5 = 0;
	assign led_4 = 0;
	assign led_3 = 0;
	assign led_2 = reset_counter[12];
	assign led_1 = 0;
	assign led_0 = locked;
	wire clock509_out;
	wire revo_out;
	wire word_clock;
	wire [7:0] clock_word = 8'b10101010;
	ocyrus_double8 #(.WIDTH(8), .PERIOD(7.86), .DIVIDE(1), .MULTIPLY(8)) mylei (.clock_in(clock127), .reset(reset), .word_clock_out(word_clock), .word1_in(clock_word), .word2_in(revo_word), .D1_out(clock509_out), .D2_out(revo_out), .T1_out(), .T2_out(), .locked());
	OBUFDS out1 (.I(clock509_out), .O(clock509_out_p), .OB(clock509_out_n));
	OBUFDS out2 (.I(revo_out), .O(revo_out_p), .OB(revo_out_n));
endmodule

module mza_test031_clock509_and_revo_generator_althea_top (
	input clock50_p, clock50_n,
	output a_p, a_n,
	output d_p, d_n,
	input j_p, j_n,
	output lemo,
	output led_0,
	output led_1,
	output led_2,
	output led_3,
	output led_4,
	output led_5,
	output led_6,
	output led_7
);
	mza_test031_clock509_and_revo_generator_althea mything (
		.local_clock50_in_p(clock50_p),
		.local_clock50_in_n(clock50_n),
		.local_clock509_in_p(j_p),
		.local_clock509_in_n(j_n),
		.clock509_out_p(d_p),
		.clock509_out_n(d_n),
		.revo_out_p(a_p),
		.revo_out_n(a_n),
		.lemo(lemo),
		.led_0(led_0),
		.led_1(led_1),
		.led_2(led_2),
		.led_3(led_3),
		.led_4(led_4),
		.led_5(led_5),
		.led_6(led_6),
		.led_7(led_7)
	);
endmodule

