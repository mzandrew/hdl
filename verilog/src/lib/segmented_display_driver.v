// written 2018-07-26 by mza
// taken from mza-test007.7-segment-driver.v
// last updated 2018-07-30 by mza

module seven_segment_display_driver__4 #(parameter number_of_segments=7) (input clock, input [15:0] data, output [number_of_segments-1:0] cathode, output [3:0] anode);
	localparam dot_clock_pickoff = 3;
	localparam overestimate_of_log2_of_number_of_segments = $clog2(number_of_segments);
	localparam nybble_clock_pickoff = dot_clock_pickoff + overestimate_of_log2_of_number_of_segments + 1;
	localparam number_of_nybbles = 4;
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
		for (i=0; i<=3; i=i+1) begin
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
			cathode <= 7'b1111111;
			dot_token <= 7'b0000001;
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
			dot_token <= { dot_token[number_of_segments-2:0], dot_token[number_of_segments-1] }; // barrel shifter
		end
	end
endmodule // seven_segment_display_driver__4

