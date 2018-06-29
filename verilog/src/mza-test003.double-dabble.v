// written 2018-06-29 by mza
// last updated 2018-06-29 by mza

// implemented after watching computerphile video https://www.youtube.com/watch?v=eXIfZ1yKFlA
// each nybble in can be at most 15, which spans about 1.5 bcd nybbles, so 8 bits ("ff") -> 12 bits ("255")

module hex2bcd(input clock, input reset, input [7:0] hex_in, output reg [11:0] bcd_out);
	parameter input_size_in_bits = 8;
	parameter output_size_in_bits = 12;
	parameter total_size_in_bits = input_size_in_bits + output_size_in_bits;
	reg [total_size_in_bits-1:0] shift_register; // size of input plus size of output
	reg [7:0] bit_counter;
	integer offset = 0;
	always @(posedge clock) begin
		if (reset) begin
			bit_counter <= input_size_in_bits;
			shift_register[input_size_in_bits-1:0] <= hex_in; // lower part
			shift_register[total_size_in_bits-1:input_size_in_bits-1] <= 0; // upper part
			bcd_out <= 0;
		end else begin
			if (bit_counter == 0) begin
				bcd_out <= shift_register[total_size_in_bits-1:input_size_in_bits]; // upper part
			end else begin
				bit_counter--;
				shift_register[total_size_in_bits-1:1] <= shift_register[total_size_in_bits-2:0];
				shift_register[0] <= 1'b0;
				for (offset = 0; offset <= 8; offset = offset + 4)
					if (shift_register[input_size_in_bits+3+offset:input_size_in_bits+offset] >= 5) begin
						shift_register[input_size_in_bits+3+offset:input_size_in_bits+offset] <= shift_register[input_size_in_bits+3+offset:input_size_in_bits+offset] + 3; // add 3 if >= 5
					end
			end
		end
	end
endmodule // bcd2hex

module top(input CLK, input J3_3, output LED5, output LED4, output LED3, output LED2, output LED1);
	reg [11:0] bcd;
	hex2bcd h2binst ( .clock(CLK), .reset(J3_3), .hex_in(11), .bcd_out(bcd) );
	assign LED4 = bcd[3];
	assign LED3 = bcd[2];
	assign LED2 = bcd[1];
	assign LED1 = bcd[0];
	assign LED5 = J3_3;
endmodule // top

