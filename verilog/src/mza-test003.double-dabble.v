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
			bcd_out <= 0;
			bit_counter <= 0;
		end else begin
//			bcd_out <= bit_counter;
//			bcd_out[7:0] <= hex_in;
			if (bit_counter == 0) begin
				bit_counter <= (input_size_in_bits << 1) + 1; // should be 17
				shift_register[input_size_in_bits-1:0] <= hex_in; // lower part
				shift_register[total_size_in_bits-1:input_size_in_bits] <= 0; // upper part
			end else if (bit_counter == 1) begin
				bit_counter--;
				bcd_out <= shift_register[total_size_in_bits-1:input_size_in_bits]; // upper part
			end else begin
				if (bit_counter[0]==1) begin
					bit_counter--;
					shift_register[total_size_in_bits-1:1] <= shift_register[total_size_in_bits-2:0];
					//shift_register[input_size_in_bits+7:input_size_in_bits] <= hex_in;
				end else begin
					bit_counter--;
//					shift_register[0] <= 0;
					for (offset = 0; offset < output_size_in_bits; offset = offset + 4)
						if (shift_register[input_size_in_bits+3+offset:input_size_in_bits+offset] >= 5) begin
							shift_register[input_size_in_bits+3+offset:input_size_in_bits+offset] <= shift_register[input_size_in_bits+3+offset:input_size_in_bits+offset] + 3; // add 3 to the nybble if >= 5; input nybble can be at most 4'b0111 because of being shifted in one bit at a time, so the result can be 4'b1010 at most which doesn't overflow
						end
				end
			end
		end
	end
endmodule // bcd2hex

module top(input CLK, input J3_3, output LED5, output LED4, output LED3, output LED2, output LED1);
	reg [11:0] bcd;
	reg [31:0] counter;
	wire reset;
	always @(posedge CLK) begin
		if (counter[31:24]==0) begin
			reset <= 1;
		end else begin
			reset <= 0;
		end
		counter++;
	end
	hex2bcd h2binst ( .clock(CLK), .reset(reset), .hex_in(counter[31:24]), .bcd_out(bcd) );
	assign LED5 = bcd[4];
	assign LED4 = bcd[3];
	assign LED3 = bcd[2];
	assign LED2 = bcd[1];
	assign LED1 = bcd[0];
//	assign LED5 = counter[28];
//	assign LED4 = counter[27];
//	assign LED3 = counter[26];
//	assign LED2 = counter[25];
//	assign LED1 = counter[24];
endmodule // top

