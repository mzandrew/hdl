`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2021-06-30 by mza

// the following message:
//Place:1073 - Placer was unable to create RPM[OLOGIC_SHIFT_RPMS] for the
//   component mytop/mylei/mylei0/osirus_m*****_D of type OLOGIC for the following
//   reason.
//   The reason for this issue:
//   Some of the logic associated with this structure is locked. This should cause
//   the rest of the logic to be locked.A problem was found at site OLOGIC_X11Y2
//   where we must place OLOGIC mytop/mylei/mylei0/osirus_secondary_D in order to
//   satisfy the relative placement requirements of this logic.  OLOGIC
//   mytop/mylei/mylei1/osirus_primary_D appears to already be placed there which
//   makes this design unplaceable.  The following components are part of this
//   structure:
//      OLOGIC   mytop/mylei/mylei0/osirus_primary_D
//      OLOGIC   mytop/mylei/mylei0/osirus_secondary_D
// means that you have an p/n (primary/secondary) output connected to a oserdes n/p (secondary/primary) primitive, so change it to an oserdes p/n (primary/secondary) primitive, like so:
// either set .PINTYPE("n") or .PINTYPE("p") as appropriate

module iserdes_single4 #(
	parameter WIDTH = 4
) (
	input sample_clock,
	input data_in,
	input reset,
	output word_clock,
	output [WIDTH-1:0] word_out
);
	wire fast_clock;
	wire ioce;
	wire raw_word_clock;
	BUFIO2 #(.DIVIDE(WIDTH), .USE_DOUBLER("FALSE"), .I_INVERT("FALSE"), .DIVIDE_BYPASS("FALSE")) buffy (.I(sample_clock), .DIVCLK(raw_word_clock), .IOCLK(fast_clock), .SERDESSTROBE(ioce));
	BUFG fabbuf (.I(raw_word_clock), .O(word_clock));
	ISERDES2 #(
		.BITSLIP_ENABLE("FALSE"), // Enable Bitslip Functionality (TRUE/FALSE)
		.DATA_RATE("SDR"), // Data-rate ("SDR" or "DDR")
		.DATA_WIDTH(WIDTH), // Parallel data width selection (2-8)
		.INTERFACE_TYPE("RETIMED"),// "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED"
		.SERDES_MODE("NONE") // "NONE", "M*****" or "S****"
	) ISERDES2_inst (
		.CFB0(), // 1-bit output: Clock feed-through route output
		.CFB1(), // 1-bit output: Clock feed-through route output
		.DFB(), // 1-bit output: Feed-through clock output
		.FABRICOUT(), // 1-bit output: Unsynchrnonized data output
		.INCDEC(), // 1-bit output: Phase detector output
		// Q1 - Q4: 1-bit (each) output: Registered outputs to FPGA logic
		.Q4(word_out[3]), // see ug381 page 80
		.Q3(word_out[2]),
		.Q2(word_out[1]),
		.Q1(word_out[0]),
		.SHIFTOUT(), // 1-bit output: Cascade output signal for primary/secondary I/O
		.VALID(), // 1-bit output: Output status of the phase detector
		.BITSLIP(1'b0), // 1-bit input: Bitslip enable input
		.CE0(1'b1), // 1-bit input: Clock enable input
		.CLK0(fast_clock), // 1-bit input: I/O clock network input
		.CLK1(1'b0), // 1-bit input: Secondary I/O clock network input
		.CLKDIV(word_clock), // 1-bit input: FPGA logic domain clock input
		.D(data_in), // 1-bit input: Input data
		.IOCE(ioce), // 1-bit input: Data strobe input
		.RST(reset), // 1-bit input: Asynchronous reset input
		.SHIFTIN(1'b0) // 1-bit input: Cascade input signal for primary/secondary I/O
	);
//	wire pll_is_locked;
//	wire buffered_pll_is_locked_and_strobe_is_aligned;
//	BUFPLL #(
//		.DIVIDE(WIDTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
//		) rx_bufpll_inst (
//		.PLLIN(sample_clock), // PLL Clock input
//		.GCLK(raw_fabric_clock), // Global Clock input
//		.LOCKED(pll_is_locked), // Clock0 locked input
//		.IOCLK(fast_clock), // Output PLL Clock
//		.LOCK(buffered_pll_is_locked_and_strobe_is_aligned), // BUFPLL Clock and strobe locked
//		.SERDESSTROBE(ioce) // Output SERDES strobe
//		);
endmodule

//	ocyrus_single8_inner #(.BIT_RATIO(8)) mylei (.word_clock(), .bit_clock(), .bit_strobe(), .reset(), .word_in(), .bit_out());
module ocyrus_single8_inner #(
	parameter PINTYPE = "p", // "p" (primary) or "n" (secondary)
	parameter BIT_RATIO=8 // how many fast_clock cycles per word_clock
) (
	input word_clock,
	input bit_clock,
	input bit_strobe,
	input reset,
	input [BIT_RATIO-1:0] word_in,
	output bit_out
);
	wire cascade_do1, cascade_to1, cascade_di1, cascade_ti1;
	wire cascade_do2, cascade_to2, cascade_di2, cascade_ti2;
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	// want MSB of word to come out first
	if (PINTYPE=="p") begin
		OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(BIT_RATIO),
		           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
		         osirus_primary_D
		         (.OQ(bit_out), .TQ(), .CLK0(bit_clock), .CLK1(1'b0), .CLKDIV(word_clock),
		         .D1(word_in[3]), .D2(word_in[2]), .D3(word_in[1]), .D4(word_in[0]),
		         .IOCE(bit_strobe), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
		         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do2), .SHIFTIN4(cascade_to2), 
		         .SHIFTOUT1(cascade_di2), .SHIFTOUT2(cascade_ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
		         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
		OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(BIT_RATIO),
		           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
		         osirus_secondary_D
		         (.OQ(), .TQ(), .CLK0(bit_clock), .CLK1(1'b0), .CLKDIV(word_clock),
		         .D1(word_in[7]), .D2(word_in[6]), .D3(word_in[5]), .D4(word_in[4]),
		         .IOCE(bit_strobe), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
		         .SHIFTIN1(cascade_di2), .SHIFTIN2(cascade_ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
		         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do2), .SHIFTOUT4(cascade_to2),
		         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	end else begin
		OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(BIT_RATIO),
		           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
		         osirus_primary_D
		         (.OQ(), .TQ(), .CLK0(bit_clock), .CLK1(1'b0), .CLKDIV(word_clock),
		         .D1(word_in[3]), .D2(word_in[2]), .D3(word_in[1]), .D4(word_in[0]),
		         .IOCE(bit_strobe), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
		         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do2), .SHIFTIN4(cascade_to2), 
		         .SHIFTOUT1(cascade_di2), .SHIFTOUT2(cascade_ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
		         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
		OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(BIT_RATIO),
		           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
		         osirus_secondary_D
		         (.OQ(bit_out), .TQ(), .CLK0(bit_clock), .CLK1(1'b0), .CLKDIV(word_clock),
		         .D1(word_in[7]), .D2(word_in[6]), .D3(word_in[5]), .D4(word_in[4]),
		         .IOCE(bit_strobe), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
		         .SHIFTIN1(cascade_di2), .SHIFTIN2(cascade_ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
		         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do2), .SHIFTOUT4(cascade_to2),
		         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	end
endmodule

module ocyrus_single8 #(
	parameter SCOPE = "BUFIO2", // can be "BUFIO2" (525 MHz max), "BUFPLL" (1050 MHz max) or "GLOBAL" (400 MHz max) for speed grade 3
	parameter BIT_WIDTH=1, // how many bits come out in parallel
	parameter BIT_DEPTH=8, // how many fast_clock cycles per word_clock (same as previous definition of WIDTH parameter)
	parameter MODE = "WORD_CLOCK_IN", // can be "WORD_CLOCK_IN" or "BIT_CLOCK_IN"
	parameter PINTYPE = "p",
	parameter PHASE = 0.0,
	parameter PERIOD = 20.0,
	parameter DIVIDE = 2,
	parameter MULTIPLY = 40,
	parameter CLK_FEEDBACK = "CLKFBOUT"
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [BIT_DEPTH-1:0] word_in,
	output D_out,
	output locked
);
	wire bit_clock;
	wire bit_strobe;
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE)) mylei (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word_in), .bit_out(D_out));
	oserdes_pll #(.BIT_DEPTH(BIT_DEPTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY), .SCOPE(SCOPE), .MODE(MODE), .CLK_FEEDBACK(CLK_FEEDBACK), .PHASE(PHASE)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .word_clock_out(word_clock_out),
		.serializer_clock_out(bit_clock), .serializer_strobe_out(bit_strobe), .locked(locked)
	);
endmodule

module ocyrus_double8 #(
	parameter SCOPE = "BUFIO2", // can be "BUFIO2" (525 MHz max), "BUFPLL" (1050 MHz max) or "GLOBAL" (400 MHz max) for speed grade 3
	parameter BIT_WIDTH=1, // how many bits come out in parallel
	parameter BIT_DEPTH=8, // how many fast_clock cycles per word_clock (same as previous definition of WIDTH parameter)
	parameter MODE = "WORD_CLOCK_IN", // can be "WORD_CLOCK_IN" or "BIT_CLOCK_IN"
	parameter PINTYPE0 = "p",
	parameter PINTYPE1 = "p",
	parameter PERIOD = 20.0,
	parameter DIVIDE = 2,
	parameter MULTIPLY = 40,
	parameter CLK_FEEDBACK = "CLKFBOUT"
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [BIT_DEPTH-1:0] word0_in, word1_in,
	output D0_out, D1_out,
	output bit_clock,
	output bit_strobe,
	output locked
);
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE0)) mylei0 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word0_in), .bit_out(D0_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE1)) mylei1 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word1_in), .bit_out(D1_out));
	oserdes_pll #(.BIT_DEPTH(BIT_DEPTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY), .SCOPE(SCOPE), .MODE(MODE), .CLK_FEEDBACK(CLK_FEEDBACK)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .word_clock_out(word_clock_out),
		.serializer_clock_out(bit_clock), .serializer_strobe_out(bit_strobe), .locked(locked)
	);
endmodule

module ocyrus_quad8 #(
	parameter SCOPE = "BUFIO2", // can be "BUFIO2" (525 MHz max), "BUFPLL" (1050 MHz max) or "GLOBAL" (400 MHz max) for speed grade 3
	parameter BIT_WIDTH=1, // how many bits come out in parallel
	parameter BIT_DEPTH=8, // how many fast_clock cycles per word_clock (same as previous definition of WIDTH parameter)
	parameter MODE = "WORD_CLOCK_IN", // can be "WORD_CLOCK_IN" or "BIT_CLOCK_IN"
	parameter PINTYPE0 = "p",
	parameter PINTYPE1 = "p",
	parameter PINTYPE2 = "p",
	parameter PINTYPE3 = "p",
	parameter PERIOD = 20.0,
	parameter DIVIDE = 2,
	parameter MULTIPLY = 40,
	parameter CLK_FEEDBACK = "CLKFBOUT"
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [BIT_DEPTH-1:0] word0_in, word1_in, word2_in, word3_in,
	output D0_out, D1_out, D2_out, D3_out,
	output locked
);
	wire bit_clock;
	wire bit_strobe;
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE0)) mylei0 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word0_in), .bit_out(D0_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE1)) mylei1 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word1_in), .bit_out(D1_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE2)) mylei2 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word2_in), .bit_out(D2_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE3)) mylei3 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word3_in), .bit_out(D3_out));
	oserdes_pll #(.BIT_DEPTH(BIT_DEPTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY), .SCOPE(SCOPE), .MODE(MODE), .CLK_FEEDBACK(CLK_FEEDBACK)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .word_clock_out(word_clock_out),
		.serializer_clock_out(bit_clock), .serializer_strobe_out(bit_strobe), .locked(locked)
	);
endmodule

module ocyrus_hex8 #(
	parameter SCOPE = "BUFIO2", // can be "BUFIO2" (525 MHz max), "BUFPLL" (1050 MHz max) or "GLOBAL" (400 MHz max) for speed grade 3
	parameter BIT_WIDTH=1, // how many bits come out in parallel
	parameter BIT_DEPTH=8, // how many fast_clock cycles per word_clock (same as previous definition of WIDTH parameter)
	parameter MODE = "WORD_CLOCK_IN", // can be "WORD_CLOCK_IN" or "BIT_CLOCK_IN"
	parameter PINTYPE0 = "p",
	parameter PINTYPE1 = "p",
	parameter PINTYPE2 = "p",
	parameter PINTYPE3 = "p",
	parameter PINTYPE4 = "p",
	parameter PINTYPE5 = "p",
	parameter PERIOD = 20.0,
	parameter DIVIDE = 2,
	parameter MULTIPLY = 40
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [BIT_DEPTH-1:0] word0_in, word1_in, word2_in, word3_in, word4_in, word5_in,
	output D0_out, D1_out, D2_out, D3_out, D4_out, D5_out,
	output locked
);
	wire bit_clock;
	wire bit_strobe;
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE0)) mylei0 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word0_in), .bit_out(D0_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE1)) mylei1 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word1_in), .bit_out(D1_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE2)) mylei2 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word2_in), .bit_out(D2_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE3)) mylei3 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word3_in), .bit_out(D3_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE4)) mylei4 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word4_in), .bit_out(D4_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE5)) mylei5 (.word_clock(word_clock_out), .bit_clock(bit_clock), .bit_strobe(bit_strobe), .reset(reset), .word_in(word5_in), .bit_out(D5_out));
	oserdes_pll #(.BIT_DEPTH(BIT_DEPTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY), .SCOPE(SCOPE), .MODE(MODE)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .word_clock_out(word_clock_out),
		.serializer_clock_out(bit_clock), .serializer_strobe_out(bit_strobe), .locked(locked)
	);
endmodule

module ocyrus_hex8_split_4_2 #(
	parameter SCOPE = "BUFPLL", // can be "BUFIO2" (525 MHz max), "BUFPLL" (1050 MHz max) or "GLOBAL" (400 MHz max) for speed grade 3
	parameter BIT_WIDTH=1, // how many bits come out in parallel
	parameter BIT_DEPTH=8, // how many fast_clock cycles per word_clock (same as previous definition of WIDTH parameter)
	parameter MODE = "WORD_CLOCK_IN", // can be "WORD_CLOCK_IN" or "BIT_CLOCK_IN"
	parameter PINTYPE0 = "p",
	parameter PINTYPE1 = "p",
	parameter PINTYPE2 = "p",
	parameter PINTYPE3 = "p",
	parameter PINTYPE4 = "p",
	parameter PINTYPE5 = "p",
	parameter PERIOD = 20.0,
	parameter DIVIDE = 2,
	parameter MULTIPLY = 40
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [BIT_DEPTH-1:0] word0_in, word1_in, word2_in, word3_in, word4_in, word5_in,
	output D0_out, D1_out, D2_out, D3_out, D4_out, D5_out,
	output locked
);
	wire bit_clock0, bit_clock1;
	wire bit_strobe0, bit_strobe1;
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE0)) mylei0 (.word_clock(word_clock_out), .bit_clock(bit_clock0), .bit_strobe(bit_strobe0), .reset(reset), .word_in(word0_in), .bit_out(D0_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE1)) mylei1 (.word_clock(word_clock_out), .bit_clock(bit_clock0), .bit_strobe(bit_strobe0), .reset(reset), .word_in(word1_in), .bit_out(D1_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE2)) mylei2 (.word_clock(word_clock_out), .bit_clock(bit_clock0), .bit_strobe(bit_strobe0), .reset(reset), .word_in(word2_in), .bit_out(D2_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE3)) mylei3 (.word_clock(word_clock_out), .bit_clock(bit_clock0), .bit_strobe(bit_strobe0), .reset(reset), .word_in(word3_in), .bit_out(D3_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE4)) mylei4 (.word_clock(word_clock_out), .bit_clock(bit_clock1), .bit_strobe(bit_strobe1), .reset(reset), .word_in(word4_in), .bit_out(D4_out));
	ocyrus_single8_inner #(.BIT_RATIO(BIT_DEPTH), .PINTYPE(PINTYPE5)) mylei5 (.word_clock(word_clock_out), .bit_clock(bit_clock1), .bit_strobe(bit_strobe1), .reset(reset), .word_in(word5_in), .bit_out(D5_out));
//oserdes_pll #(.BIT_DEPTH(BIT_DEPTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY), .SCOPE(SCOPE), .MODE(MODE)) difficult_pll_TR (
//		.reset(reset), .clock_in(clock_in), .word_clock_out(word_clock_out),
//		.serializer_clock_out(bit_clock), .serializer_strobe_out(bit_strobe), .locked(locked)
	wire clock_1x, clock_nx;
	wire pll_is_locked; // Locked output from PLL
	simpll #(
		.BIT_DEPTH(BIT_DEPTH),
		.CLKIN_PERIOD(PERIOD),
		.PHASE(0.0),
		.PLLD(DIVIDE),
		.PLLX(MULTIPLY)
	) siphon (
		.clock_in(clock_in),
		.reset(reset),
		.clock_nx_fb(bit_clock0),
		.pll_is_locked(pll_is_locked),
		.clock_1x(clock_1x),
		.clock_nx(clock_nx)
	);
	BUFG bufg_tx (.I(clock_1x), .O(word_clock_out));
	wire strobe_is_aligned0, strobe_is_aligned1;
	BUFPLL #(
		.ENABLE_SYNC("TRUE"), // synchronizes strobe to gclk input
		.DIVIDE(BIT_DEPTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
	) tx_bufpll_inst_0 (
		.PLLIN(clock_nx), // PLL Clock input
		.GCLK(word_clock_out), // Global Clock input
		.LOCKED(pll_is_locked), // Clock0 locked input
		.IOCLK(bit_clock0), // Output PLL Clock
		.LOCK(strobe_is_aligned0), // BUFPLL Clock and strobe locked
		.SERDESSTROBE(bit_strobe0) // Output SERDES strobe
	);
	BUFPLL #(
		.ENABLE_SYNC("TRUE"), // synchronizes strobe to gclk input
		.DIVIDE(BIT_DEPTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
	) tx_bufpll_inst_1 (
		.PLLIN(clock_nx), // PLL Clock input
		.GCLK(word_clock_out), // Global Clock input
		.LOCKED(pll_is_locked), // Clock0 locked input
		.IOCLK(bit_clock1), // Output PLL Clock
		.LOCK(strobe_is_aligned1), // BUFPLL Clock and strobe locked
		.SERDESSTROBE(bit_strobe1) // Output SERDES strobe
	);
	assign locked = pll_is_locked & strobe_is_aligned0 & strobe_is_aligned1;
endmodule

// 156.25 / 8.0 * 61.875 / 2.375 = 508.840461 for scrod revA3 on-board oscillator
// 156.25 / 5 * 32 = 1000 for scrod revA3 on-board oscillator
// 50.0 / 2 * 40 = 1000 for althea on-board oscillator
// 127.221875 / 2 * 16 = 1017.775 MHz
// 508.8875 / 2 * 4 = 1017.775 MHz
module simpll #(
	parameter BIT_DEPTH = 8, // how many fast_clock cycles per word_clock (same as previous definition of WIDTH parameter)
	parameter CLKIN_PERIOD = 6.4,
	parameter PHASE = 0.0,
	parameter PLLD = 5,
	parameter PLLX = 32,
	parameter CLK_FEEDBACK = "CLKFBOUT",
	parameter COMPENSATION = CLK_FEEDBACK=="CLKFBOUT" ? "INTERNAL" : "EXTERNAL"
) (
	input clock_in,
	input reset,
	input clock_nx_fb,
	output pll_is_locked,
	output clock_1x,
	output clock_nx
);
	// from clock_generator_pll_s8_diff.v from XAPP1064 example code, ug615 and ug382
	// frequency of VCO after div and mult must be in range [400,1050] MHz for speed grade 3
	// frequency of PFD (right after first DIVCLK_DIVIDE) stage must be in range [19, 500] MHz for speed grade 3
	// frequency of BUFG can't be higher than 400 MHz
	wire fb_in; // incoming feedback net
	wire fb_out; // outgoing feedback net
	wire clock_in_copy;
	if (CLK_FEEDBACK=="CLKFBOUT") begin
		assign fb_in = fb_out;
		assign clock_in_copy = clock_in;
		//localparam COMPENSATION = "INTERNAL";
	end else begin // "CLKOUT0"
		BUFIO2 #(.DIVIDE(1), .USE_DOUBLER("FALSE"), .I_INVERT("FALSE"), .DIVIDE_BYPASS("TRUE")) boopy (.I(clock_in), .DIVCLK(clock_in_copy));
		BUFIO2FB schmoopy (.I(clock_nx_fb), .O(fb_in));
		//assign fb_in = clock_nx;
		//localparam COMPENSATION = "EXTERNAL";
	end
	PLL_ADV #(
		.SIM_DEVICE("SPARTAN6"),
		.CLK_FEEDBACK(CLK_FEEDBACK), // "CLKFBOUT" or "CLKOUT0"
		.BANDWIDTH("OPTIMIZED"), // "high", "low" or "optimized"
		.CLKFBOUT_PHASE(0.0), // phase shift (degrees) of all output clocks
		.CLKIN1_PERIOD(CLKIN_PERIOD), // clock period (ns) of input clock on clkin1
		.CLKIN2_PERIOD(CLKIN_PERIOD), // clock period (ns) of input clock on clkin2
		.DIVCLK_DIVIDE(PLLD), // division factor for all clocks (1 to 52)
		.CLKFBOUT_MULT(PLLX), // multiplication factor for all output clocks
		.CLKOUT0_DIVIDE(1), // division factor for clkout0 (1 to 128)
		.CLKOUT1_DIVIDE(BIT_DEPTH), // division factor for clkout1 (1 to 128)
		.CLKOUT2_DIVIDE(2), // division factor for clkout2 (1 to 128)
		.CLKOUT3_DIVIDE(4), // division factor for clkout3 (1 to 128)
		.CLKOUT4_DIVIDE(8), // division factor for clkout4 (1 to 128)
		.CLKOUT5_DIVIDE(16), // division factor for clkout5 (1 to 128)
		.CLKOUT0_PHASE(0.0), // phase shift (degrees) for clkout0 (0.0 to 360.0)
		.CLKOUT1_PHASE(PHASE), // phase shift (degrees) for clkout1 (0.0 to 360.0)
		.CLKOUT2_PHASE(0.0), // phase shift (degrees) for clkout2 (0.0 to 360.0)
		.CLKOUT3_PHASE(0.0), // phase shift (degrees) for clkout3 (0.0 to 360.0)
		.CLKOUT4_PHASE(0.0), // phase shift (degrees) for clkout4 (0.0 to 360.0)
		.CLKOUT5_PHASE(0.0), // phase shift (degrees) for clkout5 (0.0 to 360.0)
		.CLKOUT0_DUTY_CYCLE(0.5), // duty cycle for clkout0 (0.01 to 0.99)
		.CLKOUT1_DUTY_CYCLE(0.5), // duty cycle for clkout1 (0.01 to 0.99)
		.CLKOUT2_DUTY_CYCLE(0.5), // duty cycle for clkout2 (0.01 to 0.99)
		.CLKOUT3_DUTY_CYCLE(0.5), // duty cycle for clkout3 (0.01 to 0.99)
		.CLKOUT4_DUTY_CYCLE(0.5), // duty cycle for clkout4 (0.01 to 0.99)
		.CLKOUT5_DUTY_CYCLE(0.5), // duty cycle for clkout5 (0.01 to 0.99)
		.COMPENSATION(COMPENSATION), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
		.REF_JITTER(0.100) // input reference jitter (0.000 to 0.999 ui%)
		) pll_adv_inst (
		.RST(reset), // asynchronous pll reset
		.LOCKED(pll_is_locked), // active high pll lock signal
		.CLKFBIN(fb_in), // clock feedback input
		.CLKFBOUT(fb_out), // general output feedback signal
		.CLKIN1(clock_in_copy), // primary clock input
		.CLKOUT0(clock_nx), // *n clock for transmitter
		.CLKOUT1(clock_1x), //
		.CLKOUT2(), // *1 clock for BUFG
		.CLKOUT3(), // one of six general clock output signals
		.CLKOUT4(), // one of six general clock output signals
		.CLKOUT5(), // one of six general clock output signals
		.CLKFBDCM(), // output feedback signal used when pll feeds a dcm
		.CLKOUTDCM0(), // one of six clock outputs to connect to the dcm
		.CLKOUTDCM1(), // one of six clock outputs to connect to the dcm
		.CLKOUTDCM2(), // one of six clock outputs to connect to the dcm
		.CLKOUTDCM3(), // one of six clock outputs to connect to the dcm
		.CLKOUTDCM4(), // one of six clock outputs to connect to the dcm
		.CLKOUTDCM5(), // one of six clock outputs to connect to the dcm
		.DO(), // dynamic reconfig data output (16-bits)
		.DRDY(), // dynamic reconfig ready output
		.CLKIN2(1'b0), // secondary clock input
		.CLKINSEL(1'b1), // selects '1' = clkin1, '0' = clkin2
		.DADDR(5'b00000), // dynamic reconfig address input (5-bits)
		.DCLK(1'b0), // dynamic reconfig clock input
		.DEN(1'b0), // dynamic reconfig enable input
		.DI(16'h0000), // dynamic reconfig data input (16-bits)
		.DWE(1'b0), // dynamic reconfig write enable input
		.REL(1'b0) // used to force the state of the PFD outputs (test only)
	);
endmodule

module oserdes_pll #(
	// seems global mode is only possible for bit clocks that fit on the gbuf network (max 400 MHz)
	parameter SCOPE = "BUFPLL", // can be "BUFIO2" (525 MHz max), "BUFPLL" (1050 MHz max) or "GLOBAL" (400 MHz max) for speed grade 3
	parameter BIT_WIDTH = 1, // how many bits come out in parallel
	parameter BIT_DEPTH = 8, // how many fast_clock cycles per word_clock (same as previous definition of WIDTH parameter)
	parameter MODE = "WORD_CLOCK_IN", // can be "WORD_CLOCK_IN" or "BIT_CLOCK_IN"
	parameter CLKIN_PERIOD = 6.4,
	parameter PHASE = 0.0,
	parameter PLLD=5,
	parameter PLLX=32,
	parameter CLK_FEEDBACK = "CLKFBOUT"
) (
	input clock_in, input reset, output word_clock_out,
	output serializer_clock_out, output serializer_strobe_out, output locked
);
	wire clock_1x, clock_nx;
	wire pll_is_locked; // Locked output from PLL
	//if (SCOPE == "BUFPLL" | SCOPE == "GLOBAL" | MODE == "WORD_CLOCK_IN") begin
	wire buffered_pll_is_locked_and_strobe_is_aligned;
	if (MODE == "WORD_CLOCK_IN") begin
		wire rawclock_1x_plladv;
		wire rawclock_nx_plladv;
		simpll #(
			.BIT_DEPTH(BIT_DEPTH),
			.CLKIN_PERIOD(CLKIN_PERIOD),
			.PHASE(PHASE),
			.PLLD(PLLD),
			.PLLX(PLLX),
			.CLK_FEEDBACK(CLK_FEEDBACK)
		) simon (
			.clock_in(clock_in),
			.reset(reset),
			.clock_nx_fb(serializer_clock_out),
			.pll_is_locked(pll_is_locked),
			.clock_1x(rawclock_1x_plladv),
			.clock_nx(rawclock_nx_plladv)
		);
		if (SCOPE == "BUFIO2") begin
			BUFIO2 #(
				.DIVIDE(BIT_DEPTH), .USE_DOUBLER("FALSE"), .I_INVERT("FALSE"), .DIVIDE_BYPASS("FALSE")
			) simon1 (
				.I(rawclock_nx_plladv), .DIVCLK(clock_1x), .IOCLK(clock_nx), .SERDESSTROBE(serializer_strobe_out)
			);
			assign buffered_pll_is_locked_and_strobe_is_aligned = 1;
			assign serializer_clock_out = clock_nx;
		end else if (SCOPE == "BUFPLL") begin
			assign clock_1x = rawclock_1x_plladv;
			BUFPLL #(
				.ENABLE_SYNC("TRUE"), // synchronizes strobe to gclk input
				.DIVIDE(BIT_DEPTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
			) tx_bufpll_inst_1 (
				.PLLIN(rawclock_nx_plladv), // PLL Clock input
				.GCLK(word_clock_out), // Global Clock input
				.LOCKED(pll_is_locked), // Clock0 locked input
				.IOCLK(serializer_clock_out), // Output PLL Clock
				.LOCK(buffered_pll_is_locked_and_strobe_is_aligned), // BUFPLL Clock and strobe locked
				.SERDESSTROBE(serializer_strobe_out) // Output SERDES strobe
			);
		end
	end else if (MODE == "BIT_CLOCK_IN") begin
		wire serializer_strobe_out_bufio2;
		BUFIO2 #(
			.DIVIDE(BIT_DEPTH), .USE_DOUBLER("FALSE"), .I_INVERT("FALSE"), .DIVIDE_BYPASS("FALSE")
		) simon2 (
			.I(clock_in), .DIVCLK(clock_1x), .IOCLK(clock_nx), .SERDESSTROBE(serializer_strobe_out_bufio2)
		);
		if (SCOPE == "BUFPLL") begin
			wire serializer_strobe_out_bufpll;
			BUFPLL #(
				.ENABLE_SYNC("FALSE"), // does *not* try to synchronize strobe to gclk input
				.DIVIDE(BIT_DEPTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
			) tx_bufpll_inst_2 (
				.PLLIN(clock_nx), // PLL Clock input
				.GCLK(word_clock_out), // Global Clock input
				.LOCKED(pll_is_locked), // Clock0 locked input
				.IOCLK(serializer_clock_out), // Output PLL Clock
				.LOCK(buffered_pll_is_locked_and_strobe_is_aligned), // BUFPLL Clock and strobe locked
				.SERDESSTROBE(serializer_strobe_out_bufpll) // Output SERDES strobe
			);
			assign serializer_strobe_out = serializer_strobe_out_bufpll;
		end else begin
			assign serializer_clock_out = clock_nx;
			assign serializer_strobe_out = serializer_strobe_out_bufio2;
			assign buffered_pll_is_locked_and_strobe_is_aligned = 1;
		end
	end
	assign locked = pll_is_locked & buffered_pll_is_locked_and_strobe_is_aligned;
	BUFG bufg_tx (.I(clock_1x), .O(word_clock_out));
endmodule

//	odelay_fixed #(.AMOUNT()) beckham (.bit_in(), .bit_out());
// spartan6 errata (EN148) says not to go above a delay tap value of 6 when used in ODELAY mode to get full performance (1080 MHz)
// otherwise, limit the data rate to 800 MHz for the commercial grade -3 part
module odelay_fixed #(
	parameter AMOUNT = 0
) (
	// "With IDELAY_TYPE programming FIXED or DEFAULT any active input pins INC, RST, CE and C are not used and will be ignored"
	// "The use IDELAY_TYPE of FIXED or DEFAULT means that pins CLK, IOCLK0 and IOCLK1 are ignored"
	input bit_in,
	output bit_out
);
// from Xilinx HDL Libraries Guide, version 14.5 (ug615)
	IODELAY2 #(
		.COUNTER_WRAPAROUND("WRAPAROUND"), // "STAY_AT_LIMIT" or "WRAPAROUND"
		.DATA_RATE("SDR"), // "SDR" or "DDR"
		.DELAY_SRC("ODATAIN"), // "IO", "ODATAIN" or "IDATAIN"
		.IDELAY2_VALUE(0), // Delay value when IDELAY_MODE="PCI" (0-255)
		.IDELAY_MODE("NORMAL"), // "NORMAL" or "PCI"
		.IDELAY_TYPE("FIXED"), // "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" or "DIFF_PHASE_DETECTOR"
		.IDELAY_VALUE(), // Amount of taps for fixed input delay (0-255)
		.ODELAY_VALUE(AMOUNT), // Amount of taps for fixed output delay (0-255)
		.SERDES_MODE("NONE"), // "NONE", "M*****" or "S****" (idelay only according to ug381)
		.SIM_TAPDELAY_VALUE(75) // Per tap delay used for simulation in ps
	) beck (
		.CLK(1'b0), // 1-bit input: Clock input
		.RST(1'b0), // 1-bit input: Reset to zero or 1/2 of total delay period
		.INC(1'b0), // 1-bit input: Increment / decrement input - "INC should only be asserted High when CE is also asserted High" (ug381)
		.CE(1'b0), // 1-bit input: Enable INC input
		.IOCLK0(1'b0), // 1-bit input: Input from the I/O clock network
		.IOCLK1(1'b0), // 1-bit input: Input from the I/O clock network
		.ODATAIN(bit_in), // 1-bit input: Output data input from output register or OSERDES2.
		.DOUT(bit_out), // 1-bit output: Delayed data output
		.CAL(1'b0), // 1-bit input: Initiate calibration input
		.BUSY(), // 1-bit output: Busy output after CAL
		.T(1'b0), // 1-bit input: 3-state input signal
		.TOUT(), // 1-bit output: Delayed 3-state output
		.IDATAIN(1'b0), // 1-bit input: Data input (connect to top-level port or I/O buffer)
		.DATAOUT(), // 1-bit output: Delayed data output to ISERDES/input register
		.DATAOUT2() // 1-bit output: Delayed data output to general FPGA fabric
	);
endmodule

//	idelay nirvana (.clock(), .reset(), .inc_not_dec(), .strobe(), .bit_clock(), .bit_in(), .bit_out(), .initiate_cal(), .busy());
// spartan6 errata (EN148) says not to go above a delay tap value of 6 when used in ODELAY mode to get full performance (1080 MHz)
// otherwise, limit the data rate to 800 MHz for the commercial grade -3 part
module idelay #(
	parameter MODE = "MASTER" // "NONE", "M*****" or "S****"
) (
	// "The output delay path is only available in a fixed delay"
	input clock,
	input reset,
	input inc_not_dec,
	input strobe,
	input bit_clock,
	input bit_in,
	output bit_out,
	input initiate_cal, // must issue reset after first cal
	output busy
);
// from Xilinx HDL Libraries Guide, version 14.5 (ug615)
	IODELAY2 #(
		.COUNTER_WRAPAROUND("WRAPAROUND"), // "STAY_AT_LIMIT" or "WRAPAROUND"
		.DATA_RATE("SDR"), // "SDR" or "DDR"
		.DELAY_SRC("IDATAIN"), // "IO", "ODATAIN" or "IDATAIN"
		.IDELAY2_VALUE(0), // Delay value when IDELAY_MODE="PCI" (0-255)
		.IDELAY_MODE("NORMAL"), // "NORMAL" or "PCI"
		.IDELAY_TYPE("VARIABLE_FROM_ZERO"), // "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" or "DIFF_PHASE_DETECTOR"
		.IDELAY_VALUE(0), // Amount of taps for fixed input delay (0-255)
		.ODELAY_VALUE(0), // Amount of taps for fixed output delay (0-255)
		.SERDES_MODE(MODE), // "NONE", "M*****" or "S****" (idelay only according to ug381)
		.SIM_TAPDELAY_VALUE(75) // Per tap delay used for simulation in ps
	) stp (
		.CLK(clock), // 1-bit input: Clock input
		.RST(reset), // 1-bit input: Reset to zero or 1/2 of total delay period
		.INC(inc_not_dec && strobe), // 1-bit input: Increment / decrement input - "INC should only be asserted High when CE is also asserted High" (ug381)
		.CE(strobe), // 1-bit input: Enable INC input
		.IOCLK0(bit_clock), // 1-bit input: Input from the I/O clock network
		.IOCLK1(1'b0), // 1-bit input: Input from the I/O clock network
		.ODATAIN(1'b0), // 1-bit input: Output data input from output register or OSERDES2.
		.DOUT(), // 1-bit output: Delayed data output
		.CAL(initiate_cal), // 1-bit input: Initiate calibration input
		.BUSY(busy), // 1-bit output: Busy output after CAL
		.T(1'b0), // 1-bit input: 3-state input signal
		.TOUT(), // 1-bit output: Delayed 3-state output
		.IDATAIN(bit_in), // 1-bit input: Data input (connect to top-level port or I/O buffer)
		.DATAOUT(bit_out), // 1-bit output: Delayed data output to ISERDES/input register
		.DATAOUT2() // 1-bit output: Delayed data output to general FPGA fabric
	);
endmodule

