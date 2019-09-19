`timescale 1ns / 1ps
// written 2019-09-22 by mza
// last updated 2019-09-22 by mza

module mux #(
	parameter WIDTH = 1
) (
	input S,
	input [WIDTH-1:0] I0, I1,
	output [WIDTH-1:0] O
);
	assign O = S ? I1 : I0;
endmodule

