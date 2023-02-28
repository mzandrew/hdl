`timescale 1ns / 1ps

// written 2023-02-21 by mza
// last updated 2023-02-28 by mza

module test002(
	input clock, input reset,
	input pulse1, pulse2,
	output reg [7:0] count1 = 0,
	output reg [7:0] count2 = 0
);
	reg [2:0] shift_reg1 = 0;
	reg [2:0] shift_reg2 = 0;
	always @(posedge clock) begin
		if (reset) begin
			count1 <= 0;
			count2 <= 0;
		end else begin
			if (shift_reg1[2:1]==2'b01) begin
				count1 <= count1 + 1'b1;
			end
			if (shift_reg2[2:1]==2'b01) begin
				count2 <= count2 + 1'b1;
			end
			shift_reg1 <= { shift_reg1[1:0], pulse1 };
			shift_reg2 <= { shift_reg2[1:0], pulse2 };
		end	
	end
endmodule

module test002_tb;
	localparam half_clock_period = 4;
	reg clock = 0;
	reg reset = 0;
	reg pulse1 = 0;
	reg pulse2 = 0;
	wire [7:0] count1;
	wire [7:0] count2;
	always begin
		clock <= 1'b0;
		#half_clock_period;
		clock <= 1'b1;
		#half_clock_period;
	end
	test002 blah (.clock(clock), .reset(reset), .pulse1(pulse1), .pulse2(pulse2), .count1(count1), .count2(count2));
	initial begin
		reset <= 0;
		pulse1 <= 0;
		pulse2 <= 0;
		#10;
		reset <= 1'b1; #10; reset <= 1'b0;
		#50; pulse1 <= 1'b1; #8; pulse1 <= 1'b0;
		#40; pulse1 <= 1'b1; #12; pulse1 <= 1'b0;
		#15; pulse1 <= 1'b1; #8; pulse1 <= 1'b0;
		#25; pulse1 <= 1'b1; #12; pulse1 <= 1'b0;
		#100;
		#50; pulse2 <= 1'b1; #18; pulse2 <= 1'b0;
		#30; pulse2 <= 1'b1; #16; pulse2 <= 1'b0;
		#12; pulse2 <= 1'b1; #12; pulse2 <= 1'b0;
	end
endmodule
