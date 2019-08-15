// written 2019-08-14 by mza
// taken from info in ug382/ug615/ds162

module simplepll #(parameter overall_divide=1, multiply=4, divide=1, period=10.0, compensation="SYSTEM_SYNCHRONOUS") (
	input clockin,
	input reset,
	output clockout,
	output locked
);
	wire CLKFBIN;
	wire CLKFBOUT;
	BUFG mybufg (.I(CLKFBOUT), .O(CLKFBIN));
	PLL_BASE #(
		.BANDWIDTH("OPTIMIZED"), // "HIGH", "LOW" or "OPTIMIZED"
		.CLKFBOUT_MULT(multiply), // Multiplication factor for all output clocks
		.CLKFBOUT_PHASE(0.0), // Phase shift (degrees) of all output clocks
		.CLKIN_PERIOD(period), // Clock period (ns) of input clock on CLKIN
		.CLKOUT0_DIVIDE(divide), // Division factor for CLKOUT0 (1 to 128)
		.CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.01 to 0.99)
		.CLKOUT0_PHASE(0.0), // Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
		.CLKOUT1_DIVIDE(1), // Division factor for CLKOUT1 (1 to 128)
		.CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT1 (0.01 to 0.99)
		.CLKOUT1_PHASE(0.0), // Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
		.CLKOUT2_DIVIDE(1), // Division factor for CLKOUT2 (1 to 128)
		.CLKOUT2_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT2 (0.01 to 0.99)
		.CLKOUT2_PHASE(0.0), // Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
		.CLKOUT3_DIVIDE(1), // Division factor for CLKOUT3 (1 to 128)
		.CLKOUT3_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT3 (0.01 to 0.99)
		.CLKOUT3_PHASE(0.0), // Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
		.CLKOUT4_DIVIDE(1), // Division factor for CLKOUT4 (1 to 128)
		.CLKOUT4_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT4 (0.01 to 0.99)
		.CLKOUT4_PHASE(0.0), // Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
		.CLKOUT5_DIVIDE(1), // Division factor for CLKOUT5 (1 to 128)
		.CLKOUT5_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT5 (0.01 to 0.99)
		.CLKOUT5_PHASE(0.0), // Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
		.COMPENSATION(compensation), // "SYSTEM_SYNCHRONOUS",
		// "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL",
		// "DCM2PLL", "PLL2DCM"
		.DIVCLK_DIVIDE(overall_divide), // Division factor for all clocks (1 to 52)
		.REF_JITTER(0.100) // Input reference jitter (0.000 to 0.999 UI%)
	) PLL_BASE_inst (
		.CLKFBOUT(CLKFBOUT), // General output feedback signal
		.CLKOUT0(clockout), // One of six general clock output signals
		.CLKOUT1(), // One of six general clock output signals
		.CLKOUT2(), // One of six general clock output signals
		.CLKOUT3(), // One of six general clock output signals
		.CLKOUT4(), // One of six general clock output signals
		.CLKOUT5(), // One of six general clock output signals
		.LOCKED(locked), // Active high PLL lock signal
		.CLKFBIN(CLKFBIN), // Clock feedback input
		.CLKIN(clockin), // Clock input
		.RST(reset) // Asynchronous PLL reset
	);
endmodule

module simpledcm #(parameter multiply=4, divide=1, period="10.0") (
	input clockin,
	input reset,
	output clockout,
	output clockout180,
	output locked
);
	DCM_CLKGEN #(
		.CLKFXDV_DIVIDE(2), // Specifies divide value for CLKFXDV.
		.CLKFX_DIVIDE(divide), // This value in conjunction with the input frequency and CLKFX_MULTIPLY
		// value determine the resultant output frequency for the CLKFX and
		// CLKFX180 outputs.
		.CLKFX_MD_MAX(0.0), // When using the DCM_CLKGEN with variable M and D values, this would
		// specify the maximum ratio of M and D used during static timing
		// analysis to ensure proper timing of the DCM output.
		.CLKFX_MULTIPLY(multiply), // This value in conjunction with the input frequency and CLKFX_DIVIDE
		// value determine the resultant output frequency for the CLKFX and
		// CLKFX180 outputs.
		.CLKIN_PERIOD(period), // This attribute specifies the source clock period which is used to
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

module plldcm #(parameter overall_divide=1, pllmultiply=1, plldivide=1, pllperiod=10.0, dcmmultiply=1, dcmdivide=1, dcmperiod="10.0") (
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
	simplepll #(.overall_divide(overall_divide), .multiply(pllmultiply), .divide(plldivide), .period(pllperiod), .compensation("PLL2DCM")) mypll (
		.clockin(clockin),
		.reset(reset),
		.clockout(clockintermediate),
		.locked(plllocked));
	simpledcm #(.multiply(dcmmultiply), .divide(dcmdivide), .period(dcmperiod)) mydcm (
		.clockin(clockintermediate),
		.reset(reset),
		.clockout(clockout),
		.clockout180(clockout180),
		.locked(dcmlocked));
endmodule

