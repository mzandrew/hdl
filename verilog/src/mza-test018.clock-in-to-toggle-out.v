`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2018-09-18 by mza

module mytop(
	input clock_p,
	input clock_n,
	output ttl_trig_output,
	output led0,
	output led1,
	output led2
	//output lvds_trig_output_p,
	//output lvds_trig_output_n
);
	reg trigout;
	assign ttl_trig_output = trigout;
	wire clock;
	reg [31:0] counter;
	assign led0 = counter[28];
	assign led1 = reset;
	assign led2 = ~reset;
	reg reset = 1;
	IBUFGDS clockbuf (.I(clock_p), .IB(clock_n), .O(clock)); // 250 MHz
	always @(posedge clock) begin
		if (reset) begin
			if (counter[10]) begin
				reset = 0;
			end
		end
		trigout <= ~ trigout;
		counter <= counter + 1;
	end
endmodule
