`timescale 1ns / 1ps
// written 2019-08-14 by mza
// last updated 2019-08-21 by mza

// todo: auto-fallover for missing 509; and auto-fake revo when that happens

module mza_test029_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea (
	input local_clock50_in_p,
	input local_clock50_in_n,
	input local_clock509_in_p,
	input local_clock509_in_n,
	input remote_clock509_in_p,
	input remote_clock509_in_n,
	input remote_revo_in_p,
	input remote_revo_in_n,
	output clock127_out_p,
	output clock127_out_n,
	output trg_out_p,
	output trg_out_n,
	output out1_p,
	output out1_n,
	output outa_p,
	output outa_n,
	output rsv_p,
	output rsv_n,
	input lemo,
	input ack_p,
	input ack_n,
	output reg led_revo,
	output reg led_rfclock,
	output led_0,
	output led_1,
	output led_2,
	output led_3,
	output led_4,
	output led_5,
	output led_6,
	output led_7
);
	wire ack;
	IBUFGDS ackbuf (.I(ack_p), .IB(ack_n), .O(ack));
	wire remote_clock509;
	wire local_clock50;
	wire local_clock509;
	wire clock509;
	IBUFGDS remote_input_clock509_instance (.I(remote_clock509_in_p), .IB(remote_clock509_in_n), .O(remote_clock509));
	IBUFGDS local_input_clock50_instance (.I(local_clock50_in_p), .IB(local_clock50_in_n), .O(local_clock50));
	IBUFGDS local_input_clock509_instance (.I(local_clock509_in_p), .IB(local_clock509_in_n), .O(local_clock509));
	assign clock509 = remote_clock509;
	reg reset = 1;
	reg [12:0] reset_counter = 0;
	wire rawtrg;
	IBUFGDS trigger_input_instance (.I(remote_revo_in_p), .IB(remote_revo_in_n), .O(rawtrg));
	parameter TRGSTREAM_WIDTH = 16;
	parameter TRG_MAX_DURATION = 8;
	reg [TRGSTREAM_WIDTH-1:0] trgstream = 0;
	reg [TRGSTREAM_WIDTH-TRG_MAX_DURATION-1:0] upper;
	reg [TRG_MAX_DURATION-1:0] lower;
	always @(posedge local_clock50) begin
		if (reset_counter[10]) begin
			reset <= 0;
		end
		reset_counter <= reset_counter + 1'b1;
		led_rfclock <= 0;
		if (clock509) begin
			led_rfclock <= 1;
		end
	end
	wire rawclock127;
	wire rawclock127b;
	wire rawclock254;
	wire rawclock254b;
	wire locked;
	simplepll_BASE #(.overall_divide(2), .multiply(4), .divide1(8), .divide2(4), .period(1.965), .compensation("INTERNAL")) mypll (.clockin(clock509), .reset(reset), .clock1out(rawclock127), .clock1out180(rawclock127b), .clock2out(rawclock254), .clock2out180(rawclock254b), .locked(locked));
	wire clock127;
	wire clock127b;
	BUFG mybufg1 (.I(rawclock127), .O(clock127));
	BUFG mybufg2 (.I(rawclock127b), .O(clock127b));
	wire clock254;
	wire clock254b;
	BUFG mybufg3 (.I(rawclock254), .O(clock254));
	BUFG mybufg4 (.I(rawclock254b), .O(clock254b));
	reg dummy = 0;
	always @(posedge local_clock509) begin
		dummy <= 0;
		if (trg) begin
			dummy <= 1;
		end
	end
	always @(posedge word_clock) begin
		if (lemo) begin
			word <= word0;
		end else begin
			word <= word1;
		end
	end
	always @(posedge clock509) begin
		led_revo <= 0;
		trg <= 0;
		//if (trgstream[TRGSTREAM_WIDTH-1:TRG_MAX_DURATION] == 0 && trgstream[TRG_MAX_DURATION-1:0] != 0) begin
		if (upper==0 & lower!=0) begin
			trg <= 1;
			led_revo <= 1;
		end
		upper <= trgstream[TRGSTREAM_WIDTH-1:TRG_MAX_DURATION];
		lower <= trgstream[TRG_MAX_DURATION-1:0];
		trgstream <= { trgstream[TRGSTREAM_WIDTH-2:0], rawtrg };
	end
	reg trg = 0;
	wire clock127oddr1;
	ODDR2 doughnut1 (.C0(clock127), .C1(clock127b), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(1'b0), .S(1'b0), .Q(clock127oddr1));
	OBUFDS supercool (.I(clock127oddr1), .O(clock127_out_p), .OB(clock127_out_n));
	wire clock127oddr2;
	ODDR2 doughnut2 (.C0(clock127), .C1(clock127b), .CE(~trg),  .D0(1'b0), .D1(1'b1), .R(1'b0), .S(1'b0), .Q(clock127oddr2));
	OBUFDS grouch2 (.I(clock127oddr2), .O(trg_out_p), .OB(trg_out_n));
	assign led_7 = reset;
	assign led_6 = 0;
	assign led_5 = dummy;
	assign led_4 = trg;
	assign led_3 = 0;
	assign led_2 = reset_counter[12];
	assign led_1 = 0;
	assign led_0 = locked;
	OBUFDS out1 (.I(trg), .O(out1_p), .OB(out1_n));
	wire D;
	wire word_clock;
	reg [7:0] word;
	wire [7:0] word0 = 8'b11110100;
	wire [7:0] word1 = 8'b11110010;
	ocyrus_single8 #(.WIDTH(8), .PERIOD(3.93), .DIVIDE(2), .MULTIPLY(8)) mylei (.clock_in(clock254), .reset(reset), .word_clock_out(word_clock), .word_in(word), .D_out(D), .T_out(), .locked());
	wire clock254oddr;
	ODDR2 doughnut3 (.C0(clock254), .C1(clock254b), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(1'b0), .S(1'b0), .Q(clock254oddr));
	OBUFDS outa (.I(clock254oddr), .O(outa_p), .OB(outa_n));
	//OBUFDS outa (.I(D), .O(outa_p), .OB(outa_n));
	OBUFDS out (.I(D), .O(rsv_p), .OB(rsv_n));
endmodule

module mything_tb;
	// Inputs
	reg remote_clock509_in_p;
	reg remote_clock509_in_n;
	reg remote_revo_in_p;
	reg remote_revo_in_n;
	// Outputs
	wire clock127_out_p;
	wire clock127_out_n;
	wire trg_out_p;
	wire trg_out_n;
	wire out1_p;
	wire out1_n;
	wire outa_p;
	wire outa_n;
	wire rsv_p;
	wire rsv_n;
	wire lemo;
	wire ack_p;
	wire ack_n;
	wire led_revo;
	wire led_rfclock;
	wire led_0;
	wire led_1;
	wire led_2;
	wire led_3;
	wire led_4;
	wire led_5;
	wire led_6;
	wire led_7;
	// Instantiate the Unit Under Test (UUT)
	mza_test029_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea uut (
		.remote_clock509_in_p(remote_clock509_in_p), 
		.remote_clock509_in_n(remote_clock509_in_n), 
		.remote_revo_in_p(remote_revo_in_p), 
		.remote_revo_in_n(remote_revo_in_n), 
		.clock127_out_p(clock127_out_p), 
		.clock127_out_n(clock127_out_n), 
		.trg_out_p(trg_out_p), 
		.trg_out_n(trg_out_n), 
		.out1_p(out1_p), 
		.out1_n(out1_n), 
		.outa_p(outa_p), 
		.outa_n(outa_n), 
		.rsv_p(rsv_p),
		.rsv_n(rsv_n),
		.lemo(lemo),
		.ack_p(ack_p),
		.ack_n(ack_n),
		.led_revo(l_p),
		.led_rfclock(l_n),
		.led_0(led_0), 
		.led_1(led_1), 
		.led_2(led_2), 
		.led_3(led_3), 
		.led_4(led_4), 
		.led_5(led_5), 
		.led_6(led_6), 
		.led_7(led_7)
	);
	wire raw_recovered_reco;
	assign raw_recovered_reco = clock127_out_p ^ trg_out_p;
	reg recovered_revo;
	initial begin
		// Initialize Inputs
		remote_clock509_in_p = 0; remote_clock509_in_n = 1;
		remote_revo_in_p = 0; remote_revo_in_n = 1;
		recovered_revo = 0;
		// Wait 100 ns for global reset to finish
		#100;
		// Add stimulus here
		#5000;
		remote_revo_in_p = 1; remote_revo_in_n = 0;
		#2;
		remote_revo_in_p = 0; remote_revo_in_n = 1;
		#50;
		remote_revo_in_p = 1; remote_revo_in_n = 0;
		#8;
		remote_revo_in_p = 0; remote_revo_in_n = 1;
		#50;
		remote_revo_in_p = 1; remote_revo_in_n = 0;
		#30;
		remote_revo_in_p = 0; remote_revo_in_n = 1;
	end
	always begin
		#1;
		remote_clock509_in_p = ~ remote_clock509_in_p;
		remote_clock509_in_n = ~ remote_clock509_in_n;
	end
	always @(negedge clock127_out_p) begin
		recovered_revo <= raw_recovered_reco;
	end
endmodule

module mza_test029_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea_top (
	input clock50_p, clock50_n,
	input a_p, a_n,
	output b_p, b_n,
	output c_p, c_n,
	output d_p, d_n,
	output e_p, e_n,
	input h_p, h_n,
	input j_p, j_n,
	input k_p, k_n,
	input lemo,
	output l_p, l_n,
	output led_0,
	output led_1,
	output led_2,
	output led_3,
	output led_4,
	output led_5,
	output led_6,
	output led_7
);
	mza_test029_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea mything (
		.local_clock50_in_p(clock50_p),
		.local_clock50_in_n(clock50_n),
		.local_clock509_in_p(j_p),
		.local_clock509_in_n(j_n),
		.remote_clock509_in_p(k_p),
		.remote_clock509_in_n(k_n),
		.remote_revo_in_p(h_p),
		.remote_revo_in_n(h_n),
		.clock127_out_p(d_p),
		.clock127_out_n(d_n),
		.trg_out_p(f_p),
		.trg_out_n(f_n),
		.out1_p(e_p),
		.out1_n(e_n),
		.outa_p(b_p),
		.outa_n(b_n),
		.rsv_p(c_p),
		.rsv_n(c_n),
		.lemo(lemo),
		.ack_p(a_p),
		.ack_n(a_n),
		.led_revo(l_p),
		.led_rfclock(l_n),
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

