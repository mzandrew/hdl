`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2019-09-12 by mza

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
		.SERDES_MODE("NONE") // "NONE", "MASTER" or "SLAVE"
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
		.SHIFTOUT(), // 1-bit output: Cascade output signal for master/slave I/O
		.VALID(), // 1-bit output: Output status of the phase detector
		.BITSLIP(1'b0), // 1-bit input: Bitslip enable input
		.CE0(1'b1), // 1-bit input: Clock enable input
		.CLK0(fast_clock), // 1-bit input: I/O clock network input
		.CLK1(1'b0), // 1-bit input: Secondary I/O clock network input
		.CLKDIV(word_clock), // 1-bit input: FPGA logic domain clock input
		.D(data_in), // 1-bit input: Input data
		.IOCE(ioce), // 1-bit input: Data strobe input
		.RST(reset), // 1-bit input: Asynchronous reset input
		.SHIFTIN(1'b0) // 1-bit input: Cascade input signal for master/slave I/O
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

module ocyrus_quad8 #(
	parameter WIDTH = 8,
	PERIOD = 20.0,
	DIVIDE = 2,
	MULTIPLY = 40
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [WIDTH-1:0] word1_in, word2_in, word3_in, word4_in,
	output D1_out, D2_out, D3_out, D4_out,
	output locked
);
	wire ioclk_D;
	wire ioclk_D1, ioclk_D2, ioclk_D3, ioclk_D4;
	wire ioce_D1, ioce_D2, ioce_D3, ioce_D4;
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_1do2, cascade_1to2, cascade_1di2, cascade_1ti2;
	wire cascade_2do2, cascade_2to2, cascade_2di2, cascade_2ti2;
	wire cascade_3do2, cascade_3to2, cascade_3di2, cascade_3ti2;
	wire cascade_4do2, cascade_4to2, cascade_4di2, cascade_4ti2;
	// want MSB of word to come out first
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_D1
	         (.OQ(D1_out), .TQ(), .CLK0(ioclk_D1), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word1_in[3]), .D2(word1_in[2]), .D3(word1_in[1]), .D4(word1_in[0]),
	         .IOCE(ioce_D1), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_1do2), .SHIFTIN4(cascade_1to2), 
	         .SHIFTOUT1(cascade_1di2), .SHIFTOUT2(cascade_1ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_D1
	         (.OQ(), .TQ(), .CLK0(ioclk_D1), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word1_in[7]), .D2(word1_in[6]), .D3(word1_in[5]), .D4(word1_in[4]),
	         .IOCE(ioce_D1), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_1di2), .SHIFTIN2(cascade_1ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_1do2), .SHIFTOUT4(cascade_1to2),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	// ----------------------------------------------------------------------
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_D2
	         (.OQ(D2_out), .TQ(), .CLK0(ioclk_D2), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word2_in[3]), .D2(word2_in[2]), .D3(word2_in[1]), .D4(word2_in[0]),
	         .IOCE(ioce_D2), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_2do2), .SHIFTIN4(cascade_2to2), 
	         .SHIFTOUT1(cascade_2di2), .SHIFTOUT2(cascade_2ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_D2
	         (.OQ(), .TQ(), .CLK0(ioclk_D2), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word2_in[7]), .D2(word2_in[6]), .D3(word2_in[5]), .D4(word2_in[4]),
	         .IOCE(ioce_D2), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_2di2), .SHIFTIN2(cascade_2ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_2do2), .SHIFTOUT4(cascade_2to2),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	// ----------------------------------------------------------------------
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_D3
	         (.OQ(D3_out), .TQ(), .CLK0(ioclk_D3), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word3_in[3]), .D2(word3_in[2]), .D3(word3_in[1]), .D4(word3_in[0]),
	         .IOCE(ioce_D3), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_3do2), .SHIFTIN4(cascade_3to2), 
	         .SHIFTOUT1(cascade_3di2), .SHIFTOUT2(cascade_3ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_D3
	         (.OQ(), .TQ(), .CLK0(ioclk_D3), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word3_in[7]), .D2(word3_in[6]), .D3(word3_in[5]), .D4(word3_in[4]),
	         .IOCE(ioce_D3), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_3di2), .SHIFTIN2(cascade_3ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_3do2), .SHIFTOUT4(cascade_3to2),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	// ----------------------------------------------------------------------
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_D4
	         (.OQ(D4_out), .TQ(), .CLK0(ioclk_D4), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word4_in[3]), .D2(word4_in[2]), .D3(word4_in[1]), .D4(word4_in[0]),
	         .IOCE(ioce_D4), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_4do2), .SHIFTIN4(cascade_4to2), 
	         .SHIFTOUT1(cascade_4di2), .SHIFTOUT2(cascade_4ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_D4
	         (.OQ(), .TQ(), .CLK0(ioclk_D4), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word4_in[7]), .D2(word4_in[6]), .D3(word4_in[5]), .D4(word4_in[4]),
	         .IOCE(ioce_D4), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_4di2), .SHIFTIN2(cascade_4ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_4do2), .SHIFTOUT4(cascade_4to2),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	assign ioclk_D1 = ioclk_D;
	assign ioclk_D2 = ioclk_D;
	assign ioclk_D3 = ioclk_D;
	assign ioclk_D4 = ioclk_D;
	assign ioce_D1 = ioce_D;
	assign ioce_D2 = ioce_D;
	assign ioce_D3 = ioce_D;
	assign ioce_D4 = ioce_D;
	oserdes_pll #(.WIDTH(WIDTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .fabric_clock_out(word_clock_out), 
		.serializer_clock_out(ioclk_D), .serializer_strobe_out(ioce_D), .locked(locked)
	);
endmodule

module ocyrus_double8 #(
	parameter WIDTH = 8,
	PERIOD = 20.0,
	DIVIDE = 2,
	MULTIPLY = 40
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [WIDTH-1:0] word1_in, word2_in,
	output D1_out, D2_out,
	output locked
);
	wire ioclk_D;
	wire ioclk_D1, ioclk_D2;
	wire ioce_D1, ioce_D2;
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_1do2, cascade_1to2, cascade_1di2, cascade_1ti2;
	wire cascade_2do2, cascade_2to2, cascade_2di2, cascade_2ti2;
	// want MSB of word to come out first
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_D1
	         (.OQ(D1_out), .TQ(), .CLK0(ioclk_D1), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word1_in[3]), .D2(word1_in[2]), .D3(word1_in[1]), .D4(word1_in[0]),
	         .IOCE(ioce_D1), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_1do2), .SHIFTIN4(cascade_1to2), 
	         .SHIFTOUT1(cascade_1di2), .SHIFTOUT2(cascade_1ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_D1
	         (.OQ(), .TQ(), .CLK0(ioclk_D1), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word1_in[7]), .D2(word1_in[6]), .D3(word1_in[5]), .D4(word1_in[4]),
	         .IOCE(ioce_D1), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_1di2), .SHIFTIN2(cascade_1ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_1do2), .SHIFTOUT4(cascade_1to2),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	// ----------------------------------------------------------------------
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_D2
	         (.OQ(D2_out), .TQ(), .CLK0(ioclk_D2), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word2_in[3]), .D2(word2_in[2]), .D3(word2_in[1]), .D4(word2_in[0]),
	         .IOCE(ioce_D2), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_2do2), .SHIFTIN4(cascade_2to2), 
	         .SHIFTOUT1(cascade_2di2), .SHIFTOUT2(cascade_2ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_D2
	         (.OQ(), .TQ(), .CLK0(ioclk_D2), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word2_in[7]), .D2(word2_in[6]), .D3(word2_in[5]), .D4(word2_in[4]),
	         .IOCE(ioce_D2), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_2di2), .SHIFTIN2(cascade_2ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_2do2), .SHIFTOUT4(cascade_2to2),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	assign ioclk_D1 = ioclk_D;
	assign ioclk_D2 = ioclk_D;
	assign ioce_D1 = ioce_D;
	assign ioce_D2 = ioce_D;
	oserdes_pll #(.WIDTH(WIDTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .fabric_clock_out(word_clock_out), 
		.serializer_clock_out(ioclk_D), .serializer_strobe_out(ioce_D), .locked(locked)
	);
endmodule

module ocyrus_single8 #(
	parameter WIDTH = 8,
	PERIOD = 20.0,
	DIVIDE = 2,
	MULTIPLY = 40
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [WIDTH-1:0] word_in,
	output D_out,
	output locked
);
	wire ioclk_D;
	wire ioce_D;
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_do1, cascade_to1, cascade_di1, cascade_ti1;
	wire cascade_do2, cascade_to2, cascade_di2, cascade_ti2;
	// want MSB of word to come out first
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_D
	         (.OQ(D_out), .TQ(), .CLK0(ioclk_D), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word_in[3]), .D2(word_in[2]), .D3(word_in[1]), .D4(word_in[0]),
	         .IOCE(ioce_D), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do2), .SHIFTIN4(cascade_to2), 
	         .SHIFTOUT1(cascade_di2), .SHIFTOUT2(cascade_ti2), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_D
	         (.OQ(), .TQ(), .CLK0(ioclk_D), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word_in[7]), .D2(word_in[6]), .D3(word_in[5]), .D4(word_in[4]),
	         .IOCE(ioce_D), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_di2), .SHIFTIN2(cascade_ti2), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do2), .SHIFTOUT4(cascade_to2),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	oserdes_pll #(.WIDTH(WIDTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .fabric_clock_out(word_clock_out), 
		.serializer_clock_out(ioclk_D), .serializer_strobe_out(ioce_D), .locked(locked)
	);
endmodule

// 156.25 / 8.0 * 61.875 / 2.375 = 508.840461 for scrod revA3 on-board oscillator
// 156.25 / 5 * 32 = 1000 for scrod revA3 on-board oscillator
// 50.0 / 2 * 40 = 1000 for althea on-board oscillator
// 127.221875 / 2 * 16 = 1017.775 MHz
// 508.8875 / 2 * 4 = 1017.775 MHz
module simpll #(
	parameter WIDTH=8,
	parameter CLKIN_PERIOD=6.4,
	parameter PLLD=5,
	parameter PLLX=32
) (
	input clock_in,
	input reset,
	output pll_is_locked,
	output clock_1x,
	output clock_nx
);
	// from clock_generator_pll_s8_diff.v from XAPP1064 example code
	// frequency of VCO after div and mult must be in range [400,1080] MHz
	// frequency of BUFG can't be higher than 400 MHz
	wire clock_1x; // pll generated x1 clock
	wire clock_nx; // pll generated xn clock
	wire fb; // feedback net
	wire pll_is_locked; // Locked output from PLL
	PLL_ADV #(
		.SIM_DEVICE("SPARTAN6"),
		.BANDWIDTH("OPTIMIZED"), // "high", "low" or "optimized"
		.CLKFBOUT_PHASE(0.0), // phase shift (degrees) of all output clocks
		.CLKIN1_PERIOD(CLKIN_PERIOD), // clock period (ns) of input clock on clkin1
		.CLKIN2_PERIOD(CLKIN_PERIOD), // clock period (ns) of input clock on clkin2
		.DIVCLK_DIVIDE(PLLD), // division factor for all clocks (1 to 52)
		.CLKFBOUT_MULT(PLLX), // multiplication factor for all output clocks
		.CLKOUT0_DIVIDE(1), // division factor for clkout0 (1 to 128)
		.CLKOUT1_DIVIDE(1), // division factor for clkout1 (1 to 128)
		.CLKOUT2_DIVIDE(WIDTH), // division factor for clkout2 (1 to 128)
		.CLKOUT3_DIVIDE(8), // division factor for clkout3 (1 to 128)
		.CLKOUT4_DIVIDE(8), // division factor for clkout4 (1 to 128)
		.CLKOUT5_DIVIDE(8), // division factor for clkout5 (1 to 128)
		.CLKOUT0_PHASE(0.0), // phase shift (degrees) for clkout0 (0.0 to 360.0)
		.CLKOUT1_PHASE(0.0), // phase shift (degrees) for clkout1 (0.0 to 360.0)
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
		.COMPENSATION("INTERNAL"), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
		.REF_JITTER(0.100) // input reference jitter (0.000 to 0.999 ui%)
		) pll_adv_inst (
		.RST(reset), // asynchronous pll reset
		.LOCKED(pll_is_locked), // active high pll lock signal
		.CLKFBIN(fb), // clock feedback input
		.CLKFBOUT(fb), // general output feedback signal
		.CLKIN1(clock_in), // primary clock input
		.CLKOUT0(), // *n clock for transmitter
		.CLKOUT1(clock_nx), //
		.CLKOUT2(clock_1x), // *1 clock for BUFG
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
//	parameter scope = "BUFIO2", // can be "BUFIO2" "BUFPLL" or "GLOBAL"
	parameter WIDTH=8,
	parameter CLKIN_PERIOD=6.4,
	parameter PLLD=5,
	parameter PLLX=32
) (
	input clock_in, input reset, output fabric_clock_out,
	output serializer_clock_out, output serializer_strobe_out, output locked
);
	wire clock_1x, clock_nx;
	wire pll_is_locked; // Locked output from PLL
	simpll #(
		.WIDTH(WIDTH),
		.CLKIN_PERIOD(CLKIN_PERIOD),
		.PLLD(PLLD),
		.PLLX(PLLX)
	) simon (
		.clock_in(clock_in),
		.reset(reset),
		.pll_is_locked(pll_is_locked),
		.clock_1x(clock_1x),
		.clock_nx(clock_nx)
	);
	BUFG bufg_tx (.I(clock_1x), .O(fabric_clock_out));
	wire buffered_pll_is_locked_and_strobe_is_aligned;
	BUFPLL #(
		.DIVIDE(WIDTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
		) tx_bufpll_inst_2 (
		.PLLIN(clock_nx), // PLL Clock input
		.GCLK(fabric_clock_out), // Global Clock input
		.LOCKED(pll_is_locked), // Clock0 locked input
		.IOCLK(serializer_clock_out), // Output PLL Clock
		.LOCK(buffered_pll_is_locked_and_strobe_is_aligned), // BUFPLL Clock and strobe locked
		.SERDESSTROBE(serializer_strobe_out) // Output SERDES strobe
	);
	assign locked = pll_is_locked & buffered_pll_is_locked_and_strobe_is_aligned;
endmodule

