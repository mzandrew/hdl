// written 2018-07-26 by mza
// taken from mza-test007.7-segment-driver.v
// last updated 2020-06-01 by mza

//	segmented_display_driver #(.NUMBER_OF_SEGMENTS(8), .NUMBER_OF_NYBBLES(8)) my_segmented_display_driver (.clock(clock), .data(buffered_bcd2[31:0]), .cathode(segment), .anode(anode), .sync_a(), .sync_c(), .dp(dp));
module segmented_display_driver #(
	parameter NUMBER_OF_SEGMENTS = 7,
	parameter NUMBER_OF_NYBBLES = 4,
	parameter LOG2_OF_NUMBER_OF_SEGMENTS = $clog2(NUMBER_OF_SEGMENTS),
	parameter LOG2_OF_NUMBER_OF_NYBBLES = $clog2(NUMBER_OF_NYBBLES)
) (
	input clock,
	input [NUMBER_OF_NYBBLES*4-1:0] data,
	output reg [NUMBER_OF_SEGMENTS-1:0] cathode = 0,
	output reg [NUMBER_OF_NYBBLES-1:0] anode = 0,
	output sync_a,
	output sync_c,
	input [NUMBER_OF_NYBBLES-1:0] dp
);
	localparam dot_clock_pickoff = 4;
	localparam nybble_clock_pickoff = dot_clock_pickoff + LOG2_OF_NUMBER_OF_SEGMENTS + 6; // the +6 makes the bug much less noticable
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
	wire [LOG2_OF_NUMBER_OF_NYBBLES-1:0] nybble_counter = raw_counter[LOG2_OF_NUMBER_OF_NYBBLES+nybble_clock_pickoff+1:nybble_clock_pickoff+1];
	wire [3:0] nybble [NUMBER_OF_NYBBLES-1:0];
	reg [NUMBER_OF_SEGMENTS-1:0] sequence [NUMBER_OF_NYBBLES-1:0];
	reg [NUMBER_OF_SEGMENTS-1:0] rawcathode = 0;
	reg [NUMBER_OF_NYBBLES-1:0] rawanode = 0;
	assign sync_a = anode[0];
	reg [NUMBER_OF_SEGMENTS-1:0] current_sequence = 0;
	integer i = 0;
	reg [NUMBER_OF_NYBBLES*4-1:0] buffered_data = 0;
	always @(posedge nybble_clock) begin
		cathode <= rawcathode;
		anode <= rawanode;
		rawanode <= 0;
		if (reset==0) begin
			rawanode[nybble_counter] <= 1;
			current_sequence <= sequence[nybble_counter];
			if (NUMBER_OF_SEGMENTS==16) begin
				for (i=0; i<=NUMBER_OF_NYBBLES-1; i=i+1) begin
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
			end else if (NUMBER_OF_SEGMENTS==8) begin
				for (i=0; i<=NUMBER_OF_NYBBLES-1; i=i+1) begin
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
				for (i=0; i<=NUMBER_OF_NYBBLES-1; i=i+1) begin
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
			buffered_data <= data;
		end
	end
	//generate
	genvar j;
	for (j=0; j<NUMBER_OF_NYBBLES; j=j+1) begin : charliplexer
		assign nybble[j] = buffered_data[4*j+3:4*j];
	end
	//endgenerate
	assign sync_c = dot_token[0];
	reg [NUMBER_OF_SEGMENTS-1:0] dot_token = 0;
	always @(posedge dot_clock) begin
//		if (NUMBER_OF_SEGMENTS==16) begin
//			cathode   <= 16'b1111111111111111;
//		end else if (NUMBER_OF_SEGMENTS==8) begin
//			cathode   <= 8'b11111111;
//		end else begin
//			cathode   <= 7'b1111111;
//		end
		if (reset) begin
			if (NUMBER_OF_SEGMENTS==16) begin
				dot_token <= 16'b0000000000000001;
			end else if (NUMBER_OF_SEGMENTS==8) begin
				dot_token <= 8'b00000001;
			end else begin
				dot_token <= 7'b0000001;
			end
		end else begin
			if (NUMBER_OF_SEGMENTS==16) begin
				case(dot_token)
					16'b0000000000000001 : rawcathode[00] <= current_sequence[15]; // set or clear segment a as appropriate
					16'b0000000000000010 : rawcathode[01] <= current_sequence[14]; // set or clear segment b as appropriate
					16'b0000000000000100 : rawcathode[02] <= current_sequence[13]; // set or clear segment c as appropriate
					16'b0000000000001000 : rawcathode[03] <= current_sequence[12]; // set or clear segment d as appropriate
					16'b0000000000010000 : rawcathode[04] <= current_sequence[11]; // set or clear segment e as appropriate
					16'b0000000000100000 : rawcathode[05] <= current_sequence[10]; // set or clear segment f as appropriate
					16'b0000000001000000 : rawcathode[06] <= current_sequence[09]; // set or clear segment g as appropriate
					16'b0000000010000000 : rawcathode[07] <= current_sequence[08]; // set or clear segment h as appropriate
					16'b0000000100000000 : rawcathode[08] <= current_sequence[07]; // set or clear segment k as appropriate
					16'b0000001000000000 : rawcathode[09] <= current_sequence[06]; // set or clear segment m as appropriate
					16'b0000010000000000 : rawcathode[10] <= current_sequence[05]; // set or clear segment n as appropriate
					16'b0000100000000000 : rawcathode[11] <= current_sequence[04]; // set or clear segment u as appropriate
					16'b0001000000000000 : rawcathode[12] <= current_sequence[03]; // set or clear segment p as appropriate
					16'b0010000000000000 : rawcathode[13] <= current_sequence[02]; // set or clear segment t as appropriate
					16'b0100000000000000 : rawcathode[14] <= current_sequence[01]; // set or clear segment s as appropriate
					default              : rawcathode[15] <= current_sequence[00]; // set or clear segment r as appropriate
				endcase
			end else if (NUMBER_OF_SEGMENTS==8) begin
				case(dot_token)
					8'b00000001 : rawcathode[0] <= current_sequence[7]; // set or clear segment a as appropriate
					8'b00000010 : rawcathode[1] <= current_sequence[6]; // set or clear segment b as appropriate
					8'b00000100 : rawcathode[2] <= current_sequence[5]; // set or clear segment c as appropriate
					8'b00001000 : rawcathode[3] <= current_sequence[4]; // set or clear segment d as appropriate
					8'b00010000 : rawcathode[4] <= current_sequence[3]; // set or clear segment e as appropriate
					8'b00100000 : rawcathode[5] <= current_sequence[2]; // set or clear segment f as appropriate
					8'b01000000 : rawcathode[6] <= current_sequence[1]; // set or clear segment g as appropriate
					default     : rawcathode[7] <= current_sequence[0]; // set or clear segment dp as appropriate
				endcase
			end else begin
				case(dot_token)
					7'b0000001 : rawcathode[0] <= current_sequence[6]; // set or clear segment a as appropriate
					7'b0000010 : rawcathode[1] <= current_sequence[5]; // set or clear segment b as appropriate
					7'b0000100 : rawcathode[2] <= current_sequence[4]; // set or clear segment c as appropriate
					7'b0001000 : rawcathode[3] <= current_sequence[3]; // set or clear segment d as appropriate
					7'b0010000 : rawcathode[4] <= current_sequence[2]; // set or clear segment e as appropriate
					7'b0100000 : rawcathode[5] <= current_sequence[1]; // set or clear segment f as appropriate
					default    : rawcathode[6] <= current_sequence[0]; // set or clear segment g as appropriate
				endcase
			end
			dot_token <= { dot_token[NUMBER_OF_SEGMENTS-2:0], dot_token[NUMBER_OF_SEGMENTS-1] }; // barrel shifter
		end
	end
endmodule // segmented_display_driver

module segmented_display_driver_tb;
//module testbench;
	localparam NUMBER_OF_SEGMENTS = 7;
	localparam NUMBER_OF_NYBBLES = 2;
	reg clock = 0;
	reg [7:0] data = 0;
	wire [NUMBER_OF_SEGMENTS-1:0] cathode;
	wire [NUMBER_OF_NYBBLES-1:0] anode;
	wire [NUMBER_OF_NYBBLES-1:0] dp;
	segmented_display_driver #(.NUMBER_OF_SEGMENTS(NUMBER_OF_SEGMENTS), .NUMBER_OF_NYBBLES(NUMBER_OF_NYBBLES)) my_segmented_display_driver (.clock(clock), .data(data), .cathode(cathode), .anode(anode), .sync_a(), .sync_c(), .dp(dp));
	initial begin
		#1000;
		data <= 8'h80;
		#2000000;
		data <= 8'h71;
		#2000000;
		data <= 8'h94;
	end
	always begin
		#10;
		clock = ~clock;
	end
endmodule

