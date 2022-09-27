// written 2021-12-14 by mza
// based on mza-test054.palimpsest.cylon.althea.revB.v
// last updated 2022-09-27 by mza

`define althea_revA
`include "lib/generic.v"
`include "lib/RAM8.v"
//`include "lib/RAM.sv" // ise does not and will not support systemverilog
`include "lib/plldcm.v"
`include "lib/serdes_pll.v"
`include "lib/half_duplex_rpi_bus.v"
`include "lib/sequencer.v"
`include "lib/reset.v"
`include "lib/edge_to_pulse.v"

module top #(
	parameter OSERDES_DATA_WIDTH = 8,
	parameter LOG2_OF_OSERDES_DATA_WIDTH = $clog2(OSERDES_DATA_WIDTH),
	parameter LOG2_OF_OSERDES_EXTENDED_DATA_WIDTH = $clog2(64),
	parameter TESTBENCH = 0,
	parameter COUNTER_PICKOFF = TESTBENCH ? 6 : $clog2(2500000) - LOG2_OF_OSERDES_DATA_WIDTH, // 25 MHz / 2^23 ~ 23 Hz
	parameter COUNTER100_BIT_PICKOFF = TESTBENCH ? 5 : 23,
	parameter COUNTERWORD_BIT_PICKOFF = TESTBENCH ? 5 : 23
) (
	input clock50_p, clock50_n,
	inout [5:0] coax,
//	input [2:0] rot,
	output [12:1] signal,
	output [7:0] led,
	output [3:0] coax_led
);
	// PLL_ADV VCO range is 400 MHz to 1080 MHz
	localparam PERIOD = 10.0;
	//localparam MULTIPLY = 9; // 900 MHz
	//localparam DIVIDE = 1; // 900 MHz
	//localparam EXTRA_DIVIDE = 3; // 300 MHz
	//localparam MULTIPLY = 8; // 800 MHz
	//localparam DIVIDE = 2; // 400 MHz
	//localparam EXTRA_DIVIDE = 16; // 25 MHz
	localparam MULTIPLY = 8; // 800 MHz bit_clock
	localparam DIVIDE = 2; // 400 MHz bit_clock; 50 MHz word_clock
	//localparam EXTRA_DIVIDE = 7; // 142.857143 MHz (7ns bit time); 
	//localparam EXTRA_DIVIDE = 16; // 25 MHz bit_clock (40ns bit time); 3.125 MHz word_clock
	localparam EXTRA_DIVIDE = 3; // 133.33 MHz bit_clock (7.5ns bit time); 16.67 MHz word_clock
	//localparam EXTRA_DIVIDE = 2; // 200 MHz bit_clock (5ns bit time); 25 MHz word_clock
	localparam SCOPE = "BUFPLL"; // "GLOBAL" (400 MHz), "BUFIO2" (525 MHz), "BUFPLL" (1080 MHz)
	reg [7:0] pattern [12:1];
	wire [7:0] null = 0;
	wire [7:0] pat = 8'b10000000;
	wire [3:0] status4;
	wire [7:0] status8;
	wire reset;
	assign reset = 0;
	reg [7:0] sync_out_word_alternate = 0;
	genvar i;
	reg [COUNTER_PICKOFF:0] counter = 0;
	wire word_clock;
	wire reset_word;
	always @(posedge word_clock) begin
		if (reset_word) begin
			counter <= 0;
		end else begin
			counter <= counter + 1'b1;
		end
	end
	always @(posedge word_clock) begin
//		for (i=1; i<13; i=i+1) begin : clear_pattern
		pattern[1] <= null;
		pattern[2] <= null;
		pattern[3] <= null;
		pattern[4] <= null;
		pattern[5] <= null;
		pattern[6] <= null;
		pattern[7] <= null;
		pattern[8] <= null;
		pattern[9] <= null;
		pattern[10] <= null;
		pattern[11] <= null;
		pattern[12] <= null;
		sync_out_word_alternate <= null;
//		end
		if (reset_word) begin
		end else begin
			if (counter==1) begin
				sync_out_word_alternate <= pat;
				pattern[1] <= pat;
			end else if (counter==2) begin
				pattern[2] <= pat;
			end else if (counter==3) begin
				pattern[3] <= pat;
			end else if (counter==4) begin
				pattern[4] <= pat;
			end else if (counter==5) begin
				pattern[5] <= pat;
			end else if (counter==6) begin
				pattern[6] <= pat;
			end else if (counter==7) begin
				pattern[7] <= pat;
			end else if (counter==8) begin
				pattern[8] <= pat;
			end else if (counter==9) begin
				pattern[9] <= pat;
			end else if (counter==10) begin
				pattern[10] <= pat;
			end else if (counter==11) begin
				pattern[11] <= pat;
			end else if (counter==12) begin
				pattern[12] <= pat;
			end
		end
	end
	wire pll_oserdes_locked;
	// ----------------------------------------------------------------------
	wire clock100;
	wire clock50_locked;
	wire reset100;
	if (1) begin // on boards with 50 MHz oscillator
		wire clock50_raw;
		IBUFGDS mybuf50_raw1 (.I(clock50_p), .IB(clock50_n), .O(clock50_raw));
		wire clock100_raw;
		simpledcm_CLKGEN #(.MULTIPLY(2), .DIVIDE(1), .PERIOD(20.0)) mydcm50 (.clockin(clock50_raw), .reset(reset), .clockout(clock100_raw), .clockout180(), .locked(clock50_locked));
		BUFG mybuf50_raw2 (.I(clock100_raw), .O(clock100));
		reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset100_wait4pll (.reset_input(reset), .pll_locked_input(clock50_locked), .clock_input(clock100), .reset_output(reset100));
	end else begin // on boards with 100 MHz oscillator
		wire clock100_locked;
//		IBUFGDS mybuf0 (.I(clock100_p), .IB(clock100_n), .O(clock100));
		dummy_dcm_diff_input lollipop (.clock_p(clock100_p), .clock_n(clock100_n), .reset(reset), .clock_out(clock100), .clock_locked(clock100_locked));
		reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTER100_BIT_PICKOFF)) reset100_wait4pll (.reset_input(reset), .pll_locked_input(clock100_locked), .clock_input(clock100), .reset_output(reset100));
	end
	// ----------------------------------------------------------------------
	reset_wait4pll #(.COUNTER_BIT_PICKOFF(COUNTERWORD_BIT_PICKOFF)) resetword_wait4pll (.reset_input(reset100), .pll_locked_input(pll_oserdes_locked), .clock_input(word_clock), .reset_output(reset_word));
	// ----------------------------------------------------------------------
	// the order here is 12, 11, 10, 6, 5, 4, 9, 8, 7, 3, 2, 1
	wire [7:0] dummy = 0;
	wire strobe_is_alignedA, strobe_is_alignedB, strobe_is_alignedC, strobe_is_alignedD;
	ocyrus_triacontahedron8_split_12_6_6_4_2_D0input #(
		.BIT_DEPTH(8), .PERIOD(PERIOD), .MULTIPLY(MULTIPLY), .DIVIDE(DIVIDE), .EXTRA_DIVIDE(EXTRA_DIVIDE), .SCOPE(SCOPE)
	) orama (
		.clock_in(clock100), .reset(reset100),
		.word_A11_in(dummy), .word_A10_in(dummy), .word_A09_in(dummy), .word_A08_in(dummy), .word_A07_in(dummy), .word_A06_in(dummy),
		.word_A05_in(dummy), .word_A04_in(dummy), .word_A03_in(dummy), .word_A02_in(dummy), .word_A01_in(dummy), .word_A00_in(dummy),
		.word_B5_in(pattern[12]), .word_B4_in(pattern[11]), .word_B3_in(pattern[10]), .word_B2_in(pattern[6]), .word_B1_in(pattern[5]), .word_B0_in(pattern[4]),
		.word_C5_in(pattern[9]), .word_C4_in(pattern[8]), .word_C3_in(pattern[7]), .word_C2_in(pattern[3]), .word_C1_in(pattern[2]), .word_C0_in(pattern[1]),
		.word_D3_in(dummy), .word_D2_in(dummy), .word_D1_in(dummy), .word_D0_out(),
		.word_E1_in(dummy), .word_E0_in(sync_out_word_alternate),
		.word_clockA_out(word_clock), .word_clockB_out(), .word_clockC_out(), .word_clockD_out(), .word_clockE_out(),
		.A11_out(), .A10_out(), .A09_out(), .A08_out(), .A07_out(), .A06_out(),
		.A05_out(), .A04_out(), .A03_out(), .A02_out(), .A01_out(), .A00_out(),
		.B5_out(signal[12]), .B4_out(signal[11]), .B3_out(signal[10]), .B2_out(signal[6]), .B1_out(signal[5]), .B0_out(signal[4]),
		.C5_out(signal[9]), .C4_out(signal[8]), .C3_out(signal[7]), .C2_out(signal[3]), .C1_out(signal[2]), .C0_out(signal[1]),
		.D3_out(coax[3]), .D2_out(coax[2]), .D1_out(coax[1]), .D0_in(coax[0]),
		.E1_out(coax[5]), .E0_out(coax[4]),
		.strobe_is_alignedA(strobe_is_alignedA), .strobe_is_alignedB(strobe_is_alignedB), .strobe_is_alignedC(strobe_is_alignedC), .strobe_is_alignedD(strobe_is_alignedD),
		.locked(pll_oserdes_locked)
	);
	// ----------------------------------------------------------------------
	if (0) begin
		assign status4 = 0;
		assign status8 = 0;
	end else begin
		assign status4[3] = ~pll_oserdes_locked;
		assign status4[2] = 0;
		assign status4[1] = 0;
		assign status4[0] = 0;
		// status8:
		assign status8[7] = ~clock50_locked;
		assign status8[6] = reset100;
		assign status8[5] = ~pll_oserdes_locked;
		assign status8[4] = reset_word;
		assign status8[3] = ~strobe_is_alignedA;
		assign status8[2] = ~strobe_is_alignedB;
		assign status8[1] = ~strobe_is_alignedC;
		assign status8[0] = ~strobe_is_alignedD;
	end
	assign coax_led = status4;
	assign led = status8;
	initial begin
		#100;
		//$display("%d banks", NUMBER_OF_BANKS);
	end
endmodule

module top_tb;
	localparam HALF_PERIOD_OF_CONTROLLER = 1;
	localparam HALF_PERIOD_OF_PERIPHERAL = 10; // 50 MHz
	localparam NUMBER_OF_PERIODS_OF_CONTROLLER_IN_A_DELAY = 1;
	localparam NUMBER_OF_PERIODS_OF_CONTROLLER_WHILE_WAITING_FOR_ACK = 2000;
	reg clock = 0;
	reg clock50_p = 0;
	reg clock50_n = 1;
	wire [5:0] coax;
	wire [3:0] coax_led;
	wire [7:0] led;
	wire a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p, b_n, b_p, e_n, e_p;
	wire m_p, m_n, l_p, l_n, j_p, j_n, g_p, g_n, k_p, k_n, h_p, h_n;
	wire z, y, x, w, v, u;
	wire n, p, q, r, s, t;
	wire [12:1] signal;
	top #(
		.TESTBENCH(1)
	) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n),
		.coax(coax),
		.signal(signal),
		//.diff_pair_left({ a_n, a_p, c_n, c_p, d_n, d_p, f_n, f_p, b_n, b_p, e_n, e_p }),
		//.diff_pair_right({ m_p, m_n, l_p, l_n, j_p, j_n, g_p, g_n, k_p, k_n, h_p, h_n }),
		//.single_ended_left({ z, y, x, w, v, u }),
		//.single_ended_right({ n, p, q, r, s, t }),
		.led(led), .coax_led(coax_led)
	);
	initial begin
		// inject global reset
		#512; // wait for reset100
		#512; // wait for reset125
		//#512; // wait for reset100
		//#512; // wait for reset125
		//$finish;
	end
	always begin
		#HALF_PERIOD_OF_PERIPHERAL;
		clock50_p <= #1.5 ~clock50_p;
		clock50_n <= #2.5 ~clock50_n;
	end
	always begin
		#HALF_PERIOD_OF_CONTROLLER;
		clock <= #0.625 ~clock;
	end
endmodule

module myalthea #(
	) (
	input clock50_p, clock50_n,
	inout coax4,
//	inout coax3,
//	inout coax0,
	// other IOs:
//	output rpi_gpio2_i2c1_sda, // ack_valid
//	input rpi_gpio3_i2c1_scl, // register_select
//	input rpi_gpio4_gpclk0, // enable
//	input rpi_gpio5, // read
	// 16 bit bus:
//	inout rpi_gpio6_gpclk2, rpi_gpio7_spi_ce1, rpi_gpio8_spi_ce0, rpi_gpio9_spi_miso,
//	inout rpi_gpio10_spi_mosi, rpi_gpio11_spi_sclk, rpi_gpio12, rpi_gpio13,
//	inout rpi_gpio14, rpi_gpio15, rpi_gpio16, rpi_gpio17,
//	inout rpi_gpio18, rpi_gpio19, rpi_gpio20, rpi_gpio21,
	// diff-pair IOs (toupee connectors):
	a_p, b_p, c_p, d_p, e_p, f_p, // rotated
	g_p, h_p, j_p, k_p, l_p, m_p,
//	a_n, b_n, c_n, d_n, e_n, f_n, // flipped
//	g_n, h_n, j_n, k_n, l_n, m_n, 
	// single-ended IOs (toupee connectors):
//	n, p, q, r, s, t,
//	u, v, w, x, y, z,
	// other IOs:
	//input [2:0] rot
	output [7:0] led//,
//	output [3:0] coax_led
);
	wire [3:0] internal_coax_led;
	wire [7:0] internal_led;
	assign led = internal_led;
	//assign coax_led = internal_coax_led;
	wire [5:0] diff_pair_left;
	assign { a_n, c_n, d_n, f_n, b_n, e_n } = diff_pair_left; // flipped
	wire coax5, coax3, coax2, coax1, coax0;
	wire [12:1] signal;
	//assign { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p } = signal;
	//assign { t, s, r, q, p, n, u, v, w, x, y, z } = indicator;
	assign { b_p, d_p, f_p, h_p, l_p, m_p, a_p, c_p, e_p, g_p, j_p, k_p } = signal;
//	assign { t, s, r, q, p, n, u, v, w, x, y, z } = indicator;
	top #(
		.TESTBENCH(0)
	) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n),
		.coax({coax5, coax4, coax3, coax2, coax1, coax0}),
		.signal(signal),
//		.diff_pair_left(diff_pair_left),
//		.diff_pair_right_p({ m_p, k_p, l_p, j_p, h_p, g_p }),
//		.diff_pair_right_n({ m_n, k_n, l_n, j_n, h_n, g_n }),
//		.single_ended_left({ z, y, x, w, v, u }),
//		.single_ended_right({ n, p, q, r, s, t }),
//		.rot(rot),
		.led(internal_led),
		.coax_led(internal_coax_led)
	);
endmodule

