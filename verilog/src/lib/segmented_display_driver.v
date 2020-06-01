// written 2018-07-26 by mza
// taken from mza-test007.7-segment-driver.v
// last updated 2020-05-31 by mza

module segmented_display_driver #(
	parameter number_of_segments = 7,
	parameter number_of_nybbles = 4
) (
	input clock,
	input [number_of_nybbles*4-1:0] data,
	output reg [number_of_segments-1:0] cathode = 0,
	output reg [number_of_nybbles-1:0] anode = 0,
	output sync_a,
	output sync_c,
	input [number_of_nybbles-1:0] dp
);
	localparam dot_clock_pickoff = 4;
	localparam log2_of_number_of_segments = $clog2(number_of_segments);
	localparam nybble_clock_pickoff = dot_clock_pickoff + log2_of_number_of_segments + 6; // the +6 makes the bug much less noticable
	localparam log2_of_number_of_nybbles = $clog2(number_of_nybbles);
	localparam raw_counter_size = 32;
	localparam log2_of_reset_duration = dot_clock_pickoff; // otherwise, the dot_token never gets set properly
	reg reset = 1;
	reg [raw_counter_size-1:0] raw_counter = 0;
	always @(posedge clock) begin
		if (reset) begin
			if (raw_counter[log2_of_reset_duration]) begin
				reset <= 0;
			end
		end
		raw_counter <= raw_counter + 1'b1;
	end
	wire dot_clock = raw_counter[dot_clock_pickoff];
	wire nybble_clock = raw_counter[nybble_clock_pickoff];
	wire [log2_of_number_of_nybbles-1:0] nybble_counter = raw_counter[log2_of_number_of_nybbles+nybble_clock_pickoff+1:nybble_clock_pickoff+1];
	reg [3:0] nybble [number_of_nybbles-1:0];
	reg [number_of_segments-1:0] sequence [number_of_nybbles-1:0];
	assign sync_a = anode[0];
	reg [number_of_segments-1:0] current_sequence = 0;
	integer i = 0;
	always @(posedge nybble_clock) begin
		anode <= 0;
		if (reset==0) begin
			anode[nybble_counter] <= 1;
			current_sequence <= sequence[nybble_counter];
			if (number_of_segments==16) begin
				for (i=0; i<=number_of_nybbles-1; i=i+1) begin
					case(nybble[i])
						4'h0    : sequence[i] <= 16'b0000000011111111;
						4'h1    : sequence[i] <= 16'b1100111111111111;
						4'h2    : sequence[i] <= 16'b0001000111100111;
						4'h3    : sequence[i] <= 16'b0000001111100111;
						4'h4    : sequence[i] <= 16'b1100111011100111;
						4'h5    : sequence[i] <= 16'b0010001011100111;
						4'h6    : sequence[i] <= 16'b0010000011100111;
						4'h7    : sequence[i] <= 16'b0000111111111111;
						4'h8    : sequence[i] <= 16'b0000000011100111;
						4'h9    : sequence[i] <= 16'b0000001011100111;
						4'ha    : sequence[i] <= 16'b0000110011100111;
						4'hb    : sequence[i] <= 16'b1110000011100111;
						4'hc    : sequence[i] <= 16'b0011000011111111;
						4'hd    : sequence[i] <= 16'b1100000111100111;
						4'he    : sequence[i] <= 16'b0011000011101111;
						default : sequence[i] <= 16'b0011110011101111;
					endcase
				end
			end else if (number_of_segments==8) begin
				for (i=0; i<=number_of_nybbles-1; i=i+1) begin
					case(nybble[i])
						4'h0    : sequence[i] <= { ~dp[i], 7'b0000001 };
						4'h1    : sequence[i] <= { ~dp[i], 7'b1001111 };
						4'h2    : sequence[i] <= { ~dp[i], 7'b0010010 };
						4'h3    : sequence[i] <= { ~dp[i], 7'b0000110 };
						4'h4    : sequence[i] <= { ~dp[i], 7'b1001100 };
						4'h5    : sequence[i] <= { ~dp[i], 7'b0100100 };
						4'h6    : sequence[i] <= { ~dp[i], 7'b0100000 };
						4'h7    : sequence[i] <= { ~dp[i], 7'b0001111 };
						4'h8    : sequence[i] <= { ~dp[i], 7'b0000000 };
						4'h9    : sequence[i] <= { ~dp[i], 7'b0000100 };
						4'ha    : sequence[i] <= { ~dp[i], 7'b0001000 };
						4'hb    : sequence[i] <= { ~dp[i], 7'b1100000 };
						4'hc    : sequence[i] <= { ~dp[i], 7'b1110010 };
						4'hd    : sequence[i] <= { ~dp[i], 7'b1000010 };
						4'he    : sequence[i] <= { ~dp[i], 7'b0110000 };
						default : sequence[i] <= { ~dp[i], 7'b0111000 };
					endcase
				end
			end else begin
				for (i=0; i<=number_of_nybbles-1; i=i+1) begin
					case(nybble[i])
						4'h0    : sequence[i] <= 7'b0000001;
						4'h1    : sequence[i] <= 7'b1001111;
						4'h2    : sequence[i] <= 7'b0010010;
						4'h3    : sequence[i] <= 7'b0000110;
						4'h4    : sequence[i] <= 7'b1001100;
						4'h5    : sequence[i] <= 7'b0100100;
						4'h6    : sequence[i] <= 7'b0100000;
						4'h7    : sequence[i] <= 7'b0001111;
						4'h8    : sequence[i] <= 7'b0000000;
						4'h9    : sequence[i] <= 7'b0000100;
						4'ha    : sequence[i] <= 7'b0001000;
						4'hb    : sequence[i] <= 7'b1100000;
						4'hc    : sequence[i] <= 7'b1110010;
						4'hd    : sequence[i] <= 7'b1000010;
						4'he    : sequence[i] <= 7'b0110000;
						default : sequence[i] <= 7'b0111000;
					endcase
				end
			end
			for (i=0; i<number_of_nybbles; i=i+1) begin
				nybble[i] <= data[4*i+3:4*i];
			end
		end
	end
	assign sync_c = dot_token[0];
	reg [number_of_segments-1:0] dot_token = 0;
	always @(posedge dot_clock) begin
//		if (number_of_segments==16) begin
//			cathode   <= 16'b1111111111111111;
//		end else if (number_of_segments==8) begin
//			cathode   <= 8'b11111111;
//		end else begin
//			cathode   <= 7'b1111111;
//		end
		if (reset) begin
			if (number_of_segments==16) begin
				dot_token <= 16'b0000000000000001;
			end else if (number_of_segments==8) begin
				dot_token <= 8'b00000001;
			end else begin
				dot_token <= 7'b0000001;
			end
		end else begin
			if (number_of_segments==16) begin
				case(dot_token)
					16'b0000000000000001 : cathode[00] <= current_sequence[15]; // set or clear segment a as appropriate
					16'b0000000000000010 : cathode[01] <= current_sequence[14]; // set or clear segment b as appropriate
					16'b0000000000000100 : cathode[02] <= current_sequence[13]; // set or clear segment c as appropriate
					16'b0000000000001000 : cathode[03] <= current_sequence[12]; // set or clear segment d as appropriate
					16'b0000000000010000 : cathode[04] <= current_sequence[11]; // set or clear segment e as appropriate
					16'b0000000000100000 : cathode[05] <= current_sequence[10]; // set or clear segment f as appropriate
					16'b0000000001000000 : cathode[06] <= current_sequence[09]; // set or clear segment g as appropriate
					16'b0000000010000000 : cathode[07] <= current_sequence[08]; // set or clear segment h as appropriate
					16'b0000000100000000 : cathode[08] <= current_sequence[07]; // set or clear segment k as appropriate
					16'b0000001000000000 : cathode[09] <= current_sequence[06]; // set or clear segment m as appropriate
					16'b0000010000000000 : cathode[10] <= current_sequence[05]; // set or clear segment n as appropriate
					16'b0000100000000000 : cathode[11] <= current_sequence[04]; // set or clear segment u as appropriate
					16'b0001000000000000 : cathode[12] <= current_sequence[03]; // set or clear segment p as appropriate
					16'b0010000000000000 : cathode[13] <= current_sequence[02]; // set or clear segment t as appropriate
					16'b0100000000000000 : cathode[14] <= current_sequence[01]; // set or clear segment s as appropriate
					default              : cathode[15] <= current_sequence[00]; // set or clear segment r as appropriate
				endcase
			end else if (number_of_segments==8) begin
				case(dot_token)
					8'b00000001 : cathode[0] <= current_sequence[7]; // set or clear segment a as appropriate
					8'b00000010 : cathode[1] <= current_sequence[6]; // set or clear segment b as appropriate
					8'b00000100 : cathode[2] <= current_sequence[5]; // set or clear segment c as appropriate
					8'b00001000 : cathode[3] <= current_sequence[4]; // set or clear segment d as appropriate
					8'b00010000 : cathode[4] <= current_sequence[3]; // set or clear segment e as appropriate
					8'b00100000 : cathode[5] <= current_sequence[2]; // set or clear segment f as appropriate
					8'b01000000 : cathode[6] <= current_sequence[1]; // set or clear segment g as appropriate
					default     : cathode[7] <= current_sequence[0]; // set or clear segment dp as appropriate
				endcase
			end else begin
				case(dot_token)
					7'b0000001 : cathode[0] <= current_sequence[6]; // set or clear segment a as appropriate
					7'b0000010 : cathode[1] <= current_sequence[5]; // set or clear segment b as appropriate
					7'b0000100 : cathode[2] <= current_sequence[4]; // set or clear segment c as appropriate
					7'b0001000 : cathode[3] <= current_sequence[3]; // set or clear segment d as appropriate
					7'b0010000 : cathode[4] <= current_sequence[2]; // set or clear segment e as appropriate
					7'b0100000 : cathode[5] <= current_sequence[1]; // set or clear segment f as appropriate
					default    : cathode[6] <= current_sequence[0]; // set or clear segment g as appropriate
				endcase
			end
			dot_token <= { dot_token[number_of_segments-2:0], dot_token[number_of_segments-1] }; // barrel shifter
		end
	end
endmodule // segmented_display_driver

