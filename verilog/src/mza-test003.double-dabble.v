// written 2018-06-29 by mza
// last updated 2018-07-30 by mza

`include "lib/hex2bcd.v"

module top(input CLK, input J3_3, output LED5, output LED4, output LED3, output LED2, output LED1);
	reg [11:0] bcd;
	reg [31:0] counter;
	wire reset;
	always @(posedge CLK) begin
		if (counter[31:16]==0) begin
			reset <= 1;
		end else begin
			reset <= 0;
		end
		counter++;
	end
	hex2bcd h2binst ( .clock(CLK), .reset(reset), .hex_in(counter[31:24]), .bcd_out(bcd) );
	if (1) begin
		assign LED5 = bcd[4];
		assign LED4 = bcd[3];
		assign LED3 = bcd[2];
		assign LED2 = bcd[1];
		assign LED1 = bcd[0];
	end else begin
		assign LED5 = 0;
		assign LED4 = bcd[7];
		assign LED3 = bcd[6];
		assign LED2 = bcd[5];
		assign LED1 = bcd[4];
	end
endmodule // top

