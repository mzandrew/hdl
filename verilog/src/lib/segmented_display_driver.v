// written 2018-07-26 by mza
// taken from mza-test007.7-segment-driver.v
// last updated 2018-07-31 by mza

module segmented_display_driver #(parameter number_of_segments=7, number_of_nybbles=4) (input clock, input [number_of_nybbles*4-1:0] data, output [number_of_segments-1:0] cathode, output [number_of_nybbles-1:0] anode);
	localparam dot_clock_pickoff = 3;
	localparam overestimate_of_log2_of_number_of_segments = $clog2(number_of_segments);
	localparam nybble_clock_pickoff = dot_clock_pickoff + overestimate_of_log2_of_number_of_segments + 1;
	localparam log2_of_number_of_nybbles = $clog2(number_of_nybbles);
	localparam update_clock_pickoff = nybble_clock_pickoff + log2_of_number_of_nybbles + 1;
	localparam raw_counter_size = update_clock_pickoff + 3; // just for the hell of it
	localparam log2_of_reset_duration = 10;
	wire reset;
	reg [raw_counter_size-1:0] raw_counter;
	always @(posedge clock) begin
		if (raw_counter[raw_counter_size-1:log2_of_reset_duration]==0) begin
			reset <= 1;
		end else begin
			reset <= 0;
		end
		raw_counter++;
	end
	wire dot_clock;
	wire nybble_clock;
	wire update_clock;
	wire [log2_of_number_of_nybbles-1:0] nybble_counter;
	always begin
		dot_clock <= raw_counter[dot_clock_pickoff];
		nybble_clock <= raw_counter[nybble_clock_pickoff];
		nybble_counter <= raw_counter[log2_of_number_of_nybbles+nybble_clock_pickoff+1:nybble_clock_pickoff+1];
		update_clock <= raw_counter[update_clock_pickoff];
	end
	reg [3:0] nybble [number_of_nybbles-1:0];
	integer i=0;
	always begin
		for (i=0; i<number_of_nybbles; i=i+1) begin
			nybble[i] <= data[4*i+3:4*i];
		end
	end
	reg [number_of_segments-1:0] sequence [number_of_nybbles-1:0];
	always @(posedge update_clock) begin
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
	end
	wire [number_of_segments-1:0] current_sequence;
	genvar j;
	always @(posedge nybble_clock) begin
		if (reset==1) begin
			anode <= 0;
		end else begin
			if (nybble_counter==0) begin
				anode[0] <= 1; anode[number_of_nybbles-1] <= 0; current_sequence <= sequence[0]; // turn on digit 0001; turn off digit 1000
			end else if (nybble_counter<number_of_nybbles-1) begin
				anode[nybble_counter] <= 1; anode[nybble_counter-1] <= 0; current_sequence <= sequence[nybble_counter];
			end else begin
				anode[number_of_nybbles-1] <= 1; anode[number_of_nybbles-2] <= 0; current_sequence <= sequence[number_of_nybbles-1]; // turn on digit 1000; turn off digit 0100
			end
		end
	end
	reg [number_of_segments-1:0] dot_token;
	always @(posedge dot_clock) begin
		if (reset==1) begin
			if (number_of_segments==16) begin
				cathode   <= 16'b1111111111111111;
				dot_token <= 16'b0000000000000001;
			end else begin
				cathode   <= 7'b1111111;
				dot_token <= 7'b0000001;
			end
		end else begin
			if (number_of_segments==16) begin
				case(dot_token)
					16'b0000000000000001 : begin cathode[00] <= current_sequence[15]; cathode[15] <= 1; end // set or clear segment a as appropriate; clear segment r
					16'b0000000000000010 : begin cathode[01] <= current_sequence[14]; cathode[00] <= 1; end // set or clear segment b as appropriate; clear segment a
					16'b0000000000000100 : begin cathode[02] <= current_sequence[13]; cathode[01] <= 1; end // set or clear segment c as appropriate; clear segment b
					16'b0000000000001000 : begin cathode[03] <= current_sequence[12]; cathode[02] <= 1; end // set or clear segment d as appropriate; clear segment c
					16'b0000000000010000 : begin cathode[04] <= current_sequence[11]; cathode[03] <= 1; end // set or clear segment e as appropriate; clear segment d
					16'b0000000000100000 : begin cathode[05] <= current_sequence[10]; cathode[04] <= 1; end // set or clear segment f as appropriate; clear segment e
					16'b0000000001000000 : begin cathode[06] <= current_sequence[09]; cathode[05] <= 1; end // set or clear segment g as appropriate; clear segment f
					16'b0000000010000000 : begin cathode[07] <= current_sequence[08]; cathode[06] <= 1; end // set or clear segment h as appropriate; clear segment g
					16'b0000000100000000 : begin cathode[08] <= current_sequence[07]; cathode[07] <= 1; end // set or clear segment k as appropriate; clear segment h
					16'b0000001000000000 : begin cathode[09] <= current_sequence[06]; cathode[08] <= 1; end // set or clear segment m as appropriate; clear segment k
					16'b0000010000000000 : begin cathode[10] <= current_sequence[05]; cathode[09] <= 1; end // set or clear segment n as appropriate; clear segment m
					16'b0000100000000000 : begin cathode[11] <= current_sequence[04]; cathode[10] <= 1; end // set or clear segment u as appropriate; clear segment n
					16'b0001000000000000 : begin cathode[12] <= current_sequence[03]; cathode[11] <= 1; end // set or clear segment p as appropriate; clear segment u
					16'b0010000000000000 : begin cathode[13] <= current_sequence[02]; cathode[12] <= 1; end // set or clear segment t as appropriate; clear segment p
					16'b0100000000000000 : begin cathode[14] <= current_sequence[01]; cathode[13] <= 1; end // set or clear segment s as appropriate; clear segment t
					default              : begin cathode[15] <= current_sequence[00]; cathode[14] <= 1; end // set or clear segment r as appropriate; clear segment s
				endcase
			end else begin
				case(dot_token)
					7'b0000001 : begin cathode[0] <= current_sequence[6]; cathode[6] <= 1; end // set or clear segment a as appropriate; clear segment g
					7'b0000010 : begin cathode[1] <= current_sequence[5]; cathode[0] <= 1; end // set or clear segment b as appropriate; clear segment a
					7'b0000100 : begin cathode[2] <= current_sequence[4]; cathode[1] <= 1; end // set or clear segment c as appropriate; clear segment b
					7'b0001000 : begin cathode[3] <= current_sequence[3]; cathode[2] <= 1; end // set or clear segment d as appropriate; clear segment c
					7'b0010000 : begin cathode[4] <= current_sequence[2]; cathode[3] <= 1; end // set or clear segment e as appropriate; clear segment d
					7'b0100000 : begin cathode[5] <= current_sequence[1]; cathode[4] <= 1; end // set or clear segment f as appropriate; clear segment e
					default    : begin cathode[6] <= current_sequence[0]; cathode[5] <= 1; end // set or clear segment g as appropriate; clear segment f
				endcase
			end
			dot_token <= { dot_token[number_of_segments-2:0], dot_token[number_of_segments-1] }; // barrel shifter
		end
	end
endmodule // seven_segment_display_driver__4

