`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2018-09-21 by mza

// 156.25 / 8.0 * 61.875 / 2.375 = 508.840461
// 156.25 / 5 * 32 = 1000
module oserdes_pll #(parameter WIDTH=8) (input clock_in, input reset, output fabric_clock_out, output serializer_clock_out, output serializer_strobe_output, output locked);
	// from clock_generator_pll_s8_diff.v from XAPP1064 example code
	parameter integer PLLD = 5; // 1 to 52 on a spartan6
	parameter integer PLLX = 32; // 1 to 64 on a spartan6
	// frequency of VCO after div and mult must be in range [400,1080] MHz
	parameter real CLKIN_PERIOD = 6.4; // clock period (ns) of input clock on clkin_p
	wire pllout_x1; // pll generated x1 clock
	wire pllout_xn; // pll generated xn clock
	wire dummy; // feedback net
	wire pll_is_locked; // Locked output from PLL
	wire buffered_pll_is_locked_and_strobe_is_aligned;
	assign locked = pll_is_locked & buffered_pll_is_locked_and_strobe_is_aligned;
	PLL_ADV #(
		.SIM_DEVICE("SPARTAN6"),
		.BANDWIDTH("OPTIMIZED"), // "high", "low" or "optimized"
		.CLKFBOUT_PHASE(0.0), // phase shift (degrees) of all output clocks
		.CLKIN1_PERIOD(CLKIN_PERIOD), // clock period (ns) of input clock on clkin1
		.CLKIN2_PERIOD(CLKIN_PERIOD), // clock period (ns) of input clock on clkin2
		.DIVCLK_DIVIDE(PLLD), // division factor for all clocks (1 to 52)
		.CLKFBOUT_MULT(PLLX), // multiplication factor for all output clocks
		.CLKOUT0_DIVIDE(1), // division factor for clkout0 (1 to 128)
		.CLKOUT0_DUTY_CYCLE(0.5), // duty cycle for clkout0 (0.01 to 0.99)
		.CLKOUT0_PHASE(0.0), // phase shift (degrees) for clkout0 (0.0 to 360.0)
		.CLKOUT1_DIVIDE(1), // division factor for clkout1 (1 to 128)
		.CLKOUT1_DUTY_CYCLE(0.5), // duty cycle for clkout1 (0.01 to 0.99)
		.CLKOUT1_PHASE(0.0), // phase shift (degrees) for clkout1 (0.0 to 360.0)
		.CLKOUT2_DIVIDE(WIDTH), // division factor for clkout2 (1 to 128)
		.CLKOUT2_DUTY_CYCLE(0.5), // duty cycle for clkout2 (0.01 to 0.99)
		.CLKOUT2_PHASE(0.0), // phase shift (degrees) for clkout2 (0.0 to 360.0)
		.CLKOUT3_DIVIDE(8), // division factor for clkout3 (1 to 128)
		.CLKOUT3_DUTY_CYCLE(0.5), // duty cycle for clkout3 (0.01 to 0.99)
		.CLKOUT3_PHASE(0.0), // phase shift (degrees) for clkout3 (0.0 to 360.0)
		.CLKOUT4_DIVIDE(8), // division factor for clkout4 (1 to 128)
		.CLKOUT4_DUTY_CYCLE(0.5), // duty cycle for clkout4 (0.01 to 0.99)
		.CLKOUT4_PHASE(0.0), // phase shift (degrees) for clkout4 (0.0 to 360.0)
		.CLKOUT5_DIVIDE(8), // division factor for clkout5 (1 to 128)
		.CLKOUT5_DUTY_CYCLE(0.5), // duty cycle for clkout5 (0.01 to 0.99)
		.CLKOUT5_PHASE(0.0), // phase shift (degrees) for clkout5 (0.0 to 360.0)
		.COMPENSATION("INTERNAL"), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
		.REF_JITTER(0.100) // input reference jitter (0.000 to 0.999 ui%)
		) tx_pll_adv_inst (
		.RST(reset), // asynchronous pll reset
		.LOCKED(pll_is_locked), // active high pll lock signal
		.CLKFBIN(dummy), // clock feedback input
		.CLKFBOUT(dummy), // general output feedback signal
		.CLKIN1(clock_in), // primary clock input
		.CLKOUT0(pllout_xn), // *n clock for transmitter
		.CLKOUT1(), //
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
	BUFG bufg_tx (.I(pllout_x1), .O(fabric_clock_out));
	BUFPLL #(
		.DIVIDE(WIDTH) // PLLIN0 divide-by value to produce SERDESSTROBE (1 to 8); default 1
		) tx_bufpll_inst (
		.PLLIN(pllout_xn), // PLL Clock input
		.GCLK(fabric_clock_out), // Global Clock input
		.LOCKED(pll_is_locked), // Clock0 locked input
		.IOCLK(serializer_clock_out), // Output PLL Clock
		.LOCK(buffered_pll_is_locked_and_strobe_is_aligned), // BUFPLL Clock and strobe locked
		.SERDESSTROBE(serializer_strobe_output) // Output SERDES strobe
		);
endmodule

