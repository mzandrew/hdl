`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2019-08-26 by mza

module ocyrus_double8 #(
	parameter WIDTH = 8,
	PERIOD = 20.0,
	DIVIDE = 2,
	MULTIPLY = 40
) (
	input clock_in,
	output word_clock_out,
	input reset,
	input [WIDTH-1:0] word1_in,
	input [WIDTH-1:0] word2_in,
	output D1_out,
	output D2_out,
	output T1_out,
	output T2_out,
	output locked
);
	wire ioclk_T;
	wire ioclk_T1; // 1000 MHz
	wire ioclk_T2; // 1000 MHz
	wire ioclk_D;
	wire ioclk_D1; // 1000 MHz
	wire ioclk_D2; // 1000 MHz
	wire ioce_T1;
	wire ioce_T2;
	wire ioce_D1;
	wire ioce_D2;
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_1do1;
	wire cascade_1to1;
	wire cascade_1di1;
	wire cascade_1ti1;
	wire cascade_1do2;
	wire cascade_1to2;
	wire cascade_1di2;
	wire cascade_1ti2;
	wire cascade_2do1;
	wire cascade_2to1;
	wire cascade_2di1;
	wire cascade_2ti1;
	wire cascade_2do2;
	wire cascade_2to2;
	wire cascade_2di2;
	wire cascade_2ti2;
	// want MSB of word to come out first
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_T1
	         (.OQ(T1_out), .TQ(), .CLK0(ioclk_T1), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word1_in[3]), .D2(word1_in[2]), .D3(word1_in[1]), .D4(word1_in[0]),
	         .IOCE(ioce_T1), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_1do1), .SHIFTIN4(cascade_1to1), 
	         .SHIFTOUT1(cascade_1di1), .SHIFTOUT2(cascade_1ti1), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_T1
	         (.OQ(), .TQ(), .CLK0(ioclk_T1), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word1_in[7]), .D2(word1_in[6]), .D3(word1_in[5]), .D4(word1_in[4]),
	         .IOCE(ioce_T1), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_1di1), .SHIFTIN2(cascade_1ti1), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_1do1), .SHIFTOUT4(cascade_1to1),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
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
	         osirus_master_T2
	         (.OQ(T2_out), .TQ(), .CLK0(ioclk_T2), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word2_in[3]), .D2(word2_in[2]), .D3(word2_in[1]), .D4(word2_in[0]),
	         .IOCE(ioce_T2), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_2do1), .SHIFTIN4(cascade_2to1), 
	         .SHIFTOUT1(cascade_2di1), .SHIFTOUT2(cascade_2ti1), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_T2
	         (.OQ(), .TQ(), .CLK0(ioclk_T2), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word2_in[7]), .D2(word2_in[6]), .D3(word2_in[5]), .D4(word2_in[4]),
	         .IOCE(ioce_T2), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_2di1), .SHIFTIN2(cascade_2ti1), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_2do1), .SHIFTOUT4(cascade_2to1),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
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
	wire locked_T;
	wire locked_D;
	assign ioclk_T1 = ioclk_T;
	assign ioclk_T2 = ioclk_T;
	assign ioclk_D1 = ioclk_D;
	assign ioclk_D2 = ioclk_D;
	assign ioce_T1 = ioce_T;
	assign ioce_T2 = ioce_T;
	assign ioce_D1 = ioce_D;
	assign ioce_D2 = ioce_D;
	oserdes_pll #(.WIDTH(WIDTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .fabric_clock_out(word_clock_out), 
		.serializer_clock_out_1(ioclk_T), .serializer_strobe_out_1(ioce_T), .locked_1(locked_T),
		.serializer_clock_out_2(ioclk_D), .serializer_strobe_out_2(ioce_D), .locked_2(locked_D)
	);
	assign locked = locked_T & locked_D;
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
	output T_out,
	output locked
);
	wire ioclk_T; // 1000 MHz
	wire ioclk_D; // 1000 MHz
	wire ioce_T;
	wire ioce_D;
	// with some help from https://vjordan.info/log/fpga/high-speed-serial-bus-generation-using-spartan-6.html and/or XAPP1064 source code
	wire cascade_do1;
	wire cascade_to1;
	wire cascade_di1;
	wire cascade_ti1;
	wire cascade_do2;
	wire cascade_to2;
	wire cascade_di2;
	wire cascade_ti2;
	// want MSB of word to come out first
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("MASTER"))
	         osirus_master_T
	         (.OQ(T_out), .TQ(), .CLK0(ioclk_T), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word_in[3]), .D2(word_in[2]), .D3(word_in[1]), .D4(word_in[0]),
	         .IOCE(ioce_T), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(1'b1), .SHIFTIN2(1'b1), .SHIFTIN3(cascade_do1), .SHIFTIN4(cascade_to1), 
	         .SHIFTOUT1(cascade_di1), .SHIFTOUT2(cascade_ti1), .SHIFTOUT3(), .SHIFTOUT4(), 
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
	OSERDES2 #(.DATA_RATE_OQ("SDR"), .DATA_RATE_OT("SDR"), .DATA_WIDTH(WIDTH),
	           .OUTPUT_MODE("SINGLE_ENDED"), .SERDES_MODE("SLAVE"))
	         osirus_slave_T
	         (.OQ(), .TQ(), .CLK0(ioclk_T), .CLK1(1'b0), .CLKDIV(word_clock_out),
	         .D1(word_in[7]), .D2(word_in[6]), .D3(word_in[5]), .D4(word_in[4]),
	         .IOCE(ioce_T), .OCE(1'b1), .RST(reset), .TRAIN(1'b0),
	         .SHIFTIN1(cascade_di1), .SHIFTIN2(cascade_ti1), .SHIFTIN3(1'b1), .SHIFTIN4(1'b1),
	         .SHIFTOUT1(), .SHIFTOUT2(), .SHIFTOUT3(cascade_do1), .SHIFTOUT4(cascade_to1),
	         .TCE(1'b1), .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0));
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
	wire locked_T;
	wire locked_D;
	oserdes_pll #(.WIDTH(WIDTH), .CLKIN_PERIOD(PERIOD), .PLLD(DIVIDE), .PLLX(MULTIPLY)) difficult_pll_TR (
		.reset(reset), .clock_in(clock_in), .fabric_clock_out(word_clock_out), 
		.serializer_clock_out_1(ioclk_T), .serializer_strobe_out_1(ioce_T), .locked_1(locked_T),
		.serializer_clock_out_2(ioclk_D), .serializer_strobe_out_2(ioce_D), .locked_2(locked_D)
	);
	assign locked = locked_T & locked_D;
endmodule

// 156.25 / 8.0 * 61.875 / 2.375 = 508.840461 for scrod revA3 on-board oscillator
// 156.25 / 5 * 32 = 1000 for scrod revA3 on-board oscillator
// 50.0 / 2 * 40 = 1000 for althea on-board oscillator
module oserdes_pll #(parameter WIDTH=8, parameter CLKIN_PERIOD=6.4, parameter PLLD=5, parameter PLLX=32) (
	input clock_in, input reset, output fabric_clock_out,
	output serializer_clock_out_1, output serializer_strobe_out_1, output locked_1,
	output serializer_clock_out_2, output serializer_strobe_out_2, output locked_2
);
	// from clock_generator_pll_s8_diff.v from XAPP1064 example code
//	localparam integer PLLD = 5; // 1 to 52 on a spartan6
//	localparam integer PLLX = 32; // 1 to 64 on a spartan6
	// frequency of VCO after div and mult must be in range [400,1080] MHz
	wire pllout_xn_1; // pll generated xn clock
	wire pllout_xn_2; // pll generated xn clock
	wire pllout_x1; // pll generated x1 clock
	wire fb; // feedback net
	wire pll_is_locked; // Locked output from PLL
	wire buffered_pll_is_locked_and_strobe_is_aligned_1;
	wire buffered_pll_is_locked_and_strobe_is_aligned_2;
	assign locked_1 = pll_is_locked & buffered_pll_is_locked_and_strobe_is_aligned_1;
	assign locked_2 = pll_is_locked & buffered_pll_is_locked_and_strobe_is_aligned_2;
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
		.CLKOUT0_PHASE(7.2), // phase shift (degrees) for clkout0 (0.0 to 360.0)
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
		) tx_pll_adv_inst (
		.RST(reset), // asynchronous pll reset
		.LOCKED(pll_is_locked), // active high pll lock signal
		.CLKFBIN(fb), // clock feedback input
		.CLKFBOUT(fb), // general output feedback signal
		.CLKIN1(clock_in), // primary clock input
		.CLKOUT0(pllout_xn_1), // *n clock for transmitter
		.CLKOUT1(pllout_xn_2), //
		.CLKOUT2(pllout_x1), // *1 clock for BUFG
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
	wire fabric_clock;
	BUFG bufg_tx (.I(pllout_x1), .O(fabric_clock));
	assign fabric_clock_out = fabric_clock;
	BUFPLL #(
		.DIVIDE(WIDTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
		) tx_bufpll_inst_1 (
		.PLLIN(pllout_xn_1), // PLL Clock input
		.GCLK(fabric_clock), // Global Clock input
		.LOCKED(pll_is_locked), // Clock0 locked input
		.IOCLK(serializer_clock_out_1), // Output PLL Clock
		.LOCK(buffered_pll_is_locked_and_strobe_is_aligned_1), // BUFPLL Clock and strobe locked
		.SERDESSTROBE(serializer_strobe_out_1) // Output SERDES strobe
		);
	BUFPLL #(
		.DIVIDE(WIDTH) // PLLIN divide-by value to produce SERDESSTROBE (1 to 8); default 1
		) tx_bufpll_inst_2 (
		.PLLIN(pllout_xn_2), // PLL Clock input
		.GCLK(fabric_clock), // Global Clock input
		.LOCKED(pll_is_locked), // Clock0 locked input
		.IOCLK(serializer_clock_out_2), // Output PLL Clock
		.LOCK(buffered_pll_is_locked_and_strobe_is_aligned_2), // BUFPLL Clock and strobe locked
		.SERDESSTROBE(serializer_strobe_out_2) // Output SERDES strobe
		);
endmodule

