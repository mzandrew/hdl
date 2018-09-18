`timescale 1ns / 1ps
// written 2018-09-17 by mza
// last updated 2018-09-17 by mza

module mytop(
	input clock_p,
	input clock_n,
	output ttl_trig_output
	//output lvds_trig_output_p,
	//output lvds_trig_output_n
);
	reg trigout;
	assign ttl_trig_output = trigout;
	wire clock;
	IBUFGDS clockbuf (.I(clock_p), .IB(clock_n), .O(clock));
	always @(posedge clock) begin
		trigout <= ~ trigout;
	end
endmodule

