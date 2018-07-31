// written 2018-06-29 by mza
// originally from file mza-test003.double-dabble.v
// last updated 2018-07-31 by mza

// implemented after watching computerphile video https://www.youtube.com/watch?v=eXIfZ1yKFlA
// each nybble in can be at most 15, which spans about 1.5 bcd nybbles, so 8 bits ("ff") -> 12 bits ("255")

module hex2bcd #(parameter input_size_in_nybbles = 2, input_size_in_bits = input_size_in_nybbles*4, output_size_in_bits = input_size_in_nybbles*6) (input clock, input reset, input [input_size_in_bits-1:0] hex_in, output reg [output_size_in_bits-1:0] bcd_out);
	localparam total_size_in_bits = input_size_in_bits + output_size_in_bits;
	reg [total_size_in_bits-1:0] shift_register; // size of input plus size of output
	reg [input_size_in_bits-1:0] bit_counter;
	integer offset = 0;
	always @(posedge clock) begin
		if (reset) begin
			bcd_out <= 0;
			bit_counter <= 0;
		end else begin
			if (bit_counter == 0) begin // bit_counter is 0
				bit_counter <= (input_size_in_bits << 1); // should be 16
				shift_register[input_size_in_bits-1:0] <= hex_in; // lower part
				shift_register[total_size_in_bits-1:input_size_in_bits] <= 0; // upper part
			end else if (bit_counter == 1) begin // bit_counter is 1
				bit_counter--;
				bcd_out <= shift_register[total_size_in_bits-1:input_size_in_bits]; // upper part
			end else begin
				if (bit_counter[0] == 0) begin // bit_counter is 18,16,14,12,10,8,6,4,2
					bit_counter--;
					shift_register[total_size_in_bits-1:1] <= shift_register[total_size_in_bits-2:0];
				end else begin // bit_counter is 17,15,13,11,9,7,5,3
					bit_counter--;
//					shift_register[0] <= 0; // not necessary because it ends before dealing with these
					for (offset = 0; offset < output_size_in_bits; offset = offset + 4) begin
						if (shift_register[input_size_in_bits+3+offset:input_size_in_bits+offset] >= 5) begin
							shift_register[input_size_in_bits+3+offset:input_size_in_bits+offset] <= shift_register[input_size_in_bits+3+offset:input_size_in_bits+offset] + 3; // add 3 to the nybble if >= 5; input nybble can be at most 4'b0111 because of being shifted in one bit at a time, so the result can be 4'b1010 at most which doesn't overflow
						end
					end
				end
			end
		end
	end
endmodule // hex2bcd

