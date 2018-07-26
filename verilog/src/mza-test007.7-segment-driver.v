// written 2018-07-26 by mza
// based on mza-test006.7-segment-driver.v
// last updated 2018-07-26 by mza

module seven_segment_display_driver__4(input clock, input [15:0] data, output [6:0] cathode, output [3:0] anode);
	localparam dot_clock_pickoff = 3;
	localparam number_of_segments = 7;
	localparam overestimate_of_log2_of_number_of_segments = 3; // 7~16 dots
	localparam nybble_clock_pickoff = dot_clock_pickoff + overestimate_of_log2_of_number_of_segments + 1;
	localparam number_of_nybbles = 4;
	localparam log2_of_number_of_nybbles = 2;
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

module top(input CLK, 
output LED1, LED2, LED3, LED4, LED5,
J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10
);
	wire [6:0] segment;
	assign J1_4  = segment[0];
	assign J3_8  = segment[1];
	assign J3_5  = segment[2];
	assign J3_3  = segment[3];
	assign J2_1  = segment[4];
	assign J1_5  = segment[5];
	assign J3_6  = segment[6];
	assign J3_4 = 1; // dp/colon
	wire [3:0] anode;
	assign J3_7 = anode[0]; // connected via resistor to anode0001 for least significant digit
	assign J1_7 = anode[1]; // connected via resistor to anode0010
	assign J1_6 = anode[2]; // connected via resistor to anode0100
	assign J1_3 = anode[3]; // connected via resistor to anode1000 for most significant digit

	reg [40:0] raw_counter;
	reg [40:0] alternate_counter;
	//wire clock_1Hz;
	wire [15:0] counter_1000Hz;
	wire [15:0] counter_100Hz;
	wire [15:0] counter_10Hz;
	wire [15:0] counter_1Hz;
	wire [15:0] data;
	reg [2:0] clock_token;
	always @(posedge CLK) begin
		if (raw_counter[40:10]==0) begin
			clock_token <= 3'b001;
		end else begin
			clock_token <= { clock_token[1:0], clock_token[2] }; // barrel shifter
		end
		if (clock_token == 3'b001) begin
			alternate_counter++;
		end
		raw_counter++;
	end
	always begin
//		counter_1Hz <= raw_counter[39:24]; // really about 1.34 Hz
//		counter_10Hz <= raw_counter[35:20]; // really about 11.444 Hz
//		counter_1000Hz <= alternate_counter[26:12]; // really about 1.024 kHz
		counter_10Hz <= alternate_counter[34:19]; // really about 7.629 Hz
//		counter_1Hz <= alternate_counter[37:22]; // really about 1.048576 Hz
		data <= counter_10Hz;
	end
	seven_segment_display_driver__4 my_instance_name (.clock(CLK), .data(data), .cathode(segment), .anode(anode));

endmodule // top

