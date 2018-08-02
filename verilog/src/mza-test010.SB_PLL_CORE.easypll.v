// written 2018-08-01 by mza
// last updated 2018-08-01 by mza

`include "lib/easypll.v"

module top(input CLK, output J1_3, J1_10, LED5);
	wire fast_clock;
	wire pll_is_locked;
	assign J1_3 = fast_clock;
	reg [31:0] counter;
	wire divided_clock;
	assign divided_clock = counter[15];
	assign J1_10 = divided_clock;
	assign LED5 = pll_is_locked;
	//easypll #(.DIVR(0), .DIVF(63), .DIVQ(3), .FILTER_RANGE(1)) my_pll_instance (.clock_input(CLK), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 96 MHz
	easypll my_96MHz_pll_instance (.clock_input(CLK), .reset_active_low(1), .global_clock_output(fast_clock), .pll_is_locked(pll_is_locked)); // 96 MHz
	always @(posedge fast_clock) begin
		counter++;
	end
endmodule // top

