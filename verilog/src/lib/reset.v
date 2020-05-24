// written 2020-05-23 by mza
// last updated 2020-05-23 by mza

//	reset #(.FREQUENCY(10000000)) myr (.upstream_clock(upstream_clock), .upstream_reset(upstream_reset), .downstream_pll_locked(downstream_pll_locked), .downstream_reset(downstream_reset));
module reset #(
	parameter FREQUENCY = 10000000.0,
	parameter PLL_LOCK_TIME = 0.05
) (
	input upstream_clock,
	input upstream_reset,
	input downstream_pll_locked,
	output downstream_reset
);
	// ln(freq*lock_t)/ln(2)
	//localparam significant_bit_number = $clog2(FREQUENCY*PLL_LOCK_TIME) + 2;
	localparam significant_bit_number = 25; // synthesis
	//localparam significant_bit_number = 4; // simulation
	reg [significant_bit_number:0] counterA = 0;
	reg [significant_bit_number:0] counterB = 0;
	reg internal_reset_state = 1;
	wire asychronous_reset_source = upstream_reset || (counterA[significant_bit_number]&&counterB[significant_bit_number]&&(~downstream_pll_locked));
	reg sychronous_reset_source = 1;
	assign downstream_reset = asychronous_reset_source || sychronous_reset_source;
	always @(posedge upstream_clock) begin
		if (upstream_reset) begin
			counterA <= 0;
//			downstream_reset <= 1;
			sychronous_reset_source <= 1;
			counterB <= 0;
			internal_reset_state <= 1;
		end else if (internal_reset_state) begin
			if (counterA[significant_bit_number]) begin
//				downstream_reset <= 0;
				sychronous_reset_source <= 0;
				if (counterB[significant_bit_number]) begin
					internal_reset_state <= 0;
				end else begin
					counterB <= counterB + 1'b1;
				end
			end else begin
				counterA <= counterA + 1'b1;
			end
		end else if (~downstream_pll_locked) begin
			counterA <= 0;
//			downstream_reset <= 1;
			sychronous_reset_source <= 1;
			counterB <= 0;
			internal_reset_state <= 1;
		end
//		if (synchronous_reset_source) begin
//		end
	end
//	always @(posedge upstream_clock, posedge upstream_reset, negedge downstream_pll_locked) begin
//		end
//	end
endmodule

//	reset #(.FREQUENCY(10000000)) myr (.upstream_clock(upstream_clock), .upstream_reset(upstream_reset), .downstream_pll_locked(downstream_pll_locked), .downstream_reset(downstream_reset));
module reset_try1_broken #(
	parameter FREQUENCY = 10000000.0,
	parameter PLL_LOCK_TIME = 0.05
) (
	input upstream_clock,
	input upstream_reset,
	input downstream_pll_locked,
	output reg downstream_reset = 1
);
	// ln(freq*lock_t)/ln(2)
	//localparam significant_bit_number = $clog2(FREQUENCY*PLL_LOCK_TIME) + 2;
	localparam significant_bit_number = 25;
	reg [significant_bit_number:0] counterA = 0;
	reg [significant_bit_number:0] counterB = 0;
	reg internal_reset_state = 1;
	always @(posedge upstream_clock, posedge upstream_reset, negedge downstream_pll_locked) begin
		if (upstream_reset) begin
			counterA <= 0;
			downstream_reset <= 1;
			counterB <= 0;
			internal_reset_state <= 1;
		end else if (internal_reset_state) begin
		//end else if (downstream_reset) begin
			if (counterA[significant_bit_number]) begin
				downstream_reset <= 0;
				if (counterB[significant_bit_number]) begin
					internal_reset_state <= 0;
				end else begin
					counterB <= counterB + 1'b1;
				end
			end else begin
				counterA <= counterA + 1'b1;
			end
		end else if (~downstream_pll_locked) begin
			counterA <= 0;
			downstream_reset <= 1;
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
	reset #(.FREQUENCY(10000000)) myr (.upstream_clock(upstream_clock), .upstream_reset(upstream_reset), .downstream_pll_locked(downstream_pll_locked), .downstream_reset(downstream_reset));
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
		$stop;
	end
	always begin
		#10;
		if (clock_enabled) begin
			upstream_clock <= ~upstream_clock;
		end
	end
endmodule

