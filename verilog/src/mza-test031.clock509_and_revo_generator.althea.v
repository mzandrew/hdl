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
	reg [26:0] counter = 0;
	always @(posedge clock50) begin
		if (counter[10]) begin
			reset <= 0;
		end
		counter <= counter + 1'b1;
	end
	parameter clock_word = 8'b10101010;
	wire [7:0] revo_word;
	wire oserdes_pll_locked1;
	wire oserdes_pll_locked2;
	assign led_7 = oserdes_pll_locked1;
	assign led_6 = oserdes_pll_locked2;
	assign led_5 = 0;
	assign led_4 = revo;
	assign led_3 = 0;
	assign led_2 = reset;
	assign led_1 = 0;
	assign led_0 = counter[26];
	wire clock509_oddr;
	wire revo_oddr;
	wire word_clock1;
	wire word_clock2;
	wire revo;
	superkekb skb (.clock(word_clock1), .reset(reset), .revo(revo), .revo_word(revo_word));
	wire rawclock127;
	BUFIO2 #(
		.DIVIDE(4), .USE_DOUBLER("FALSE"), .I_INVERT("FALSE"), .DIVIDE_BYPASS("FALSE")
	) sally (
		.I(clock509), .DIVCLK(rawclock127), .IOCLK(), .SERDESSTROBE()
	);
	wire clock127;
	BUFG peter (.I(rawclock127), .O(clock127));
	ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(7.86), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL"), .MODE("WORD_CLOCK_IN")) mylei1 (.clock_in(clock127), .reset(reset), .word_clock_out(word_clock1), .word_in(clock_word), .D_out(clock509_oddr), .locked(oserdes_pll_locked1));
	ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(7.86), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL"), .MODE("WORD_CLOCK_IN")) mylei2 (.clock_in(clock127), .reset(reset), .word_clock_out(word_clock2), .word_in(revo_word), .D_out(revo_oddr), .locked(oserdes_pll_locked2));
//	ocyrus_double8 #(.BIT_DEPTH(8), .PERIOD(1.965), .DIVIDE(2), .MULTIPLY(4), .SCOPE("BUFPLL")) mylei1 (.clock_in(clock509), .reset(reset), .word_clock_out(word_clock), .word1_in(clock_word), .word2_in(revo_word), .D1_out(clock509_oddr), .D2_out(revo_oddr), .locked(oserdes_pll_locked));
//	ocyrus_double8 #(.BIT_DEPTH(8), .PERIOD(1.965), .DIVIDE(2), .MULTIPLY(4), .SCOPE("BUFPLL")) mylei2 (.clock_in(clock509), .reset(reset), .word_clock_out(word_clock2), .word1_in(clock_word), .word2_in(revo_word), .D1_out(clock509_oddr2), .D2_out(revo_oddr2), .locked(oserdes_pll_locked2));
	OBUFDS out1 (.I(1'b0), .O(clk78_p), .OB(clk78_n));
	OBUFDS out2 (.I(revo_oddr), .O(trg36_p), .OB(trg36_n));
	assign lemo = clock509_oddr;
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
		.lemo(lemo),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

