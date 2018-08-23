// written 2018-08-22 by mza
// idea stolen from http://fpgasrus.com/prbs.html
// last updated 2018-08-22 by mza

module prbs #(parameter WIDTH=128, TAP1=27, TAP2=30) (input clock, input reset, output reg [WIDTH-1:0] word);
//	reg [WIDTH-1:0] temp;
	always @(posedge clock) begin
		if (reset==1) begin
			word <= 1;
		end else begin
			//temp = word; // blocking assignment
			//repeat (WIDTH) temp = { temp[WIDTH-2:1], temp[TAP1]^temp[TAP2] }; // blocking assignment
			word <= { word[WIDTH-1:0], word[TAP1]^word[TAP2] };
			//word <= temp;
		end
	end
endmodule // prbs

