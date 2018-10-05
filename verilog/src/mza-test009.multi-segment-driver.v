// written 2018-07-31 by mza
// based on mza-test007.7-segment-driver.v and mza-test003.double-dabble.v
// last updated 2018-10-05 by mza

`include "lib/hex2bcd.v"
`include "lib/segmented_display_driver.v"

module top(input CLK, 
output LED1, LED2, LED3, LED4, LED5,
J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10
);
	if (1) begin
		// for an HDSP-B04E mounted pin7=pin14 justified on an icestick-test revA ZIF-socket board (IDL_18_027)
		//wire [6:0] segment;
		//assign { J3_6, J1_5, J2_1, J3_3, J3_5, J3_8, J1_4 } = segment;
		wire [7:0] segment;
		assign { J3_6, J1_5, J2_1, J3_3, J3_5, J3_8, J1_4, J1_10 } = segment; // the J1_10 is just a dummy extra segment
		assign J3_4 = 1; // dp/colon
		wire [3:0] anode;
		assign J3_7 = anode[0]; // connected via resistor to anode0001 for least significant digit
		assign J1_7 = anode[1]; // connected via resistor to anode0010
		assign J1_6 = anode[2]; // connected via resistor to anode0100
		assign J1_3 = anode[3]; // connected via resistor to anode1000 for most significant digit
		//segmented_display_driver #(.number_of_segments(7), .number_of_nybbles(4)) my_instance_name (.clock(CLK), .data(bcd[15:0]), .cathode(segment), .anode(anode), .sync(), .sync_a(), .sync_c());
		segmented_display_driver #(.number_of_segments(8), .number_of_nybbles(4)) my_instance_name (.clock(CLK), .data(bcd[15:0]), .cathode(segment), .anode(anode), .sync_a(), .sync_c());
	end else begin
		// for an LTP587HR mounted pin16=pin14 justified on an icestick-test revA ZIF-socket board (IDL_18_027)
		wire [15:0] segment;
		assign { J1_6, J1_7, J1_7, J3_6, J1_3, J1_4, J2_10, J2_1, J3_3, J3_4, J3_5, J3_5, J3_7, J3_8, J1_5, J2_4, J2_2, J2_7 } = segment;
		assign J1_8  = 1; // dp/colon
		assign J2_9  = anode[0]; // res+pot connected to anode
		assign J1_9  = anode[0]; // res+pot connected to anode
		wire [1:0] anode;
		segmented_display_driver #(.number_of_segments(16), .number_of_nybbles(2)) my_instance_name (.clock(CLK), .data(bcd[7:0]), .cathode(segment), .anode(anode), .sync_a(), .sync_c());
	end
	wire [23:0] bcd;
	wire [15:0] data;
	wire reset;
	assign reset = 0;
	hex2bcd #(.input_size_in_nybbles(4)) h2binst ( .clock(CLK), .reset(reset), .hex_in(data), .bcd_out(bcd) );
	reg [40:0] raw_counter;
	reg [40:0] alternate_counter;
	//wire clock_1Hz;
	wire [15:0] counter_1000Hz;
	wire [15:0] counter_100Hz;
	wire [15:0] counter_10Hz;
	wire [15:0] counter_1Hz;
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
		//data <= counter_10Hz;
		data <= 16'd1122;
	end

endmodule // top

