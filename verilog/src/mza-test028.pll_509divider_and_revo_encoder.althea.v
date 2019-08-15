`timescale 1ns / 1ps
// written 2019-08-14 by mza
// last updated 2019-08-14 by mza

// todo: auto-fallover for missing 509; and auto-fake revo when that happens

module mza_test028_pll_509divider_and_revo_encoder_althea (
	input k_p,
	input k_n,
	input m_p,
	input m_n,
	output d_p,
	output d_n,
	output a_p,
	output a_n,
	output b_p,
	output b_n,
	output e_p,
	output e_n,
	output led_0,
	output led_1,
	output led_2,
	output led_3,
	output led_4,
	output led_5,
	output led_6,
	output led_7
);
	wire clock509;
	IBUFGDS input_clock_instance (.I(k_p), .IB(k_n), .O(clock509));
	//assign clock509 = lemo;
	//reg [WIDTH-1:0] word;
	//wire [7:0] led_byte;
	//assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = led_byte;
	//assign led_byte = word;
	//reg [31:0] counter = 0;
	reg reset = 1;
	reg [12:0] reset_counter = 0;
	always @(posedge clock509) begin
		if (reset) begin
			if (reset_counter[10]) begin
				reset <= 0;
			end
		end
		reset_counter <= reset_counter + 1;
	end
	wire clock127;
	wire clock127b;
	wire locked;
	//pll pll_instance (.CLK_IN1_P(k_p), .CLK_IN1_N(k_n), .CLK_OUT1(clock127), .RESET(1'b0), .LOCKED(led_0));
	//plldcm plldcm_instance #(.divide(4), .multiply(1), .period("1.965") (.clockin(clock509), .clockout(clock127), .clockout180(clock127b), .reset(reset), .locked(led_0));
	plldcm #(.overall_divide(2), .pllmultiply(4), .plldivide(8), .pllperiod(1.965), .dcmmultiply(2), .dcmdivide(2), .dcmperiod("7.86")) myplldcm (.clockin(clock509), .clockout(clock127), .clockout180(clock127b), .reset(reset), .locked(locked));
	wire rawtrg;
	IBUFGDS trigger_input_instance (.I(m_p), .IB(m_n), .O(rawtrg));
	reg trg = 0;
	always @(posedge clock127) begin
		if (trg) begin
			trg <= 0;
		end else begin
			if (rawtrg) begin
				trg <= 1;
			end
		end
	end
	wire clock127oddr1;
	wire clock127oddr2;
	ODDR2 doughnut1 (.C0(clock127), .C1(clock127b), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(1'b0), .S(1'b0), .Q(clock127oddr1));
	OBUFDS supercool (.I(clock127oddr1), .O(a_p), .OB(a_n));
	ODDR2 doughnut2 (.C0(clock127), .C1(clock127b), .CE(~trg),  .D0(1'b0), .D1(1'b1), .R(1'b0), .S(1'b0), .Q(clock127oddr2));
	//OBUFDS grouch1 (.I(trg), .O(d_p), .OB(d_n));
	OBUFDS grouch2 (.I(clock127oddr2), .O(d_p), .OB(d_n));
	assign led_7 = reset;
	assign led_6 = 0;
	assign led_5 = 0;
	assign led_4 = trg;
	assign led_3 = 0;
	assign led_2 = 0;
	assign led_1 = 0;
	assign led_0 = locked;
	wire clock127oddr3;
	ODDR2 doughnut3 (.C0(clock127), .C1(clock127b), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(1'b0), .S(1'b0), .Q(clock127oddr3));
	OBUFDS outa (.I(clock127oddr3), .O(b_p), .OB(b_n));
	OBUFDS out1 (.I(trg), .O(e_p), .OB(e_n));
endmodule

