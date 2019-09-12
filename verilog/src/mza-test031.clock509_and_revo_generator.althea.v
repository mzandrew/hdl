`timescale 1ns / 1ps
// written 2019-08-26 by mza
// last updated 2019-09-12 by mza

module mza_test031_clock509_and_revo_generator_althea (
	input local_clock50_in_p, local_clock50_in_n,
	input local_clock509_in_p, local_clock509_in_n,
	output clk78_p, clk78_n,
	output trg36_p, trg36_n,
	output clk_se,
	output trg_se,
	output lemo,
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	wire clock50;
	wire clock509;
	IBUFGDS local_input_clock50_instance (.I(local_clock50_in_p), .IB(local_clock50_in_n), .O(clock50));
	IBUFGDS local_input_clock509_instance (.I(local_clock509_in_p), .IB(local_clock509_in_n), .O(clock509));
	reg reset = 1;
	reg [26:0] reset_counter = 0;
	always @(posedge clock50) begin
		if (reset_counter[10]) begin
			reset <= 0;
		end
		reset_counter <= reset_counter + 1'b1;
	end
	wire rawclock127;
	wire rawclock127b;
	wire locked;
	simplepll_BASE #(
			.overall_divide(2), .multiply(4), .period(1.965), .compensation("INTERNAL"),
			.divide0(8), .divide1(8), .divide2(4), .divide3(4), .divide4(4), .divide5(4)
		) mypll (
			.clockin(clock509), .reset(reset), .locked(pll_509_127_locked),
			.clock0out(rawclock127), .clock1out(rawclock127b), .clock2out(), .clock3out(), .clock4out(), .clock5out()
		);
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
	reg reg_revo = 0;
	parameter number_of_quad_bunches_minus_one = 1280 - 1;
	reg [10:0] quad_bunch_counter = number_of_quad_bunches_minus_one;
	always @(posedge word_clock) begin
		if (reset) begin
			reg_revo <= 0;
			quad_bunch_counter <= number_of_quad_bunches_minus_one;
			revo_word <= 8'b00000000;
		end else begin
			if (quad_bunch_counter>0) begin
				quad_bunch_counter <= quad_bunch_counter - 1'b1;
				revo_word <= 8'b00000000;
				reg_revo <= 0;
			end else begin
				quad_bunch_counter <= number_of_quad_bunches_minus_one;
				revo_word <= 8'b11111111;
				reg_revo <= 1;
			end
		end
	end
	wire oserdes_pll_locked;
	wire oserdes_pll_locked2;
	assign led_7 = pll_509_127_locked;
	assign led_6 = oserdes_pll_locked;
	assign led_5 = oserdes_pll_locked2;
	assign led_4 = reset;
	assign led_3 = reg_revo;
	assign led_2 = 0;
	assign led_1 = 0;
	assign led_0 = 0;
	wire clock509_oddr1;
	wire clock509_oddr2;
	wire revo_oddr1;
	wire revo_oddr2;
	wire word_clock;
	wire word_clock2;
	wire [7:0] clock_word = 8'b10101010;
	ocyrus_double8 #(.WIDTH(8), .PERIOD(7.86), .DIVIDE(1), .MULTIPLY(8)) mylei1 (.clock_in(clock127), .reset(reset), .word_clock_out(word_clock), .word1_in(clock_word), .word2_in(revo_word), .D1_out(clock509_oddr1), .D2_out(revo_oddr1), .locked(oserdes_pll_locked));
//	ocyrus_double8 #(.WIDTH(8), .PERIOD(7.86), .DIVIDE(1), .MULTIPLY(8)) mylei2 (.clock_in(clock127), .reset(reset), .word_clock_out(word_clock2), .word1_in(clock_word), .word2_in(revo_word), .D1_out(clock509_oddr2), .D2_out(revo_oddr2), .locked(oserdes_pll_locked2));
//	ocyrus_quad8 #(.WIDTH(8), .PERIOD(7.86), .DIVIDE(1), .MULTIPLY(8)) mylei (
//			.clock_in(clock127), .reset(reset), .word_clock_out(word_clock), .locked(oserdes_pll_locked),
//			.word1_in(clock_word), .word2_in(revo_word), .word3_in(clock_word), .word4_in(revo_word),
//			.D1_out(clock509_oddr1), .D2_out(revo_oddr1), .D3_out(clock509_oddr2), .D4_out(revo_oddr2)
//		);
	OBUFDS out1 (.I(clock509_oddr1), .O(clk78_p), .OB(clk78_n));
//	OBUFDS out1 (.I(reg_revo), .O(clk78_p), .OB(clk78_n));
	OBUFDS out2 (.I(revo_oddr1), .O(trg36_p), .OB(trg36_n));
//	OBUFDS out2 (.I(reg_revo), .O(trg36_p), .OB(trg36_n));
	assign lemo = reg_revo;
//	assign lemo = clock509_oddr2;
//	assign clk_se = clock509_oddr2;
//	assign trg_se = revo_oddr2;
	assign clk_se = 0;
	assign trg_se = 0;
endmodule

module mza_test031_clock509_and_revo_generator_althea_tb;
	reg local_clock50_in_p = 0, local_clock50_in_n = 1;
	reg local_clock509_in_p = 0, local_clock509_in_n = 1;
	wire clk78_p, clk78_n;
	wire trg36_p, trg36_n;
	wire lemo;
	wire led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7;
	mza_test031_clock509_and_revo_generator_althea mything (
		.local_clock50_in_p(local_clock50_in_p), .local_clock50_in_n(local_clock50_in_n),
		.local_clock509_in_p(local_clock509_in_p), .local_clock509_in_n(local_clock509_in_n),
		.clk78_p(clk78_p), .clk78_n(clk78_n),
		.trg36_p(trg36_p), .trg36_n(trg36_n),
		.lemo(lemo),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
	initial begin
		local_clock509_in_p = 0; local_clock509_in_n = 1;
		local_clock50_in_p = 0; local_clock50_in_n = 1;
	end
	always begin
		#1;
		local_clock509_in_p <= ~local_clock509_in_p; local_clock509_in_n <= ~local_clock509_in_n;
	end
	always begin
		#10;
		local_clock50_in_p <= ~local_clock50_in_p; local_clock50_in_n <= ~local_clock50_in_n;
	end
endmodule

module mza_test031_clock509_and_revo_generator_althea_top (
	input clock50_p, clock50_n,
	output a_p, a_n,
	output b_p, b_n,
	input d_p, d_n,
//	output e_p, f_p,
	output h_p, k_p,
	output lemo,
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	mza_test031_clock509_and_revo_generator_althea mything (
		.local_clock50_in_p(clock50_p), .local_clock50_in_n(clock50_n),
		.local_clock509_in_p(d_p), .local_clock509_in_n(d_n),
		.clk78_p(a_p), .clk78_n(a_n),
		.trg36_p(b_p), .trg36_n(b_n),
		.clk_se(k_p),
		.trg_se(h_p),
//		.clk_se(e_p),
//		.trg_se(f_p),
		.lemo(lemo),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

