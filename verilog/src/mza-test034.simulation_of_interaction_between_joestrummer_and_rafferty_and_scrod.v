`timescale 1ns / 1ps
// written 2019-09-20 by mza
// last updated 2019-09-20 by mza

module joestrummer_and_rafferty_tb;
	reg joestrummer_local_clock50_in_p = 0, joestrummer_local_clock50_in_n = 1;
	reg joestrummer_local_clock509_in_p = 0, joestrummer_local_clock509_in_n = 1;
	wire joestrummer_trg36_p, joestrummer_trg36_n;
	wire joestrummer_lemo;
	wire joestrummer_led_0, joestrummer_led_1, joestrummer_led_2, joestrummer_led_3, joestrummer_led_4, joestrummer_led_5, joestrummer_led_6, joestrummer_led_7;
	wire raw_recovered_revo;
	assign raw_recovered_revo = rafferty_clk78_p ^ rafferty_trg36_p;
	reg recovered_revo = 0;
	mza_test031_clock509_and_revo_generator_althea joestrummer (
		.local_clock50_in_p(joestrummer_local_clock50_in_p), .local_clock50_in_n(joestrummer_local_clock50_in_n),
		.local_clock509_in_p(joestrummer_local_clock509_in_p), .local_clock509_in_n(joestrummer_local_clock509_in_n),
		.clk78_p(), .clk78_n(),
		.trg36_p(joestrummer_trg36_p), .trg36_n(joestrummer_trg36_n),
		.lemo(joestrummer_lemo),
		.led_0(joestrummer_led_0), .led_1(joestrummer_led_1), .led_2(joestrummer_led_2), .led_3(joestrummer_led_3),
		.led_4(joestrummer_led_4), .led_5(joestrummer_led_5), .led_6(joestrummer_led_6), .led_7(joestrummer_led_7)
	);
	initial begin
		joestrummer_local_clock509_in_p = 0; joestrummer_local_clock509_in_n = 1;
		joestrummer_local_clock50_in_p = 0; joestrummer_local_clock50_in_n = 1;
		rafferty_local_clock50_in_p <= 0; rafferty_local_clock50_in_n <= 1;
		rafferty_local_clock509_in_p <= 0; rafferty_local_clock509_in_n <= 1;
		rafferty_lemo <= 0; rafferty_clock_select <= 0;
		recovered_revo <= 0;
	end
	always begin
		#1;
		joestrummer_local_clock509_in_p <= ~joestrummer_local_clock509_in_p; joestrummer_local_clock509_in_n <= ~joestrummer_local_clock509_in_n;
	end
	always begin
		#10;
		joestrummer_local_clock50_in_p <= ~joestrummer_local_clock50_in_p; joestrummer_local_clock50_in_n <= ~joestrummer_local_clock50_in_n;
	end
	// Inputs
	reg rafferty_local_clock50_in_p = 0;
	reg rafferty_local_clock50_in_n = 1;
	reg rafferty_local_clock509_in_p = 0;
	reg rafferty_local_clock509_in_n = 1;
	// Outputs
	wire rafferty_clk78_p;
	wire rafferty_clk78_n;
	wire rafferty_trg36_p;
	wire rafferty_trg36_n;
	wire rafferty_out1_p;
	wire rafferty_out1_n;
	wire rafferty_outa_p;
	wire rafferty_outa_n;
	wire rafferty_rsv54_p;
	wire rafferty_rsv54_n;
	reg rafferty_lemo = 0;
	wire rafferty_ack12_p;
	wire rafferty_ack12_n;
	wire rafferty_led_revo;
	wire rafferty_led_rfclock;
	wire rafferty_driven_high;
	reg rafferty_clock_select = 0;
	wire rafferty_led_0;
	wire rafferty_led_1;
	wire rafferty_led_2;
	wire rafferty_led_3;
	wire rafferty_led_4;
	wire rafferty_led_5;
	wire rafferty_led_6;
	wire rafferty_led_7;
	wire remote_clock_p, remote_clock_n;
	OBUFDS samwise (.I(joestrummer_lemo), .O(remote_clock_p), .OB(remote_clock_n));
	mza_test032_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea rafferty (
		.local_clock50_in_p(rafferty_local_clock50_in_p), .local_clock50_in_n(rafferty_local_clock50_in_n),
		.remote_clock509_in_p(remote_clock_p), .remote_clock509_in_n(remote_clock_n),
		.remote_revo_in_p(joestrummer_trg36_p), .remote_revo_in_n(joestrummer_trg36_n),
		.clk78_p(rafferty_clk78_p), .clk78_n(rafferty_clk78_n),
		.trg36_p(rafferty_trg36_p), .trg36_n(rafferty_trg36_n),
		.rsv54_p(rafferty_rsv54_p), .rsv54_n(rafferty_rsv54_n),
		.ack12_p(rafferty_ack12_p), .ack12_n(rafferty_ack12_n),
		.out1_p(rafferty_out1_p), .out1_n(rafferty_out1_n),
		.outa_p(rafferty_outa_p), .outa_n(rafferty_outa_n),
		.lemo(rafferty_lemo),
		.led_revo(rafferty_led_revo),
		.led_rfclock(rafferty_led_rfclock),
		.clock_select(rafferty_clock_select),
		.driven_high(rafferty_driven_high),
		.led_0(rafferty_led_0), .led_1(rafferty_led_1), .led_2(rafferty_led_2), .led_3(rafferty_led_3),
		.led_4(rafferty_led_4), .led_5(rafferty_led_5), .led_6(rafferty_led_6), .led_7(rafferty_led_7)
	);
	always begin
		#1;
		rafferty_local_clock509_in_p <= ~rafferty_local_clock509_in_p; rafferty_local_clock509_in_n <= ~rafferty_local_clock509_in_n;
	end
	always begin
		#10;
		rafferty_local_clock50_in_p <= ~rafferty_local_clock50_in_p; rafferty_local_clock50_in_n <= ~rafferty_local_clock50_in_n;
	end
	always @(negedge rafferty_clk78_p) begin
		recovered_revo <= raw_recovered_revo;
	end
endmodule

module joestrummer_and_rafferty_and_scrod_tb;
	reg joestrummer_local_clock50_in_p = 0, joestrummer_local_clock50_in_n = 1;
	reg joestrummer_local_clock509_in_p = 0, joestrummer_local_clock509_in_n = 1;
	wire joestrummer_trg36_p, joestrummer_trg36_n;
	wire joestrummer_lemo;
	wire joestrummer_led_0, joestrummer_led_1, joestrummer_led_2, joestrummer_led_3, joestrummer_led_4, joestrummer_led_5, joestrummer_led_6, joestrummer_led_7;
	wire raw_recovered_revo;
	assign raw_recovered_revo = rafferty_clk78_p ^ rafferty_trg36_p;
	reg recovered_revo = 0;
	mza_test031_clock509_and_revo_generator_althea joestrummer (
		.local_clock50_in_p(joestrummer_local_clock50_in_p), .local_clock50_in_n(joestrummer_local_clock50_in_n),
		.local_clock509_in_p(joestrummer_local_clock509_in_p), .local_clock509_in_n(joestrummer_local_clock509_in_n),
		.clk78_p(), .clk78_n(),
		.trg36_p(joestrummer_trg36_p), .trg36_n(joestrummer_trg36_n),
		.lemo(joestrummer_lemo),
		.led_0(joestrummer_led_0), .led_1(joestrummer_led_1), .led_2(joestrummer_led_2), .led_3(joestrummer_led_3),
		.led_4(joestrummer_led_4), .led_5(joestrummer_led_5), .led_6(joestrummer_led_6), .led_7(joestrummer_led_7)
	);
	initial begin
		joestrummer_local_clock509_in_p = 0; joestrummer_local_clock509_in_n = 1;
		joestrummer_local_clock50_in_p = 0; joestrummer_local_clock50_in_n = 1;
		rafferty_local_clock50_in_p <= 0; rafferty_local_clock50_in_n <= 1;
		rafferty_local_clock509_in_p <= 0; rafferty_local_clock509_in_n <= 1;
		rafferty_lemo <= 0; rafferty_clock_select <= 0;
		recovered_revo <= 0;
	end
	always begin
		#1;
		joestrummer_local_clock509_in_p <= ~joestrummer_local_clock509_in_p; joestrummer_local_clock509_in_n <= ~joestrummer_local_clock509_in_n;
	end
	always begin
		#10;
		joestrummer_local_clock50_in_p <= ~joestrummer_local_clock50_in_p; joestrummer_local_clock50_in_n <= ~joestrummer_local_clock50_in_n;
	end
	// Inputs
	reg rafferty_local_clock50_in_p = 0;
	reg rafferty_local_clock50_in_n = 1;
	reg rafferty_local_clock509_in_p = 0;
	reg rafferty_local_clock509_in_n = 1;
	// Outputs
	wire rafferty_clk78_p;
	wire rafferty_clk78_n;
	wire rafferty_trg36_p;
	wire rafferty_trg36_n;
	wire rafferty_out1_p;
	wire rafferty_out1_n;
	wire rafferty_outa_p;
	wire rafferty_outa_n;
	wire rafferty_rsv54_p;
	wire rafferty_rsv54_n;
	reg rafferty_lemo = 0;
	wire rafferty_ack12_p;
	wire rafferty_ack12_n;
	wire rafferty_led_revo;
	wire rafferty_led_rfclock;
	wire rafferty_driven_high;
	reg rafferty_clock_select = 0;
	wire rafferty_led_0;
	wire rafferty_led_1;
	wire rafferty_led_2;
	wire rafferty_led_3;
	wire rafferty_led_4;
	wire rafferty_led_5;
	wire rafferty_led_6;
	wire rafferty_led_7;
	wire remote_clock_p, remote_clock_n;
	OBUFDS samwise (.I(joestrummer_lemo), .O(remote_clock_p), .OB(remote_clock_n));
	mza_test032_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea rafferty (
		.local_clock50_in_p(rafferty_local_clock50_in_p), .local_clock50_in_n(rafferty_local_clock50_in_n),
		.remote_clock509_in_p(remote_clock_p), .remote_clock509_in_n(remote_clock_n),
		.remote_revo_in_p(joestrummer_trg36_p), .remote_revo_in_n(joestrummer_trg36_n),
		.clk78_p(rafferty_clk78_p), .clk78_n(rafferty_clk78_n),
		.trg36_p(rafferty_trg36_p), .trg36_n(rafferty_trg36_n),
		.rsv54_p(rafferty_rsv54_p), .rsv54_n(rafferty_rsv54_n),
		.ack12_p(rafferty_ack12_p), .ack12_n(rafferty_ack12_n),
		.out1_p(rafferty_out1_p), .out1_n(rafferty_out1_n),
		.outa_p(rafferty_outa_p), .outa_n(rafferty_outa_n),
		.lemo(rafferty_lemo),
		.led_revo(rafferty_led_revo),
		.led_rfclock(rafferty_led_rfclock),
		.clock_select(rafferty_clock_select),
		.driven_high(rafferty_driven_high),
		.led_0(rafferty_led_0), .led_1(rafferty_led_1), .led_2(rafferty_led_2), .led_3(rafferty_led_3),
		.led_4(rafferty_led_4), .led_5(rafferty_led_5), .led_6(rafferty_led_6), .led_7(rafferty_led_7)
	);
	always begin
		#1;
		rafferty_local_clock509_in_p <= ~rafferty_local_clock509_in_p; rafferty_local_clock509_in_n <= ~rafferty_local_clock509_in_n;
	end
	always begin
		#10;
		rafferty_local_clock50_in_p <= ~rafferty_local_clock50_in_p; rafferty_local_clock50_in_n <= ~rafferty_local_clock50_in_n;
	end
	always @(negedge rafferty_clk78_p) begin
		recovered_revo <= raw_recovered_revo;
	end
endmodule

