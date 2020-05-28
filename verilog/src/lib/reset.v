// written 2020-05-23 by mza
// last updated 2020-05-27 by mza

//	reset #(.FREQUENCY(10000000)) myr (.upstream_clock(), .upstream_reset(), .downstream_pll_locked(), .downstream_reset());
module reset #(
	parameter FREQUENCY = 10000000.0, // in Hertz
	parameter PLL_LOCK_TIME = 0.05, // in seconds
	parameter SYNCHRONOUS_ONLY = 1,
	parameter SIGNIFICANT_BIT_NUMBER_B = $clog2(FREQUENCY*PLL_LOCK_TIME) + 1, // synthesis
//	parameter SIGNIFICANT_BIT_NUMBER_B = 5, // simulation
	parameter SIGNIFICANT_BIT_NUMBER_A = SIGNIFICANT_BIT_NUMBER_B/4
) (
	input upstream_clock,
	input upstream_reset,
	input downstream_pll_locked,
	output downstream_reset
);
	reg [SIGNIFICANT_BIT_NUMBER_A:0] counterA = 0;
	reg [SIGNIFICANT_BIT_NUMBER_B:0] counterB = 0;
	reg internal_reset_state = 1;
	reg sychronous_reset_source = 1;
	if (SYNCHRONOUS_ONLY) begin
		//assign asychronous_reset_source = upstream_reset;
		//assign asychronous_reset_source = 0;
		assign downstream_reset = sychronous_reset_source;
	end else begin
		wire asychronous_reset_source;
		assign asychronous_reset_source = upstream_reset || (counterB[SIGNIFICANT_BIT_NUMBER_B]&&(~downstream_pll_locked));
		assign downstream_reset = asychronous_reset_source || sychronous_reset_source;
	end
	always @(posedge upstream_clock) begin
		if (upstream_reset) begin
			counterA <= 0;
			sychronous_reset_source <= 1;
			counterB <= 0;
			internal_reset_state <= 1;
		end else if (internal_reset_state) begin
			if (counterA[SIGNIFICANT_BIT_NUMBER_A]) begin
				sychronous_reset_source <= 0;
				if (counterB[SIGNIFICANT_BIT_NUMBER_B]) begin
					internal_reset_state <= 0;
				end else begin
					counterB <= counterB + 1'b1;
				end
			end else begin
				counterA <= counterA + 1'b1;
			end
		end else if (~downstream_pll_locked) begin
			counterA <= 0;
			sychronous_reset_source <= 1;
			counterB <= 0;
			internal_reset_state <= 1;
		end
	end
endmodule

module reset_tb();
	reg clock_enabled = 1;
	reg upstream_clock = 0;
	reg upstream_reset = 0;
	reg downstream_pll_locked = 0;
	wire downstream_reset;
	reset #(.FREQUENCY(10000000), .SIGNIFICANT_BIT_NUMBER_B(5)) myr (.upstream_clock(upstream_clock), .upstream_reset(upstream_reset), .downstream_pll_locked(downstream_pll_locked), .downstream_reset(downstream_reset));
	initial begin
		// power-on reset
		#200; downstream_pll_locked <= 1;
		#1000; // ------------------------------------------------------------
		// global reset
		upstream_reset <= 1;
		#20; downstream_pll_locked <= 0;
		#100; upstream_reset <= 0;
		#200; downstream_pll_locked <= 1;
		#1000; // ------------------------------------------------------------
		// pll loses lock
		#100; downstream_pll_locked <= 0;
		#1000; // pretend the pll doesn't lock immediately
		#200; downstream_pll_locked <= 1;
		#1000;
		#1000; // ------------------------------------------------------------
		// losing pll lock after clock disappears
		#100; clock_enabled <= 0;
		#100; downstream_pll_locked <= 0;
		#100;
		#1000; // ------------------------------------------------------------
		$finish;
	end
	always begin
		#10;
		if (clock_enabled) begin
			upstream_clock <= ~upstream_clock;
		end
	end
endmodule

