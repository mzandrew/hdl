`timescale 1ns / 1ps
// written 2019-09-09 by mza
// based partly off mza-test029
// last updated 2019-09-13 by mza

// todo: auto-fallover for missing 509; and auto-fake revo when that happens

module mza_test032_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea (
	input local_clock50_in_p, local_clock50_in_n,
	input local_clock509_in_p, local_clock509_in_n,
	input remote_clock509_in_p, remote_clock509_in_n,
	input remote_revo_in_p, remote_revo_in_n,
	output ack12_p, ack12_n,
	output trg36_p, trg36_n,
	output rsv54_p, rsv54_n,
	output clk78_p, clk78_n,
	output out1_p, out1_n,
	output outa_p, outa_n,
	input lemo,
	output reg led_revo,
	output led_rfclock,
	output driven_high,
	input clock_select,
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	wire remote_clock509;
	wire local_clock509;
	wire clock509;
	IBUFGDS remote_input_clock509_instance (.I(remote_clock509_in_p), .IB(remote_clock509_in_n), .O(remote_clock509));
	IBUFGDS local_input_clock509_instance (.I(local_clock509_in_p), .IB(local_clock509_in_n), .O(local_clock509));
	assign driven_high = 1;
//	BUFGMUX #(.CLK_SEL_TYPE("ASYNC")) clock_selection_instance (.I0(remote_clock509), .I1(local_clock509), .S(clock_select), .O(clock509));
	assign clock509 = remote_clock509;
	// ----------------------------------------------------------------------
	reg reset1 = 1;
	reg reset2 = 1;
	wire reset;
	assign reset = reset1 | reset2;
	reg [25:0] counter = 0;
	wire local_clock50;
	IBUFGDS local_input_clock50_instance (.I(local_clock50_in_p), .IB(local_clock50_in_n), .O(local_clock50));
	reg acknowledge_that_we_saw_a_trigger_recently = 0;
	always @(posedge local_clock50) begin
		if (reset1) begin
			counter <= 0;
			led_revo <= 0;
			reset2 <= 1;
		end else begin
			reset2 <= ~pll_127_127_locked;
		end
		if (counter[10]) begin
			reset1 <= 0;
		end
		if (counter[18:0]==0) begin
			if (saw_a_trigger_recently) begin
				led_revo <= 1;
				acknowledge_that_we_saw_a_trigger_recently <= 1;
			end else begin
				led_revo <= 0;
				acknowledge_that_we_saw_a_trigger_recently <= 0;
			end
		end
		counter <= counter + 1'b1;
	end
	// ----------------------------------------------------------------------
	wire rawclock127_0;
	wire rawclock127_90;
	wire rawclock127_180;
	wire rawclock127_270;
	wire raw_clock509a, raw_clock509b;
	wire pll_127_127_locked;
	assign led_rfclock = pll_127_127_locked;
	wire revo_stream_clock127;
	simplepll_BASE #(.overall_divide(2), .multiply(16), .period(7.86), .compensation("INTERNAL"),
		.divide0(8), .divide1(8), .divide2(8), .divide3(8), .divide4(2), .divide5(2),
		.phase0(0.0), .phase1(90.0), .phase2(180.0), .phase3(270.0), .phase4(0.0), .phase5(180.0)
	) mypll (.clockin(revo_stream_clock127), .reset(reset1), .locked(pll_127_127_locked),
		.clock0out(rawclock127_0), .clock1out(rawclock127_90),
		.clock2out(rawclock127_180), .clock3out(rawclock127_270),
		.clock4out(raw_clock509a), .clock5out(raw_clock509b)
	);
	// ----------------------------------------------------------------------
	wire rawtrg;
	IBUFDS trigger_input_instance (.I(remote_revo_in_p), .IB(remote_revo_in_n), .O(rawtrg));
	reg saw_a_trigger_recently = 0;
	always @(posedge rawtrg or posedge reset or posedge acknowledge_that_we_saw_a_trigger_recently) begin
		if (reset | acknowledge_that_we_saw_a_trigger_recently) begin
			saw_a_trigger_recently <= 0;
		end else begin
			saw_a_trigger_recently <= 1;
		end
	end
	wire [3:0] revo_stream127;
	iserdes_single4 revo_iserdes (.sample_clock(clock509), .data_in(rawtrg), .reset(reset1), .word_clock(revo_stream_clock127), .word_out(revo_stream127));
	wire [3:0] pulse_revo_stream127;
	edge_to_pulse #(.WIDTH(4)) midge (.clock(revo_stream_clock127), .in(revo_stream127), .reset(reset), .out(pulse_revo_stream127));
	reg [1:0] select2 = 0;
	reg [3:0] select4 = 0;
	reg phase_locked = 0;
	always @(posedge revo_stream_clock127 or posedge reset) begin
		if (reset) begin
			select2 <= 0;
			select4 <= 0;
			phase_locked <= 0;
		end else begin
			if (!phase_locked) begin
				case (pulse_revo_stream127)
					4'b1111 : begin select2 <= 2'b00; select4 <= pulse_revo_stream127; phase_locked <= 1; end
					4'b1110 : begin select2 <= 2'b01; select4 <= pulse_revo_stream127; phase_locked <= 1; end
					4'b1100 : begin select2 <= 2'b10; select4 <= pulse_revo_stream127; phase_locked <= 1; end
					4'b1000 : begin select2 <= 2'b11; select4 <= pulse_revo_stream127; phase_locked <= 1; end
					default : begin end
				endcase
			end
		end
	end
	wire clock127_0s;
	wire clock127_1s;
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_0s (.I0(rawclock127_0),   .I1(rawclock127_90),  .S(select2[0]), .O(clock127_0s));
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_1s (.I0(rawclock127_180), .I1(rawclock127_270), .S(select2[0]), .O(clock127_1s));
	wire clock127;
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_sx (.I0(clock127_0s), .I1(clock127_1s), .S(select2[1]), .O(clock127));
	wire clock127b;
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_b (.I0(clock127_0s), .I1(clock127_1s), .S(~select2[1]), .O(clock127b));
	// ----------------------------------------------------------------------
	wire [3:0] other_revo_stream127;
	ssynchronizer_pnp #(.WIDTH(4)) sharma (.clock1(revo_stream_clock127), .clock2(clock127), .reset(reset), .in1(revo_stream127), .out2(other_revo_stream127));
	reg long_trg = 0;
	wire short_trg;
	reg trg = 0;
	reg trg_inv = 1;
	edge_to_pulse #(.WIDTH(1)) midgey (.clock(clock127), .in(long_trg), .reset(reset), .out(short_trg));
	always @(posedge clock127) begin
		if (reset) begin
			long_trg <= 0;
			trg <= 0;
			trg_inv <= 1;
		end else begin
			if (short_trg) begin
				trg <= 1;
				trg_inv <= 0;
			end else begin
				trg <= 0;
				trg_inv <= 1;
			end
			if (other_revo_stream127) begin
				long_trg <= 1;
			end else begin
				long_trg <= 0;
			end
		end
	end
	// ----------------------------------------------------------------------
	wire data;
	wire word_clock;
	reg [7:0] word;
	wire [7:0] word_null = 8'b00000000;
	wire [7:0] word_trg  = 8'b11001100;
	wire pll_oserdes_locked;
	ocyrus_single8 #(.WIDTH(8), .PERIOD(7.86), .DIVIDE(2), .MULTIPLY(16)) mylei (.clock_in(clock127), .reset(reset), .word_clock_out(word_clock), .word_in(word), .D_out(data), .T_out(), .locked(pll_oserdes_locked));
	wire reset3 = reset1 | reset2 | ~pll_oserdes_locked;
	wire trg_again;
	ssynchronizer_pnp barry (.clock1(clock127), .clock2(word_clock), .reset(reset), .in1(trg), .out2(trg_again));
	always @(posedge word_clock) begin
		if (reset3) begin
			word <= word_null;
		end else begin
			if (trg_again) begin
				word <= word_trg;
			end else begin
				word <= word_null;
			end
		end
	end
	// ----------------------------------------------------------------------
	wire clock127_oddr;
	ODDR2 doughnut127 (.C0(clock127), .C1(clock127b), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(reset), .S(1'b0), .Q(clock127_oddr));
	wire clock127_encoded_trg_oddr;
	ODDR2 doughnut2 (.C0(clock127), .C1(clock127b), .CE(trg_inv),  .D0(1'b0), .D1(1'b1), .R(reset), .S(1'b0), .Q(clock127_encoded_trg_oddr));
//	wire clock509a, clock509b;
//	BUFG a (.I(raw_clock509a), .O(clock509a));
//	BUFG b (.I(raw_clock509b), .O(clock509b));
//	wire clock509_oddr;
//	ODDR2 doughnut509 (.C0(raw_clock509a), .C1(raw_clock509b), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(reset), .S(1'b0), .Q(clock509_oddr));
	if (0) begin
		// test performance
		OBUFDS ack12 (.I(rawtrg), .O(ack12_p), .OB(ack12_n));
//		OBUFDS trg36 (.I(clock509_oddr), .O(trg36_p), .OB(trg36_n));
		OBUFDS rsv54 (.I(trg), .O(rsv54_p), .OB(rsv54_n));
		OBUFDS clk78 (.I(clock127_oddr), .O(clk78_p), .OB(clk78_n));
	end else if (0) begin
		// miscellaneous debug/troubleshoot
//		OBUFDS ack12 (.I(long_trg), .O(ack12_p), .OB(ack12_n));
//		OBUFDS ack12 (.I(select4[3]), .O(ack12_p), .OB(ack12_n));
//		OBUFDS trg36 (.I(select4[2]), .O(trg36_p), .OB(trg36_n));
//		OBUFDS rsv54 (.I(select4[1]), .O(rsv54_p), .OB(rsv54_n));
//		OBUFDS clk78 (.I(select4[0]), .O(clk78_p), .OB(clk78_n));
//		OBUFDS rsv54 (.I(rawtrg), .O(rsv54_p), .OB(rsv54_n));
//		OBUFDS supercool1 (.I(clock127_oddr), .O(clk78_p), .OB(clk78_n));
//		OBUFDS supercool1 (.I(0'b0), .O(clk78_p), .OB(clk78_n));
//		OBUFDS supercool2 (.I(select2[1]), .O(trg36_p), .OB(trg36_n));
//		OBUFDS supercool2 (.I(trg), .O(trg36_p), .OB(trg36_n));
//		OBUFDS out1 (.I(clock127_encoded_trg_oddr2), .O(out1_p), .OB(out1_n));
//		OBUFDS out1 (.I(select2[1]), .O(out1_p), .OB(out1_n));
//		OBUFDS outa (.I(clock127_oddr), .O(outa_p), .OB(outa_n));
//		OBUFDS outa (.I(data), .O(outa_p), .OB(outa_n));
//		OBUFDS outa (.I(rawtrg), .O(outa_p), .OB(outa_n));
//		OBUFDS outa (.I(clock509_oddr), .O(outa_p), .OB(outa_n));
	end else begin
		// normal operation
		OBUFDS ack12 (.I(long_trg), .O(ack12_p), .OB(ack12_n));
		OBUFDS trg36 (.I(clock127_encoded_trg_oddr), .O(trg36_p), .OB(trg36_n));
		OBUFDS rsv54 (.I(data), .O(rsv54_p), .OB(rsv54_n));
		OBUFDS clk78 (.I(clock127_oddr), .O(clk78_p), .OB(clk78_n));
		OBUFDS out1 (.I(rawtrg), .O(out1_p), .OB(out1_n));
		OBUFDS outa (.I(trg), .O(outa_p), .OB(outa_n));
	end
	assign led_7 = pll_oserdes_locked;
	assign led_6 = pll_127_127_locked;
	assign led_5 = reset;
	assign led_4 = phase_locked;
	assign led_3 = select4[3];
	assign led_2 = select4[2];
	assign led_1 = select4[1];
	assign led_0 = select4[0];
endmodule

module mything_tb;
	// Inputs
	reg local_clock50_in_p = 0;
	reg local_clock50_in_n = 1;
	reg remote_clock509_in_p = 0;
	reg remote_clock509_in_n = 1;
	reg local_clock509_in_p = 0;
	reg local_clock509_in_n = 1;
	reg remote_revo_in_p = 0;
	reg remote_revo_in_n = 1;
	// Outputs
	wire clk78_p;
	wire clk78_n;
	wire trg36_p;
	wire trg36_n;
	wire out1_p;
	wire out1_n;
	wire outa_p;
	wire outa_n;
	wire rsv54_p;
	wire rsv54_n;
	reg lemo = 0;
	wire ack12_p;
	wire ack12_n;
	wire led_revo;
	wire led_rfclock;
	wire driven_high;
	reg clock_select = 0;
	wire led_0;
	wire led_1;
	wire led_2;
	wire led_3;
	wire led_4;
	wire led_5;
	wire led_6;
	wire led_7;
	// Instantiate the Unit Under Test (UUT)
	mza_test032_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea uut (
		.local_clock50_in_p(local_clock50_in_p), .local_clock50_in_n(local_clock50_in_n),
		.remote_clock509_in_p(remote_clock509_in_p), .remote_clock509_in_n(remote_clock509_in_n),
		.remote_revo_in_p(remote_revo_in_p), .remote_revo_in_n(remote_revo_in_n),
		.clk78_p(clk78_p), .clk78_n(clk78_n),
		.trg36_p(trg36_p), .trg36_n(trg36_n),
		.rsv54_p(rsv54_p), .rsv54_n(rsv54_n),
		.ack12_p(ack12_p), .ack12_n(ack12_n),
		.out1_p(out1_p), .out1_n(out1_n),
		.outa_p(outa_p), .outa_n(outa_n),
		.lemo(lemo),
		.led_revo(l_p),
		.led_rfclock(l_n),
		.clock_select(clock_select),
		.driven_high(driven_high),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
	wire raw_recovered_revo;
	assign raw_recovered_revo = clk78_p ^ trg36_p;
	reg recovered_revo = 0;
	initial begin
		// Initialize Inputs
		local_clock50_in_p <= 0; local_clock50_in_n <= 1;
		remote_clock509_in_p <= 0; remote_clock509_in_n <= 1;
		local_clock509_in_p <= 0; local_clock509_in_n <= 1;
		remote_revo_in_p <= 0; remote_revo_in_n <= 1;
		recovered_revo <= 0; lemo <= 0;
		clock_select <= 0;
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
		local_clock509_in_p <= ~local_clock509_in_p; local_clock509_in_n <= ~local_clock509_in_n;
	end
	always begin
		#1;
		remote_clock509_in_p <= ~remote_clock509_in_p; remote_clock509_in_n <= ~remote_clock509_in_n;
	end
	always begin
		#10;
		local_clock50_in_p <= ~local_clock50_in_p; local_clock50_in_n <= ~local_clock50_in_n;
	end
	always @(negedge clk78_p) begin
		recovered_revo <= raw_recovered_revo;
	end
endmodule

module mza_test032_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea_top (
	input clock50_p, clock50_n,
	output a_p, a_n,
	output b_p, b_n,
	output c_p, c_n,
	output d_p, d_n,
	output e_p, e_n,
	output f_p, f_n,
	input g_n, output g_p,
	input h_p, h_n,
	input j_p, j_n,
	input k_p, k_n,
	output l_p, l_n,
	input lemo,
	output led_0, output led_1, output led_2, output led_3,
	output led_4, output led_5, output led_6, output led_7
);
	mza_test032_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea mything (
		.local_clock50_in_p(clock50_p), .local_clock50_in_n(clock50_n),
		.local_clock509_in_p(j_p), .local_clock509_in_n(j_n),
		.remote_clock509_in_p(k_p), .remote_clock509_in_n(k_n),
		.remote_revo_in_p(h_p), .remote_revo_in_n(h_n),
		.ack12_p(a_p), .ack12_n(a_n),
		.trg36_p(f_p), .trg36_n(f_n),
		.rsv54_p(c_p), .rsv54_n(c_n),
		.clk78_p(d_p), .clk78_n(d_n),
		.out1_p(e_p), .out1_n(e_n),
		.outa_p(b_p), .outa_n(b_n),
		.lemo(lemo),
		.led_revo(l_n),
		.led_rfclock(l_p),
		.driven_high(g_p), .clock_select(g_n),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

