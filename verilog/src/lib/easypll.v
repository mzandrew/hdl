// written 2018-08-01 by mza
// use like so:
// easypll #(.DIVR(0), .DIVF(63), .DIVQ(3), .FILTER_RANGE(1)) my_pll_instance (.clock_input(CLK), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 96 MHz
// last updated 2018-08-01 by mza

// from arachne-pnr/tests/simple/sb_pll40_CORE.v
// and from reading SBTICETechnologyLibrary201504.pdf

// default output is 96 MHz, given  12 MHz input:
module easypll #(parameter DIVR=0, DIVF=63, DIVQ=3, FILTER_RANGE=1) (
input clock_input, reset_active_low,
//output [1:0] global_clock_output, [1:0] regular_clock_output, pll_is_locked
output global_clock_output, pll_is_locked
);
	//SB_PLL40_2_PAD #(
	SB_PLL40_CORE #(
		//.FEEDBACK_PATH("DELAY"), // default
		.FEEDBACK_PATH("SIMPLE"),
		//.FEEDBACK_PATH("PHASE_AND_DELAY"),
		//.FEEDBACK_PATH("EXTERNAL"),
//		.DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
		//.DELAY_ADJUSTMENT_MODE_FEEDBACK("DYNAMIC"),
//		.DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
		//.DELAY_ADJUSTMENT_MODE_RELATIVE("DYNAMIC"),
//		.PLLOUT_SELECT_PORTB("GENCLK"),
		//.PLLOUT_SELECT_PORTB("GENCLK_HALF"),
		//.PLLOUT_SELECT_PORTB("SHIFTREG_90deg"),
		//.PLLOUT_SELECT_PORTB("SHIFTREG_0deg"),
//		.SHIFTREG_DIV_MODE(1'b0),
//		.FDA_FEEDBACK(4'b1111),
//		.FDA_RELATIVE(4'b1111),
		.DIVR(DIVR),// 4
		.DIVF(DIVF), // 7
		.DIVQ(DIVQ), // 3
		.FILTER_RANGE(FILTER_RANGE), // 3
//		.ENABLE_ICEGATE_PORTA(1'b0),
//		.ENABLE_ICEGATE_PORTB(1'b0),
//		.TEST_MODE(1'b0)
	) my_pll_instance (
		//.PACKAGEPIN(clock_input_pin),
		.REFERENCECLK(clock_input),
		.PLLOUTGLOBAL(global_clock_output),
		//.PLLOUTGLOBALB(global_clock_output),
//		.PLLOUTCOREA(regular_clock_output[0]),
//		.PLLOUTCOREB(regular_clock_output[1]),
//		.EXTFEEDBACK(),
//		.DYNAMICDELAY(),
//		.BYPASS(0),
		.RESETB(reset_active_low),
//		.LATCHINPUTVALUE(),
//		.SDO(SDO),
//		.SDI(SDI),
//		.SCLK(SCLK),
		.LOCK(pll_is_locked)
	);
endmodule // mypll

