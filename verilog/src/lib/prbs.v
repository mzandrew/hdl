// written 2018-08-22 by mza
// idea stolen from http://fpgasrus.com/prbs.html
// last updated 2020-04-04 by mza

module prbs #(parameter WIDTH=128, TAP1=27, TAP2=30) (input clock, input reset, output reg [WIDTH-1:0] word);
	always @(posedge clock) begin
		if (reset==1) begin
			word <= 1;
		end else begin
			word <= { word[WIDTH-2:0], word[TAP1]^word[TAP2] };
		end
	end
endmodule // prbs

