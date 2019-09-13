`timescale 1ns / 1ps
// written 2019-09-12 by mza
// based on mza_test031
// last updated 2019-09-12 by mza

module superkekb (
	input clock,
	input reset,
	output revo,
	output reg [7:0] revo_word
);
	reg reg_revo = 0;
	parameter number_of_quad_bunches_minus_one = 1280 - 1;
	reg [10:0] quad_bunch_counter = number_of_quad_bunches_minus_one;
	always @(posedge clock) begin
		if (reset) begin
			reg_revo <= 0;
			quad_bunch_counter <= number_of_quad_bunches_minus_one;
			revo_word <= 8'b00000000;
		end else begin
			if (quad_bunch_counter>0) begin
				quad_bunch_counter <= quad_bunch_counter - 1'b1;
				revo_word <= 8'b00000000;
				reg_revo <= 0;
			end else begin
				quad_bunch_counter <= number_of_quad_bunches_minus_one;
				revo_word <= 8'b11111111;
				reg_revo <= 1;
			end
		end
	end
	assign revo = reg_revo;
endmodule

