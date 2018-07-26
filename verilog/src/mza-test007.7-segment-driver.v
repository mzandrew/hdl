// written 2018-07-26 by mza
// based on mza-test006.7-segment-driver.v
// last updated 2018-07-26 by mza

//module seven_segment_display_driver__4(input clock, input [15:0] data, output [6:0] cathode, output [3:0] anode);
//endmodule // seven_segment_display_driver__4

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
	reg [39:0] raw_counter;
	wire digit_clock;
	wire [1:0] digit_counter;
	wire dot_clock;
	reg [6:0] dot_token;
	wire clock_1Hz;
	wire [15:0] counter_1Hz;
	wire [6:0] current_sequence;
	reg [6:0] sequence [3:0];
	reg [3:0] nybble [3:0];
	wire reset;
	wire [15:0] data;
	always @(posedge CLK) begin
		if (raw_counter[31:12]==0) begin // reset active for 4096 cycles
			reset <= 1;
			LED1 <= 0;
			LED2 <= 0;
			LED3 <= 0;
			LED4 <= 0;
			LED5 <= 0;
		end else begin
			reset <= 0;
			LED4 <= digit_clock;
			LED5 <= dot_clock;
		end
		raw_counter++;
	end
	localparam dot_clock_pickoff = 3;
	localparam digit_clock_pickoff = dot_clock_pickoff + 4;
	always begin
		digit_clock <= raw_counter[digit_clock_pickoff];
		digit_counter <= raw_counter[digit_clock_pickoff+2:digit_clock_pickoff+1];
	end
	always begin
		dot_clock <= raw_counter[dot_clock_pickoff];
	end
	always begin
		clock_1Hz <= raw_counter[23];
		counter_1Hz <= raw_counter[39:24];
	end
	always begin
		data <= counter_1Hz;
	end
	always begin
		nybble[3] <= data[15:12];
		nybble[2] <= data[11:08];
		nybble[1] <= data[07:04];
		nybble[0] <= data[03:00];
	end
	integer i=0;
	always @(posedge clock_1Hz) begin
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
	always @(posedge digit_clock) begin
		if (reset==1) begin
			anode <= 4'h0;
		end else begin
			case(digit_counter)
				4'h0    : begin anode[0] <= 1; anode[3] <= 0; current_sequence <= sequence[0]; end // turn on digit 0001; turn off digit 1000
				4'h1    : begin anode[1] <= 1; anode[0] <= 0; current_sequence <= sequence[1]; end // turn on digit 0010; turn off digit 0001
				4'h2    : begin anode[2] <= 1; anode[1] <= 0; current_sequence <= sequence[2]; end // turn on digit 0100; turn off digit 0010
				default : begin anode[3] <= 1; anode[2] <= 0; current_sequence <= sequence[3]; end // turn on digit 1000; turn off digit 0100
			endcase
		end
	end
	always @(posedge dot_clock) begin
		if (reset==1) begin
			segment <= 7'b1111111;
			dot_token <= 7'b0000001;
		end else begin
			case(dot_token)
				7'b0000001 : begin segment[0] <= current_sequence[6]; segment[6] <= 1; end // set or clear segment a as appropriate; clear segment g
				7'b0000010 : begin segment[1] <= current_sequence[5]; segment[0] <= 1; end // set or clear segment b as appropriate; clear segment a
				7'b0000100 : begin segment[2] <= current_sequence[4]; segment[1] <= 1; end // set or clear segment c as appropriate; clear segment b
				7'b0001000 : begin segment[3] <= current_sequence[3]; segment[2] <= 1; end // set or clear segment d as appropriate; clear segment c
				7'b0010000 : begin segment[4] <= current_sequence[2]; segment[3] <= 1; end // set or clear segment e as appropriate; clear segment d
				7'b0100000 : begin segment[5] <= current_sequence[1]; segment[4] <= 1; end // set or clear segment f as appropriate; clear segment e
				default    : begin segment[6] <= current_sequence[0]; segment[5] <= 1; end // set or clear segment g as appropriate; clear segment f
			endcase
			dot_token <= { dot_token[5:0], dot_token[6] }; // barrel shifter
		end
	end
endmodule // top

