// written 2019-08-14 by mza
// taken from info in ug382/ug615/ds162, ug768/ug953
// last updated 2025-03-11 by mza

// pll, dcm, mmcm, etc
`ifndef PLLDCM_LIB
`define PLLDCM_LIB

// from ug162:
// spartan6 -3 PLL_in via BUFGMUX [19,400] MHz
// spartan6 -3 PLL_in via BUFIO2 [19,540] MHz
// spartan6 -3 PLL_vco [400,1080] MHz
// spartan6 -3 PLL_out via BUFPLL [3.125,1080] MHz
// spartan6 -3 PLL_PFD [19,500] MHz
// spartan6 -3 DCM_dfs_in [0.5,280] MHz
// spartan6 -3 DCM_dfs_out [5,375] MHz
// spartan6 DCM_SP_multiply [2,32]
// spartan6 DCM_SP_divide [1,32]
// spartan6 DCM_CLKGEN_multiply [2,256]
// spartan6 DCM_CLKGEN_divide [1,256]

module dummy_dcm_diff_input #(
	parameter MULT_DIV = 10,
	parameter PERIOD = 10.0
) (
	input clock_p, clock_n,
	input reset,
	output clock_out,
	output clock_locked
);
	wire clock_raw1;
	IBUFGDS mybuf_raw1 (.I(clock_p), .IB(clock_n), .O(clock_raw1));
	wire clock_raw2;
	simpledcm_CLKGEN #(.MULTIPLY(MULT_DIV), .DIVIDE(MULT_DIV), .PERIOD(PERIOD)) mydcm (.clockin(clock_raw1), .reset(reset), .clockout(clock_raw2), .clockout180(), .locked(clock_locked));
	BUFG mybuf_raw2 (.I(clock_raw2), .O(clock_out));
endmodule

// can only be used to directly feed a DCM
//simplepll_ADV_2DCM #(.OVERALL_DIVIDE(1), .MULTIPLY(10), .DIVIDE(4), .PERIOD(20.0)) mypll (.clockin(clock50), .reset(reset), .clockout(clock), .locked()); // 50->125
module simplepll_ADV_2DCM #(
	parameter OVERALL_DIVIDE = 1,
	parameter MULTIPLY = 4,
	parameter DIVIDE = 1,
	parameter PERIOD = 10.0,
	parameter COMPENSATION = "PLL2DCM"
) (
	input clockin,
	input reset,
	output clockout,
	output locked
);
	wire fbdcm;
	PLL_ADV #(
		.SIM_DEVICE("SPARTAN6"),
		.BANDWIDTH("OPTIMIZED"), // "high", "low" or "optimized"
		.CLKFBOUT_PHASE(0.0), // phase shift (degrees) of all output clocks
		.CLKIN1_PERIOD(PERIOD), // clock period (ns) of input clock on clkin1
		.CLKIN2_PERIOD(PERIOD), // clock period (ns) of input clock on clkin2
		.DIVCLK_DIVIDE(OVERALL_DIVIDE), // division factor for all clocks (1 to 52)
		.CLKFBOUT_MULT(MULTIPLY), // multiplication factor for all output clocks
		.CLKOUT0_DIVIDE(DIVIDE), // division factor for clkout0 (1 to 128)
		.CLKOUT1_DIVIDE(1), // division factor for clkout1 (1 to 128)
		.CLKOUT2_DIVIDE(1), // division factor for clkout2 (1 to 128)
		.CLKOUT3_DIVIDE(1), // division factor for clkout3 (1 to 128)
		.CLKOUT4_DIVIDE(1), // division factor for clkout4 (1 to 128)
		.CLKOUT5_DIVIDE(1), // division factor for clkout5 (1 to 128)
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
		.COMPENSATION(COMPENSATION), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
		.REF_JITTER(0.100) // input reference jitter (0.000 to 0.999 ui%)
	) pll_adv_inst (
		.RST(reset), // asynchronous pll reset
		.LOCKED(locked), // active high pll lock signal
		.CLKFBIN(fbdcm), // clock feedback input
		.CLKFBOUT(), // general output feedback signal
		.CLKIN1(clockin), // primary clock input
		.CLKOUT0(),
		.CLKOUT1(), //
		.CLKOUT2(), //
		.CLKOUT3(), // one of six general clock output signals
		.CLKOUT4(), // one of six general clock output signals
		.CLKOUT5(), // one of six general clock output signals
		.CLKFBDCM(fbdcm), // output feedback signal used when pll feeds a dcm
		.CLKOUTDCM0(clockout), // one of six clock outputs to connect to the dcm
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

//simplepll_ADV #(.OVERALL_DIVIDE(1), .MULTIPLY(10), .DIVIDE(4), .PERIOD(20.0)) mypll (.clockin(clock50), .reset(reset), .clockout(clock), .locked()); // 50->125
//	simplepll_ADV #(
//		.PERIOD(PLLPERIOD), .OVERALL_DIVIDE(OVERALL_PLLDIVIDE), .MULTIPLY(PLLMULTIPLY), .DIVIDE(PLLDIVIDE),
//		.DIVIDE0(WORD_CLOCK_DIVIDE), .DIVIDE1(BIT_CLOCK_DIVIDE),
//		.DIVIDE2(SAMPLE_CLOCK_DIVIDE), .DIVIDE3(1),
//		.DIVIDE4(1), .DIVIDE5(1),
//		.PHASE0(0.0),  .PHASE1(0.0),
//		.PHASE2(0.0),  .PHASE3(0.0),
//		.PHASE4(0.0),  .PHASE5(0.0)
//	) mypll (
//		.clockin(clock_in),
//		.reset(reset),
//		.clock0out(raw_word_clock), .clock1out(bit_clock),
//		.clock2out(raw_sample_clock), .clock3out(),
//		.clock4out(), .clock5out(),
//		.locked(pll_is_locked));
module simplepll_ADV #(
	parameter OVERALL_DIVIDE = 1,
	parameter MULTIPLY = 4,
	parameter DIVIDE0=1, DIVIDE1=1, DIVIDE2=1, DIVIDE3=1, DIVIDE4=1, DIVIDE5=1,
	parameter PHASE0=0.0, PHASE1=0.0, PHASE2=0.0, PHASE3=0.0, PHASE4=0.0, PHASE5=0.0,
	parameter PERIOD = 10.0,
	parameter COMPENSATION = "INTERNAL"
) (
	input clockin,
	input reset,
	output clock0out, output clock1out,
	output clock2out, output clock3out,
	output clock4out, output clock5out,
	output locked
);
	wire fb;
	PLL_ADV #(
		.SIM_DEVICE("SPARTAN6"),
		.BANDWIDTH("OPTIMIZED"), // "high", "low" or "optimized"
		.CLKFBOUT_PHASE(0.0), // phase shift (degrees) of all output clocks
		.CLKIN1_PERIOD(PERIOD), // clock period (ns) of input clock on clkin1
		.CLKIN2_PERIOD(PERIOD), // clock period (ns) of input clock on clkin2
		.DIVCLK_DIVIDE(OVERALL_DIVIDE), // division factor for all clocks (1 to 52)
		.CLKFBOUT_MULT(MULTIPLY), // multiplication factor for all output clocks
		.CLKOUT0_DIVIDE(DIVIDE0), // division factor for clkout0 (1 to 128)
		.CLKOUT1_DIVIDE(DIVIDE1), // division factor for clkout1 (1 to 128)
		.CLKOUT2_DIVIDE(DIVIDE2), // division factor for clkout2 (1 to 128)
		.CLKOUT3_DIVIDE(DIVIDE3), // division factor for clkout3 (1 to 128)
		.CLKOUT4_DIVIDE(DIVIDE4), // division factor for clkout4 (1 to 128)
		.CLKOUT5_DIVIDE(DIVIDE5), // division factor for clkout5 (1 to 128)
		.CLKOUT0_PHASE(PHASE0), // phase shift (degrees) for clkout0 (0.0 to 360.0)
		.CLKOUT1_PHASE(PHASE1), // phase shift (degrees) for clkout1 (0.0 to 360.0)
		.CLKOUT2_PHASE(PHASE2), // phase shift (degrees) for clkout2 (0.0 to 360.0)
		.CLKOUT3_PHASE(PHASE3), // phase shift (degrees) for clkout3 (0.0 to 360.0)
		.CLKOUT4_PHASE(PHASE4), // phase shift (degrees) for clkout4 (0.0 to 360.0)
		.CLKOUT5_PHASE(PHASE5), // phase shift (degrees) for clkout5 (0.0 to 360.0)
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
		.LOCKED(locked), // active high pll lock signal
		.CLKFBIN(fb), // clock feedback input
		.CLKFBOUT(fb), // general output feedback signal
		.CLKIN1(clockin), // primary clock input
		.CLKOUT0(clock0out),
		.CLKOUT1(clock1out), //
		.CLKOUT2(clock2out), //
		.CLKOUT3(clock3out), // one of six general clock output signals
		.CLKOUT4(clock4out), // one of six general clock output signals
		.CLKOUT5(clock5out), // one of six general clock output signals
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

//wire rawclock125;
//simplepll_BASE #(.OVERALL_DIVIDE(1), .MULTIPLY(10), .DIVIDE0(4), .PHASE0(0.0), .PERIOD(20.0)) other (.clockin(clock50), .reset(reset), .clock0out(rawclock125), .locked(other_pll_locked)); // 50->125
//wire clock125;
//BUFG mrt (.I(rawclock125), .O(clock125));
// divclk_divide 1 to 52
// mult 1 to 64
// clkout_divide 1 to 128
module simplepll_BASE #(
	parameter
	PERIOD=10.0,
	OVERALL_DIVIDE=1,
	MULTIPLY=4,
	DIVIDE0=1, DIVIDE1=2, DIVIDE2=4, DIVIDE3=8, DIVIDE4=16, DIVIDE5=32,
	PHASE0=0.0, PHASE1=0.0, PHASE2=0.0, PHASE3=0.0, PHASE4=0.0, PHASE5=0.0,
	COMPENSATION="SYSTEM_SYNCHRONOUS"
) (
	input clockin,
	input reset,
	output clock0out, output clock1out,
	output clock2out, output clock3out,
	output clock4out, output clock5out,
	output locked
);
	wire fb;
	PLL_BASE #(
		.BANDWIDTH("OPTIMIZED"), // "HIGH", "LOW" or "OPTIMIZED"
		.CLKFBOUT_MULT(MULTIPLY), // Multiplication factor for all output clocks
		.CLKFBOUT_PHASE(0.0), // Phase shift (degrees) of all output clocks
		.CLKIN_PERIOD(PERIOD), // Clock period (ns) of input clock on CLKIN
		.CLKOUT0_DIVIDE(DIVIDE0), // Division factor for CLKOUT0 (1 to 128)
		.CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.01 to 0.99)
		.CLKOUT0_PHASE(PHASE0), // Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
		.CLKOUT1_DIVIDE(DIVIDE1), // Division factor for CLKOUT1 (1 to 128)
		.CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT1 (0.01 to 0.99)
		.CLKOUT1_PHASE(PHASE1), // Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
		.CLKOUT2_DIVIDE(DIVIDE2), // Division factor for CLKOUT2 (1 to 128)
		.CLKOUT2_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT2 (0.01 to 0.99)
		.CLKOUT2_PHASE(PHASE2), // Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
		.CLKOUT3_DIVIDE(DIVIDE3), // Division factor for CLKOUT3 (1 to 128)
		.CLKOUT3_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT3 (0.01 to 0.99)
		.CLKOUT3_PHASE(PHASE3), // Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
		.CLKOUT4_DIVIDE(DIVIDE4), // Division factor for CLKOUT4 (1 to 128)
		.CLKOUT4_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT4 (0.01 to 0.99)
		.CLKOUT4_PHASE(PHASE4), // Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
		.CLKOUT5_DIVIDE(DIVIDE5), // Division factor for CLKOUT5 (1 to 128)
		.CLKOUT5_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT5 (0.01 to 0.99)
		.CLKOUT5_PHASE(PHASE5), // Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
		.COMPENSATION(COMPENSATION), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
		.DIVCLK_DIVIDE(OVERALL_DIVIDE), // Division factor for all clocks (1 to 52)
		.REF_JITTER(0.100) // Input reference jitter (0.000 to 0.999 UI%)
	) PLL_BASE_inst (
		.CLKFBOUT(fb), // General output feedback signal
		.CLKOUT0(clock0out), // One of six general clock output signals
		.CLKOUT1(clock1out), // One of six general clock output signals
		.CLKOUT2(clock2out), // One of six general clock output signals
		.CLKOUT3(clock3out), // One of six general clock output signals
		.CLKOUT4(clock4out), // One of six general clock output signals
		.CLKOUT5(clock5out), // One of six general clock output signals
		.LOCKED(locked), // Active high PLL lock signal
		.CLKFBIN(fb), // Clock feedback input
		.CLKIN(clockin), // Clock input
		.RST(reset) // Asynchronous PLL reset
	);
endmodule

//	simpledcm_CLKGEN #(.MULTIPLY(), .DIVIDE(), .PERIOD()) mydcm (.clockin(), .reset(), .clockout(), .clockout180(), .locked());
// clockin: 0.5-375 MHz (ds162.pdf)
// clockout: 5-375 MHz (ds162.pdf)
// MULTIPLY: 2-256
// DIVIDE: 1-256
// clkfxdv_divide:2, 4, 8, 16, 32
module simpledcm_CLKGEN #(parameter MULTIPLY=4, DIVIDE=1, PERIOD="10.0") (
	input clockin,
	input reset,
	output clockout,
	output clockout180,
	output locked
);
	DCM_CLKGEN #(
//		.DFS_OSCILLATOR_MODE("PHASE_FREQ_LOCK"), // "The DCM has the attribute DFS_OSCILLATOR_MODE not set to PHASE_FREQ_LOCK. No phase relationship exists between the input clock and CLKFX or CLKFX180 outputs of this DCM. Data paths between these clock domains must be constrained using FROM/TO constraints" but "Module DCM_CLKGEN does not have a parameter named DFS_OSCILLATOR_MODE"
		.CLKFXDV_DIVIDE(2), // Specifies DIVIDE value for CLKFXDV.
		.CLKFX_DIVIDE(DIVIDE), // This value in conjunction with the input frequency and CLKFX_MULTIPLY
		// value determine the resultant output frequency for the CLKFX and
		// CLKFX180 outputs.
		.CLKFX_MD_MAX(0.0), // When using the DCM_CLKGEN with variable M and D values, this would
		// specify the maximum ratio of M and D used during static timing
		// analysis to ensure proper timing of the DCM output.
		.CLKFX_MULTIPLY(MULTIPLY), // This value in conjunction with the input frequency and CLKFX_DIVIDE
		// value determine the resultant output frequency for the CLKFX and
		// CLKFX180 outputs.
		.CLKIN_PERIOD(PERIOD), // This attribute specifies the source clock period which is used to
		// help the DCM adjust for the optimum CLKFX/CLKFX180 outputs and also
		// result in faster locking time.
		.STARTUP_WAIT("FALSE") // Delays configuration DONE signal until DCM LOCKED signal goes high.
		)
	DCM_CLKGEN_inst (
		.CLKFX(clockout), // 1-bit Generated output clock.
		.CLKFX180(clockout180), // 1-bit Generated output clock 180 degree out of phase from CLKFX.
		.CLKFXDV(), // 1-bit Divided output clock, Divide value derived from CLKFXDV_DIV attribute.
		// There is no phase alignment between CLKFX and CLKFXDV.
		.LOCKED(locked), // 1-bit Synchronous output from the DCM that provides the user with an indication
		// the DCM is ready for operation.
		.PROGDONE(), // 1-bit Active high output to indicate the successful re-programming of an M
		// and/or D value.
		.STATUS(), // 2-bit Clock Status lines.
		.CLKIN(clockin), // 1-bit The source clock (CLKIN) input pin provides the source clock to the DCM.
		// In the case of Free-running oscillator mode, running clock needs to be
		// connected until DCM is locked and DCM is frozen, then clock can be removed. In
		// the other modes, a free running clock needs to be provided and remain.
		.FREEZEDCM(1'b0), // 1-bit Prevents tap adjustment drift in the event of a lost CLKIN input
		.PROGCLK(1'b0), // 1-bit Clock input for M and/or D reconfiguration.
		.PROGDATA(1'b0), // 1-bit Serial data input to supply information for the reprogramming of M and/or
		// D values of the DCM. This input must be applied synchronous to the PROGCLK
		// input.
		.PROGEN(1'b0), // 1-bit Active high enable input for the reprogramming of M/D values. This input
		// must be applied synchronous to the PROGCLK input.
		.RST(reset) // 1-bit Reset pin
	);
endmodule

//	simpledcm_SP #(.MULTIPLY(), .DIVIDE(), .ALT_CLOCKOUT_DIVIDE(), .PERIOD()) mydcm (.clockin(), .reset(), .clockout(), .clockout180(), .alt_clockout(), .locked());
// MULTIPLY: 2-32
// DIVIDE: 1-32
module simpledcm_SP #(
	parameter ALT_CLOCKOUT_DIVIDE=2.0,
	parameter MULTIPLY=4,
	parameter DIVIDE=1,
	parameter PERIOD=10.0,
	parameter CLKIN_DIVIDE_BY_2 = "FALSE"
) (
	input clockin,
	input reset,
	output clockout,
	output clockout180,
	output alt_clockout,
	output locked
);
	wire fb;
//	wire clockfb_in;
//	wire clockfb_out;
//	BUFG mybufg (.I(clockfb_out), .O(clockfb_in));
	DCM_SP #(
		.CLKIN_PERIOD(PERIOD), // Specify period of input clock
		.CLKIN_DIVIDE_BY_2(CLKIN_DIVIDE_BY_2), // TRUE/FALSE to enable CLKIN divide by two feature
		.CLK_FEEDBACK("1X"), // Specify clock feedback of NONE, 1X or 2X
		.CLKFX_MULTIPLY(MULTIPLY), // Can be any integer from 2 to 32
		.CLKFX_DIVIDE(DIVIDE), // Can be any integer from 1 to 32
		.CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
		.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
		// an integer from 0 to 15
		.DLL_FREQUENCY_MODE("LOW"), // HIGH or LOW frequency mode for DLL
		.DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
		.PHASE_SHIFT(0), // Amount of fixed phase shift from -255 to 255
		.STARTUP_WAIT("FALSE"), // Delay configuration DONE until DCM LOCK, TRUE/FALSE
		.CLKDV_DIVIDE(ALT_CLOCKOUT_DIVIDE) // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
	) DCM_SP_inst (
		.CLKIN(clockin), // Clock input (from IBUFG, BUFG or DCM)
		.CLKFB(fb), // DCM clock feedback
		.CLKFX(clockout), // DCM CLK synthesis out (M/D)
		.CLKFX180(clockout180), // 180 degree CLK synthesis out
		.CLK0(fb), // 0 degree DCM CLK output
		.CLK90(), // 90 degree DCM CLK output
		.CLK180(), // 180 degree DCM CLK output
		.CLK270(), // 270 degree DCM CLK output
		.CLK2X(), // 2X DCM CLK output
		.CLK2X180(), // 2X, 180 degree DCM CLK out
		.PSDONE(), // Dynamic phase adjust done output
		.STATUS(), // 8-bit DCM status bits output
		.PSCLK(1'b0), // Dynamic phase adjust clock input
		.PSEN(1'b0), // Dynamic phase adjust enable input
		.PSINCDEC(1'b0), // Dynamic phase adjust increment/decrement
		.DSSEN(1'b0), // missing constraint in ug615
		.CLKDV(alt_clockout), // Divided DCM CLK out (CLKDV_DIVIDE)
		.LOCKED(locked), // DCM LOCK status output
		.RST(reset) // DCM asynchronous reset input
	);
endmodule

//	dcm_pll #(
//		.DCM_PERIOD(7.861), .DCM_MULTIPLY(4), .DCM_DIVIDE(4),
//		.PLL_PERIOD(7.861), .PLL_MULTIPLY(4), .PLL_OVERALL_DIVIDE(1),
//		.PLL_DIVIDE0(24), .PLL_DIVIDE1(24), .PLL_DIVIDE2(24), .PLL_DIVIDE3(24), .PLL_DIVIDE4(4), .PLL_DIVIDE5(4),
//		.PLL_PHASE0(0.0), .PLL_PHASE1(180.0), .PLL_PHASE2(0.0), .PLL_PHASE3(180.0), .PLL_PHASE4(0.0), .PLL_PHASE5(0.0)
//	) my_dcm_pll (
//		.clockin(clock127), .reset(reset127), .clockintermediate(word_clock), .dcm_locked(first_pll_locked), .pll_locked(second_pll_locked),
//		.clock0out(sstclk_raw), .clock1out(sstclk180_raw), .clock2out(wr_clk_raw), .clock3out(wr_clk180_raw), .clock4out(), .clock5out()
//	);
module dcm_pll #(
	parameter DCM_PERIOD = "10.0",
	parameter DCM_MULTIPLY = 1,
	parameter DCM_DIVIDE = 1,
	parameter PLL_PERIOD = 10.0,
	parameter PLL_MULTIPLY = 1,
	parameter PLL_OVERALL_DIVIDE = 1,
	parameter PLL_DIVIDE0 = 1, PLL_DIVIDE1 = 1, PLL_DIVIDE2 = 1, PLL_DIVIDE3 = 1, PLL_DIVIDE4 = 1, PLL_DIVIDE5 = 1, 
	parameter PLL_PHASE0 = 0.0, PLL_PHASE1 = 0.0, PLL_PHASE2 = 0.0, PLL_PHASE3 = 0.0, PLL_PHASE4 = 0.0, PLL_PHASE5 = 0.0 
) (
	input clockin,
	input reset,
	output clockintermediate,
	output clock0out, clock1out, clock2out, clock3out, clock4out, clock5out,
	output dcm_locked, pll_locked
);
	wire clockintermediate_raw;
	BUFG (.I(clockintermediate_raw), .O(clockintermediate));
	simpledcm_SP #(
		.MULTIPLY(DCM_MULTIPLY), .DIVIDE(DCM_DIVIDE), .PERIOD(DCM_PERIOD)
	) mydcm (
		.clockin(clockin),
		.reset(reset),
		.clockout(clockintermediate_raw),
		.clockout180(),
		.locked(dcm_locked));
	simplepll_BASE #(
		.OVERALL_DIVIDE(PLL_OVERALL_DIVIDE), .MULTIPLY(PLL_MULTIPLY), .PERIOD(PLL_PERIOD), .COMPENSATION("DCM2PLL"),
		.DIVIDE0(PLL_DIVIDE0), .DIVIDE1(PLL_DIVIDE1), .DIVIDE2(PLL_DIVIDE2), .DIVIDE3(PLL_DIVIDE3), .DIVIDE4(PLL_DIVIDE4), .DIVIDE5(PLL_DIVIDE5),
		.PHASE0(PLL_PHASE0), .PHASE1(PLL_PHASE1), .PHASE2(PLL_PHASE2), .PHASE3(PLL_PHASE3), .PHASE4(PLL_PHASE4), .PHASE5(PLL_PHASE5)
	) mypll (
		.clockin(clockintermediate),
		.reset(reset),
		.clock0out(clock0out), .clock1out(clock1out), .clock2out(clock2out), .clock3out(clock3out), .clock4out(clock4out), .clock5out(clock5out),
		.locked(pll_locked));
endmodule

//	dcm_pll_pll #(
//		.DCM_PERIOD(7.861), .DCM_MULTIPLY(4), .DCM_DIVIDE(4),
//		.PLL_PERIOD(7.861), .PLL_MULTIPLY(4), .PLL_OVERALL_DIVIDE(1),
//		.PLL_DIVIDE0(24), .PLL_DIVIDE1(24), .PLL_DIVIDE2(24), .PLL_DIVIDE3(24), .PLL_DIVIDE4(4), .PLL_DIVIDE5(4),
//		.PLL_PHASE0(0.0), .PLL_PHASE1(180.0), .PLL_PHASE2(0.0), .PLL_PHASE3(180.0), .PLL_PHASE4(0.0), .PLL_PHASE5(0.0)
//	) my_dcm_pll (
//		.clockin(clock127), .reset(reset127), .clockintermediate(word_clock), .dcm_locked(first_pll_locked), .pll_locked(second_pll_locked),
//		.clock0out(sstclk_raw), .clock1out(sstclk180_raw), .clock2out(wr_clk_raw), .clock3out(wr_clk180_raw), .clock4out(), .clock5out()
//	);
module dcm_pll_pll #(
	parameter DCM_PERIOD = "10.0",
	parameter DCM_MULTIPLY = 1,
	parameter DCM_DIVIDE = 1,
	parameter PLL_PERIOD = 10.0,
	parameter PLL_MULTIPLY = 1,
	parameter PLL_OVERALL_DIVIDE = 1,
	parameter PLL_DIVIDE0 = 1, PLL_DIVIDE1 = 1, PLL_DIVIDE2 = 1, PLL_DIVIDE3 = 1, PLL_DIVIDE4 = 1, PLL_DIVIDE5 = 1, 
	parameter PLL_DIVIDE6 = 1, PLL_DIVIDE7 = 1, PLL_DIVIDE8 = 1, PLL_DIVIDE9 = 1, PLL_DIVIDE10 = 1, PLL_DIVIDE11 = 1, 
	parameter PLL_PHASE0 = 0.0, PLL_PHASE1 = 0.0, PLL_PHASE2 = 0.0, PLL_PHASE3 = 0.0, PLL_PHASE4 = 0.0, PLL_PHASE5 = 0.0,
	parameter PLL_PHASE6 = 0.0, PLL_PHASE7 = 0.0, PLL_PHASE8 = 0.0, PLL_PHASE9 = 0.0, PLL_PHASE10 = 0.0, PLL_PHASE11 = 0.0 
) (
	input clockin,
	input reset,
	output clockintermediate, clockintermediate_raw, clockintermediate_raw180,
	output clock0out, clock1out, clock2out, clock3out, clock4out, clock5out,
	output clock6out, clock7out, clock8out, clock9out, clock10out, clock11out,
	output dcm_locked, pll1_locked, pll2_locked
);
	BUFG intermediate (.I(clockintermediate_raw), .O(clockintermediate));
	simpledcm_SP #(
		.MULTIPLY(DCM_MULTIPLY), .DIVIDE(DCM_DIVIDE), .PERIOD(DCM_PERIOD)
	) mydcm (
		.clockin(clockin),
		.reset(reset),
		.clockout(clockintermediate_raw),
		.clockout180(clockintermediate_raw180),
		.alt_clockout(),
		.locked(dcm_locked));
	simplepll_BASE #(
		.OVERALL_DIVIDE(PLL_OVERALL_DIVIDE), .MULTIPLY(PLL_MULTIPLY), .PERIOD(PLL_PERIOD), .COMPENSATION("DCM2PLL"),
		.DIVIDE0(PLL_DIVIDE0), .DIVIDE1(PLL_DIVIDE1), .DIVIDE2(PLL_DIVIDE2), .DIVIDE3(PLL_DIVIDE3), .DIVIDE4(PLL_DIVIDE4), .DIVIDE5(PLL_DIVIDE5),
		.PHASE0(PLL_PHASE0), .PHASE1(PLL_PHASE1), .PHASE2(PLL_PHASE2), .PHASE3(PLL_PHASE3), .PHASE4(PLL_PHASE4), .PHASE5(PLL_PHASE5)
	) mypll1 (
		.clockin(clockintermediate),
		.reset(reset),
		.clock0out(clock0out), .clock1out(clock1out), .clock2out(clock2out), .clock3out(clock3out), .clock4out(clock4out), .clock5out(clock5out),
		.locked(pll1_locked));
	simplepll_BASE #(
		.OVERALL_DIVIDE(PLL_OVERALL_DIVIDE), .MULTIPLY(PLL_MULTIPLY), .PERIOD(PLL_PERIOD), .COMPENSATION("DCM2PLL"),
		.DIVIDE0(PLL_DIVIDE6), .DIVIDE1(PLL_DIVIDE7), .DIVIDE2(PLL_DIVIDE8), .DIVIDE3(PLL_DIVIDE9), .DIVIDE4(PLL_DIVIDE10), .DIVIDE5(PLL_DIVIDE11),
		.PHASE0(PLL_PHASE6), .PHASE1(PLL_PHASE7), .PHASE2(PLL_PHASE8), .PHASE3(PLL_PHASE9), .PHASE4(PLL_PHASE10), .PHASE5(PLL_PHASE11)
	) mypll2 (
		.clockin(clockintermediate),
		.reset(reset),
		.clock0out(clock6out), .clock1out(clock7out), .clock2out(clock8out), .clock3out(clock9out), .clock4out(clock10out), .clock5out(clock11out),
		.locked(pll2_locked));
endmodule

//plldcm #(.OVERALL_DIVIDE(1), .pllmultiply(10), .plldivide(1), .pllperiod(20.0), .dcmmultiply(2), .dcmdivide(8), .dcmperiod(2.0)) kronos (.clockin(clock50), .reset(reset), .clockout(clock), .clockout180(), .locked()); // 50->125
module plldcm #(parameter OVERALL_DIVIDE=1, PLLMULTIPLY=1, PLLDIVIDE=1, PLLPERIOD=10.0, DCMMULTIPLY=1, DCMDIVIDE=1, DCMPERIOD="10.0") (
	input clockin,
	input reset,
	output clockout,
	output clockout180,
	output locked
);
	wire clockintermediate;
	wire dcmlocked;
	wire plllocked;
	assign locked = dcmlocked & plllocked;
	simplepll_ADV_2DCM #(.OVERALL_DIVIDE(OVERALL_DIVIDE), .MULTIPLY(PLLMULTIPLY), .DIVIDE(PLLDIVIDE), .PERIOD(PLLPERIOD), .COMPENSATION("PLL2DCM")) mypll (
	//simplepll_ADV #(.OVERALL_DIVIDE(OVERALL_DIVIDE), .MULTIPLY(PLLMULTIPLY), .DIVIDE(PLLDIVIDE), .PERIOD(PLLPERIOD), .COMPENSATION("DCM2PLL")) mypll (
		.clockin(clockin),
		.reset(reset),
		.clockout(clockintermediate),
		.locked(plllocked));
	simpledcm_SP #(.MULTIPLY(DCMMULTIPLY), .DIVIDE(DCMDIVIDE), .PERIOD(DCMPERIOD)) mydcm (
		.clockin(clockintermediate),
		.reset(reset),
		.clockout(clockout),
		.clockout180(clockout180),
		.locked(dcmlocked));
endmodule

module clock_select #(
	parameter N = 4,
	parameter log2_N = $clog2(N)
) (
	input [N-1:0] clock,
	input [log2_N-1:0] select,
	output clock_out
);
	wire clock_0s;
	wire clock_1s;
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_0s (.I0(clock[0]), .I1(clock[1]), .S(select[0]), .O(clock_0s));
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_1s (.I0(clock[2]), .I1(clock[3]), .S(select[0]), .O(clock_1s));
	BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_sx (.I0(clock_0s), .I1(clock_1s), .S(select[1]), .O(clock_out));
endmodule

// 7series:

//MMCM_base #(.M(10.0), .D(1), .CLKOUT0_DIVIDE(1.0), .CLOCK_PERIOD_NS(10.0),
//	.CLKOUT1_DIVIDE(1), .CLKOUT2_DIVIDE(1), .CLKOUT3_DIVIDE(1),
//	.CLKOUT4_DIVIDE(1), .CLKOUT5_DIVIDE(1), .CLKOUT6_DIVIDE(1)) (
//	.clock_in(clock), .reset(reset), .locked(mmcm_locked),
//	.clock0_out_p(), .clock0_out_n(), .clock1_out_p(), .clock1_out_n(),
//	.clock2_out_p(), .clock2_out_n(), .clock3_out_p(), .clock3_out_n(),
//	.clock4_out(), .clock5_out(), .clock6_out());
// never tested
module MMCM_base #(
	parameter D = 1, // overall divide [1,106]
	parameter M = 10.0, // overall multiply [2.0,64.0]
	parameter CLKOUT0_DIVIDE = 1.0, // this one is fractional [1.0,128.0]
	parameter CLKOUT1_DIVIDE = 1, // [1,128]
	parameter CLKOUT2_DIVIDE = 1,
	parameter CLKOUT3_DIVIDE = 1,
	parameter CLKOUT4_DIVIDE = 1,
	parameter CLKOUT5_DIVIDE = 1,
	parameter CLKOUT6_DIVIDE = 1,
	parameter CLOCK_PERIOD_NS = 10.0
) (
	input clock_in, // input=[10,800]MHz; PFD=[10,450]MHz; VCO=[600,1200]MHz; OUT=[4.69,800]MHz for a "-1" grade zynq-7020
	input reset,
	output locked,
	output clock0_out_p, clock0_out_n,
	output clock1_out_p, clock1_out_n,
	output clock2_out_p, clock2_out_n,
	output clock3_out_p, clock3_out_n,
	output clock4_out,
	output clock5_out,
	output clock6_out
);
	wire clkfb;
	// MMCME2_BASE: Base Mixed Mode Clock Manager 7 Series Xilinx HDL Language Template, version 2018.3
	MMCME2_BASE #(
		.STARTUP_WAIT("FALSE"), // Delays DONE until MMCM is locked (FALSE, TRUE)
		.BANDWIDTH("OPTIMIZED"), // Jitter programming (OPTIMIZED, HIGH, LOW)
		.REF_JITTER1(0.1), // Reference input jitter in UI (0.000-0.999).
		.DIVCLK_DIVIDE(D), // Master division value (1-106)
		.CLKFBOUT_MULT_F(M), // Multiply value for all CLKOUT (2.000-64.000).
		.CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
		.CLKIN1_PERIOD(CLOCK_PERIOD_NS), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		.CLKOUT0_DIVIDE_F(CLKOUT0_DIVIDE), // Divide amount for CLKOUT0 (1.000-128.000).
		// CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
		.CLKOUT1_DIVIDE(CLKOUT1_DIVIDE),
		.CLKOUT2_DIVIDE(CLKOUT2_DIVIDE),
		.CLKOUT3_DIVIDE(CLKOUT3_DIVIDE),
		.CLKOUT4_DIVIDE(CLKOUT4_DIVIDE),
		.CLKOUT5_DIVIDE(CLKOUT5_DIVIDE),
		.CLKOUT6_DIVIDE(CLKOUT6_DIVIDE),
		// CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5),
		.CLKOUT6_DUTY_CYCLE(0.5),
		// CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
		.CLKOUT0_PHASE(0.0),
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.CLKOUT6_PHASE(0.0),
		.CLKOUT4_CASCADE("FALSE") // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
	) MMCME2_BASE_inst (
		 .CLKOUT0(clock0_out_p), // 1-bit output: CLKOUT0
		.CLKOUT0B(clock0_out_n), // 1-bit output: Inverted CLKOUT0
		 .CLKOUT1(clock1_out_p), // 1-bit output: CLKOUT1
		.CLKOUT1B(clock1_out_n), // 1-bit output: Inverted CLKOUT1
		 .CLKOUT2(clock2_out_p), // 1-bit output: CLKOUT2
		.CLKOUT2B(clock2_out_n), // 1-bit output: Inverted CLKOUT2
		 .CLKOUT3(clock3_out_p), // 1-bit output: CLKOUT3
		.CLKOUT3B(clock3_out_n), // 1-bit output: Inverted CLKOUT3
		 .CLKOUT4(clock4_out), // 1-bit output: CLKOUT4
		 .CLKOUT5(clock5_out), // 1-bit output: CLKOUT5
		 .CLKOUT6(clock6_out), // 1-bit output: CLKOUT6
		.CLKFBOUT(clkfb), // 1-bit output: Feedback clock
		.CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
		.CLKFBIN(clkfb), // 1-bit input: Feedback clock
		.LOCKED(locked), // 1-bit output: LOCK
		.CLKIN1(clock_in), // 1-bit input: Clock
		.PWRDWN(1'b0), // 1-bit input: Power-down
		.RST(reset) // 1-bit input: Reset
	);
endmodule

// used in test062 (pynq/alpha) and test071 (ac701/prbs)
(* keep_hierarchy = "yes" *)
module MMCM_advanced #(
	parameter D = 1, // overall divide [1,106]
	parameter M = 10.0, // overall multiply [2.0,64.0]
	parameter CLKOUT0_DIVIDE = 1.0, // this one is fractional [1.0,128.0]
	parameter CLKOUT1_DIVIDE = 1, // [1,128]
	parameter CLKOUT2_DIVIDE = 1,
	parameter CLKOUT3_DIVIDE = 1,
	parameter CLKOUT4_DIVIDE = 1,
	parameter CLKOUT5_DIVIDE = 1,
	parameter CLKOUT6_DIVIDE = 1,
	parameter CLOCK1_PERIOD_NS = 10.0,
	parameter CLOCK2_PERIOD_NS = 10.0
) (
	input clock_in, // input=[10,800]MHz; PFD=[10,450]MHz; VCO=[600,1200]MHz; OUT=[4.69,800]MHz for a "-1" grade zynq-7020
	input reset,
	output locked,
	output clock0_out_p, clock0_out_n,
	output clock1_out_p, clock1_out_n,
	output clock2_out_p, clock2_out_n,
	output clock3_out_p, clock3_out_n,
	output clock4_out,
	output clock5_out,
	output clock6_out
);
	wire clkfb;
	wire [15:0] drp_DO, drp_DI;
	wire [6:0] drp_DADDR;
	wire drp_DCLK, drp_DEN, drp_DWE, drp_DRDY;
	assign drp_DCLK = 0;
	assign drp_DEN = 0;
	assign drp_DWE = 0;
	assign drp_DADDR = 0;
	assign drp_DI = 0;
	wire clk_fb;
	// MMCME2_ADV: Advanced Mixed Mode Clock Manager 7 Series
	// modified from Xilinx HDL Language Template, version 2023.2 (ug953)
	MMCME2_ADV #(
		.BANDWIDTH("OPTIMIZED"), // Jitter programming (OPTIMIZED, HIGH, LOW)
		.DIVCLK_DIVIDE(D), // Master division value (1-106)
		.CLKFBOUT_MULT_F(M), // Multiply value for all CLKOUT (2.000-64.000).
		.CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
		.CLKIN1_PERIOD(CLOCK1_PERIOD_NS), // CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		.CLKIN2_PERIOD(CLOCK2_PERIOD_NS),
		.CLKOUT0_DIVIDE_F(CLKOUT0_DIVIDE), // Divide amount for CLKOUT0 (1.000-128.000).
		.CLKOUT1_DIVIDE(CLKOUT1_DIVIDE), // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
		.CLKOUT2_DIVIDE(CLKOUT2_DIVIDE),
		.CLKOUT3_DIVIDE(CLKOUT3_DIVIDE),
		.CLKOUT4_DIVIDE(CLKOUT4_DIVIDE),
		.CLKOUT5_DIVIDE(CLKOUT5_DIVIDE),
		.CLKOUT6_DIVIDE(CLKOUT6_DIVIDE),
		.CLKOUT0_DUTY_CYCLE(0.5), // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5),
		.CLKOUT6_DUTY_CYCLE(0.5),
		.CLKOUT0_PHASE(0.0), // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.CLKOUT6_PHASE(0.0),
		.CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
		.COMPENSATION("ZHOLD"), // ZHOLD, BUF_IN, EXTERNAL, INTERNAL
		.REF_JITTER1(0.1), // REF_JITTER: Reference input jitter in UI (0.000-0.999).
		.REF_JITTER2(0.1),
		.STARTUP_WAIT("FALSE"), // Delays DONE until MMCM is locked (FALSE, TRUE)
		.SS_EN("FALSE"), // Enables spread spectrum (FALSE, TRUE)
		.SS_MODE("CENTER_HIGH"), // CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
		.SS_MOD_PERIOD(10000), // Spread spectrum modulation period (ns) (VALUES)
		.CLKFBOUT_USE_FINE_PS("FALSE"), // USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
		.CLKOUT0_USE_FINE_PS("FALSE"),
		.CLKOUT1_USE_FINE_PS("FALSE"),
		.CLKOUT2_USE_FINE_PS("FALSE"),
		.CLKOUT3_USE_FINE_PS("FALSE"),
		.CLKOUT4_USE_FINE_PS("FALSE"),
		.CLKOUT5_USE_FINE_PS("FALSE"),
		.CLKOUT6_USE_FINE_PS("FALSE")
	) MMCME2_ADV_inst (
		.RST(reset), // 1-bit input: Reset
		.DADDR(drp_DADDR), // 7-bit input: DRP address
		.DCLK(drp_DCLK), // 1-bit input: DRP clock
		.DEN(drp_DEN), // 1-bit input: DRP enable
		.DI(drp_DI), // 16-bit input: DRP data
		.DWE(drp_DWE), // 1-bit input: DRP write enable
		.CLKIN1(clock_in), // 1-bit input: Primary clock
		.CLKIN2(1'b0), // 1-bit input: Secondary clock
		.CLKFBIN(clk_fb), // 1-bit input: Feedback clock
		.CLKFBOUT(clk_fb), // 1-bit output: Feedback clock
		 .CLKOUT0(clock0_out_p), // 1-bit output: CLKOUT0
		.CLKOUT0B(clock0_out_n), // 1-bit output: Inverted CLKOUT0
		 .CLKOUT1(clock1_out_p), // 1-bit output: CLKOUT1
		.CLKOUT1B(clock1_out_n), // 1-bit output: Inverted CLKOUT1
		 .CLKOUT2(clock2_out_p), // 1-bit output: CLKOUT2
		.CLKOUT2B(clock2_out_n), // 1-bit output: Inverted CLKOUT2
		 .CLKOUT3(clock3_out_p), // 1-bit output: CLKOUT3
		.CLKOUT3B(clock3_out_n), // 1-bit output: Inverted CLKOUT3
		 .CLKOUT4(clock4_out), // 1-bit output: CLKOUT4
		 .CLKOUT5(clock5_out), // 1-bit output: CLKOUT5
		 .CLKOUT6(clock6_out), // 1-bit output: CLKOUT6
		.LOCKED(locked), // 1-bit output: LOCK
		.PSCLK(1'b0), // 1-bit input: Phase shift clock
		.PSEN(1'b0), // 1-bit input: Phase shift enable
		.PSINCDEC(1'b0), // 1-bit input: Phase shift increment/decrement
		.CLKINSEL(1'b1), // 1-bit input: Clock select, 1=CLKIN1 0=CLKIN2
		.PWRDWN(1'b0), // 1-bit input: Power-down
		.PSDONE(), // 1-bit output: Phase shift done
		.CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
		.CLKFBSTOPPED(), // 1-bit output: Feedback clock stopped
		.CLKINSTOPPED(), // 1-bit output: Input clock stopped
		.DO(drp_DO), // 16-bit output: DRP data
		.DRDY(drp_DRDY) // 1-bit output: DRP ready
	);
endmodule

`endif

