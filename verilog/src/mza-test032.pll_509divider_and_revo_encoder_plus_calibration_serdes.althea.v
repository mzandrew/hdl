`timescale 1ns / 1ps
// written 2019-09-09 by mza
// based partly off mza-test029
// last updated 2019-09-09 by mza

// todo: auto-fallover for missing 509; and auto-fake revo when that happens

module mza_test032_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea (
	input local_clock50_in_p, local_clock50_in_n,
	input local_clock509_in_p, local_clock509_in_n,
	input remote_clock509_in_p, remote_clock509_in_n,
	input remote_revo_in_p, remote_revo_in_n,
	output clock127_out_p, clock127_out_n,
	output trg_out_p, trg_out_n,
	output out1_p, out1_n,
	output outa_p, outa_n,
	output rsv_p, rsv_n,
	input lemo,
	input ack_p, ack_n,
	output reg led_revo,
	output reg led_rfclock,
	output driven_high,
	input clock_select,
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	wire ack;
	IBUFGDS ackbuf (.I(ack_p), .IB(ack_n), .O(ack));
	// ----------------------------------------------------------------------
	wire remote_clock509;
	wire local_clock509;
	wire clock509;
	IBUFGDS remote_input_clock509_instance (.I(remote_clock509_in_p), .IB(remote_clock509_in_n), .O(remote_clock509));
	IBUFGDS local_input_clock509_instance (.I(local_clock509_in_p), .IB(local_clock509_in_n), .O(local_clock509));
	assign driven_high = 1;
//	BUFGMUX #(.CLK_SEL_TYPE("ASYNC")) clock_selection_instance (.I0(remote_clock509), .I1(local_clock509), .S(clock_select), .O(clock509));
	assign clock509 = remote_clock509;
	// ----------------------------------------------------------------------
	reg reset = 1;
	reg [8:0] reset_counter = 0;
	wire local_clock50;
	IBUFGDS local_input_clock50_instance (.I(local_clock50_in_p), .IB(local_clock50_in_n), .O(local_clock50));
	always @(posedge local_clock50) begin
		if (reset) begin
			led_revo <= 0;
			led_rfclock <= 0;
		end
		if (reset_counter[7]) begin
			reset <= 0;
		end
		reset_counter <= reset_counter + 1'b1;
	end
	// ----------------------------------------------------------------------
	wire rawclock127_0;
	wire rawclock127_90;
	wire rawclock127_180;
	wire rawclock127_270;
	wire locked1;
	simplepll_BASE #(.overall_divide(2), .multiply(4), .period(1.965), .compensation("INTERNAL"),
		.divide0(8), .divide1(8), .divide2(8), .divide3(8), .divide4(2), .divide5(2),
		.phase0(0.0), .phase1(90.0), .phase2(180.0), .phase3(270.0), .phase4(0.0), .phase5(0.0)
	) mypll (.clockin(clock509), .reset(reset), .locked(locked1),
		.clock0out(rawclock127_0), .clock1out(rawclock127_90),
		.clock2out(rawclock127_180), .clock3out(rawclock127_270),
		.clock4out(), .clock5out()
	);
	// ----------------------------------------------------------------------
	wire rawtrg;
	IBUFDS trigger_input_instance (.I(remote_revo_in_p), .IB(remote_revo_in_n), .O(rawtrg));
	wire revo_stream_clock;
	wire [3:0] revo_stream127;
	reg [1:0] select = 0;
	iserdes_single4 revo_iserdes (.sample_clock(clock509), .data_in(rawtrg), .reset(reset), .word_clock(revo_stream_clock), .word_out(revo_stream127));
	wire [3:0] pulse_revo_stream127;
	edge_to_pulse #(.WIDTH(4)) midge (.clock(revo_stream_clock), .in(revo_stream127), .reset(reset), .out(pulse_revo_stream127));
	always @(posedge revo_stream_clock) begin
		if (reset) begin
			select <= 0;
		end else begin
			case (pulse_revo_stream127)
				4'b1000 : begin select <= 2'b00; end
				4'b0100 : begin select <= 2'b01; end
				4'b0010 : begin select <= 2'b10; end
				4'b0001 : begin select <= 2'b11; end
				default : begin end
			endcase
		end
	end
	wire clock127_0s;
	wire clock127_1s;
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_0s (.I0(rawclock127_0),   .I1(rawclock127_90),  .S(select[0]), .O(clock127_0s));
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_1s (.I0(rawclock127_180), .I1(rawclock127_270), .S(select[0]), .O(clock127_1s));
	wire clock127;
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_sx (.I0(clock127_0s), .I1(clock127_1s), .S(select[1]), .O(clock127));
	wire clock127b;
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_b (.I0(clock127_0s), .I1(clock127_1s), .S(~select[1]), .O(clock127b));
	// ----------------------------------------------------------------------
	reg trg = 0;
	reg [3:0] other_revo_stream127;
	always @(posedge clock127) begin
		if (reset) begin
			trg <= 0;
			other_revo_stream127 <= 0;
		end else begin
			if (other_revo_stream127) begin
				trg <= 1;
			end else begin
				trg <= 0;
			end
			other_revo_stream127 <= revo_stream127;
		end
	end

//	reg [3:0] phase;
//	reg trg, trg_inv1, should_trg;
//	parameter TRGSTREAM_WIDTH = 8'd16;
//	parameter TRG_MAX_DURATION = 8'd8;
//	reg [TRGSTREAM_WIDTH-1:0] trgstream509;
//	wire [TRGSTREAM_WIDTH-1:0] trgstream254;
//	reg [TRGSTREAM_WIDTH-TRG_MAX_DURATION-1:0] upper;
//	reg [TRG_MAX_DURATION-1:0] lower;
//	reg u, l;
//	wire rawtrg, rawtrg2;
//	always @(posedge clock509) begin
//		if (reset) begin
//			trgstream509 <= 0;
//		end else begin
//			trgstream509 <= { trgstream509[TRGSTREAM_WIDTH-2:0], rawtrg2 };
//		end
//	end
//	//ssynchronizer #(.WIDTH(TRGSTREAM_WIDTH)) ts_sync (.clock1(clock509), .clock2(clock254), .reset(reset), .in1(trgstream509), .out2(trgstream254));
//	//ssynchronizer_pnppp #(.WIDTH(TRGSTREAM_WIDTH)) ts_sync (.clock1(clock509), .clock2(clock254), .reset(reset), .in1(trgstream509), .out2(trgstream254));
//	//ssynchronizer_90_270 #(.WIDTH(TRGSTREAM_WIDTH)) ts_sync (.clock1(clock509), .clock1_90(clock254_90), .clock1_270(clock254_270), .clock2(clock254), .reset(reset), .in1(trgstream509), .out2(trgstream254));
//	//assign rawtrg2 = rawtrg;
//	asynchronizer rawtrg_sync (.clock(clock509), .reset(reset), .async_in(rawtrg), .sync_out(rawtrg2));
//	always @(posedge clock127) begin
//		if (reset) begin
//			phase <= 4'b0001;
//			trg <= 0;
//			trg_inv1 <= 1;
//			should_trg <= 0;
//			upper <= 0;
//			lower <= 0;
//			u <= 0;
//			l <= 0;
//		end else begin
//			if (phase == 4'b0001) begin
//				//led_revo <= 0;
//				if (should_trg) begin
//					trg <= 1;
//					trg_inv1 <= 0;
//				end else begin
//					trg <= 0;
//					trg_inv1 <= 1;
//				end
//				//if (trgstream[TRGSTREAM_WIDTH-1:TRG_MAX_DURATION] == 0 && trgstream[TRG_MAX_DURATION-1:0] != 0) begin
//				upper <= trgstream254[TRGSTREAM_WIDTH-1:TRG_MAX_DURATION];
//				lower <= trgstream254[TRG_MAX_DURATION-1:0];
//			end else if (phase == 4'b0010) begin
//				u <= |upper;
//				l <= |lower;
//				should_trg <= 0;
//			end else if (phase == 4'b0100) begin
//				if (l) begin
//					should_trg <= 1;
//				end
//			end else begin
//				if (u) begin
//					should_trg <= 0;
//				end
////				if (l) begin
////					if (u) begin
////						should_trg <= 0;
////					end else begin
////						should_trg <= 1;
////					end
////				end
//			end
//			phase <= { phase[2:0], phase[3] };
//		end
//	end

	// ----------------------------------------------------------------------
	wire locked2;
	assign led_7 = locked2;
	assign led_6 = locked1;
	assign led_5 = reset;
	assign led_4 = 0;//trg;
	assign led_3 = revo_stream127[3];
	assign led_2 = revo_stream127[2];
	assign led_1 = revo_stream127[1];
	assign led_0 = revo_stream127[0];
	// ----------------------------------------------------------------------
	wire data;
	wire word_clock;
	reg [7:0] word;
	wire [7:0] word_null = 8'b11000000;
	wire [7:0] word_trg  = 8'b00111111;
	ocyrus_single8 #(.WIDTH(8), .PERIOD(7.86), .DIVIDE(2), .MULTIPLY(16)) mylei (.clock_in(clock127), .reset(reset), .word_clock_out(word_clock), .word_in(word), .D_out(data), .T_out(), .locked(locked2));
	always @(posedge word_clock) begin
		if (reset) begin
			word <= word_null;
		end else begin
			if (trg) begin
				word <= word_trg;
			end else begin
				word <= word_null;
			end
		end
	end
	// ----------------------------------------------------------------------
	OBUFDS rsv (.I(data), .O(rsv_p), .OB(rsv_n));
//	OBUFDS rsv (.I(0), .O(rsv_p), .OB(rsv_n));
	wire clock127_oddr1;
	ODDR2 doughnut0 (.C0(clock127), .C1(clock127b), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(reset), .S(1'b0), .Q(clock127_oddr1));
	OBUFDS supercool1 (.I(clock127_oddr1), .O(clock127_out_p), .OB(clock127_out_n));
//	OBUFDS supercool1 (.I(0'b0), .O(clock127_out_p), .OB(clock127_out_n));
//	wire clock127_oddr2;
//	ODDR2 doughnut1 (.C0(clock127), .C1(clock127b), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(reset), .S(1'b0), .Q(clock127_oddr2));
//	OBUFDS outa (.I(clock127_oddr2), .O(outa_p), .OB(outa_n));
//	OBUFDS outa (.I(data), .O(outa_p), .OB(outa_n));
//	OBUFDS outa (.I(rawtrg), .O(outa_p), .OB(outa_n));
//	OBUFDS outa (.I(select[0]), .O(outa_p), .OB(outa_n));
	OBUFDS outa (.I(revo_stream127[0]), .O(outa_p), .OB(outa_n));
//	wire clock127_encoded_trg_oddr1;
//	ODDR2 doughnut2 (.C0(clock127), .C1(clock127b), .CE(trg_inv1),  .D0(1'b0), .D1(1'b1), .R(reset), .S(1'b0), .Q(clock127_encoded_trg_oddr1));
//	OBUFDS supercool2 (.I(clock127_encoded_trg_oddr1), .O(trg_out_p), .OB(trg_out_n));
//	OBUFDS supercool2 (.I(select[1]), .O(trg_out_p), .OB(trg_out_n));
	OBUFDS supercool2 (.I(trg), .O(trg_out_p), .OB(trg_out_n));
//	wire clock127_encoded_trg_oddr2;
//	ODDR2 doughnut3 (.C0(clock127), .C1(clock127b), .CE(trg_inv2),  .D0(1'b0), .D1(1'b1), .R(reset), .S(1'b0), .Q(clock127_encoded_trg_oddr2));
//	OBUFDS out1 (.I(clock127_encoded_trg_oddr2), .O(out1_p), .OB(out1_n));
//	OBUFDS out1 (.I(select[1]), .O(out1_p), .OB(out1_n));
	OBUFDS out1 (.I(pulse_revo_stream127[0]), .O(out1_p), .OB(out1_n));
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
	reg lemo = 0;
	reg ack_p = 0;
	reg ack_n = 0;
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
		.clock127_out_p(clock127_out_p), .clock127_out_n(clock127_out_n),
		.trg_out_p(trg_out_p), .trg_out_n(trg_out_n),
		.rsv_p(rsv_p), .rsv_n(rsv_n),
		.ack_p(ack_p), .ack_n(ack_n),
		.out1_p(out1_p), .out1_n(out1_n),
		.outa_p(outa_p), .outa_n(outa_n),
		.lemo(lemo),
		.led_revo(l_p),
		.led_rfclock(l_n),
		.clock_select(clock_select),
		.driven_high(driven_high),
		.led_0(led_0),
		.led_1(led_1),
		.led_2(led_2),
		.led_3(led_3),
		.led_4(led_4),
		.led_5(led_5),
		.led_6(led_6),
		.led_7(led_7)
	);
	wire raw_recovered_revo;
	assign raw_recovered_revo = clock127_out_p ^ trg_out_p;
	reg recovered_revo = 0;
	initial begin
		// Initialize Inputs
		local_clock50_in_p <= 0; local_clock50_in_n <= 1;
		remote_clock509_in_p <= 0; remote_clock509_in_n <= 1;
		local_clock509_in_p <= 0; local_clock509_in_n <= 1;
		remote_revo_in_p <= 0; remote_revo_in_n <= 1;
		recovered_revo <= 0; lemo <= 0; ack_p <= 0; ack_n <= 1;
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
	always @(negedge clock127_out_p) begin
		recovered_revo <= raw_recovered_revo;
	end
endmodule

module mza_test032_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea_top (
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
	input g_n, output g_p,
	output led_0, output led_1, output led_2, output led_3,
	output led_4, output led_5, output led_6, output led_7
);
	mza_test032_pll_509divider_and_revo_encoder_plus_calibration_serdes_althea mything (
		.local_clock50_in_p(clock50_p), .local_clock50_in_n(clock50_n),
		.local_clock509_in_p(j_p), .local_clock509_in_n(j_n),
		.remote_clock509_in_p(k_p), .remote_clock509_in_n(k_n),
		.remote_revo_in_p(h_p), .remote_revo_in_n(h_n),
		.clock127_out_p(d_p), .clock127_out_n(d_n),
		.trg_out_p(f_p), .trg_out_n(f_n),
		.rsv_p(c_p), .rsv_n(c_n),
		.ack_p(a_p), .ack_n(a_n),
		.out1_p(e_p), .out1_n(e_n),
		.outa_p(b_p), .outa_n(b_n),
		.lemo(lemo),
		.led_revo(l_p),
		.led_rfclock(l_n),
		.driven_high(g_p), .clock_select(g_n),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

