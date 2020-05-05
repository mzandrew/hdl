// lifted from https://github.com/thekroko/icezero-blinky.git
// last updated 2020-05-04 by mza

//`include "prescaler.v"
`include "lib/synchronizer.v"

module top (
	input clk_100mhz,
	input btn,
	output led1,
	output led2,
	output led3
);
	wire clk_16mhz, pll_locked;
`ifdef TESTBENCH
	assign clk_16mhz = clk_100mhz, pll_locked = 1;
`else
	SB_PLL40_PAD #(
		.FEEDBACK_PATH("SIMPLE"),
		.DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
		.DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
		.PLLOUT_SELECT("GENCLK"),
		.FDA_FEEDBACK(4'b1111),
		.FDA_RELATIVE(4'b1111),
		.DIVR(4'b0011),		// DIVR =  3
		.DIVF(7'b0101000),	// DIVF = 40
		.DIVQ(3'b110),		// DIVQ =  6
		.FILTER_RANGE(3'b010)	// FILTER_RANGE = 2
	) pll (
		.PACKAGEPIN   (clk_100mhz),
		.PLLOUTGLOBAL (clk_16mhz ),
		.LOCK         (pll_locked),
		.BYPASS       (1'b0      ),
		.RESETB       (1'b1      )
	);
`endif
	reg [23:0] counter = 0;
	if (1) begin
		wire button_clock;
		button_debounce #(.DEBOUNCE_CLOCK_PERIODS(1678)) bd (.clock(clk_16mhz), .button_raw(btn), .button_just_went_active(button_clock));
		always @(posedge button_clock) begin
			counter <= counter + 1'b1;
		end
		assign led1 = counter[2];
		assign led2 = counter[1];
		assign led3 = counter[0];
	end else begin
		always @(posedge clk_16mhz) begin
			counter <= counter + 1'b1;
		end
		assign led1 = counter[23];
		assign led2 = counter[22];
		assign led3 = counter[21];
	end
endmodule

