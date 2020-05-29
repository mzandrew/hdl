// written 2018-07-20 by mza
// based on mza-test005.7-segment-driver.v
// last updated 2020-05-29 by mza

`define icestick

module top (
	input CLK,
	output reg LED1 = 0,
	output reg LED2 = 0,
	output reg LED3 = 0,
	output reg LED4 = 0,
	output reg LED5 = 0,
	output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
	output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
	output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10
);
	reg segment_a = 0;
	reg segment_b = 0;
	reg segment_c = 0;
	reg segment_d = 0;
	reg segment_e = 0;
	reg segment_f = 0;
	reg segment_g = 0;
	assign J1_4  = segment_a;
	assign J3_8  = segment_b;
	assign J3_5  = segment_c;
	assign J3_3  = segment_d;
	assign J2_1  = segment_e;
	assign J1_5  = segment_f;
	assign J3_6  = segment_g;
	assign J3_4 = 1; // dp/colon
	reg anode0001 = 0;
	reg anode0010 = 0;
	reg anode0100 = 0;
	reg anode1000 = 0;
	assign J3_7 = anode0001; // connected via resistor to anode0001 for least significant digit
	assign J1_7 = anode0010; // connected via resistor to anode0010
	assign J1_6 = anode0100; // connected via resistor to anode0100
	assign J1_3 = anode1000; // connected via resistor to anode1000 for most significant digit
	reg [31:0] raw_counter = 0;
	wire digit_clock;
	wire [1:0] digit_counter;
	wire dot_clock;
	reg [6:0] dot_token = 0;
	wire clock_1Hz;
	wire [3:0] counter_1Hz;
	reg [6:0] sequence = 0;
	reg [6:0] sequence0001 = 0;
	reg [6:0] sequence0010 = 0;
	reg [6:0] sequence0100 = 0;
	reg [6:0] sequence1000 = 0;
	reg reset = 0;
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
	assign digit_clock = raw_counter[digit_clock_pickoff];
	assign digit_counter = raw_counter[digit_clock_pickoff+2:digit_clock_pickoff+1];
	assign dot_clock = raw_counter[dot_clock_pickoff];
	assign clock_1Hz = raw_counter[23];
	assign counter_1Hz = raw_counter[27:24];
	always @(posedge clock_1Hz) begin
		sequence1000 <= sequence0100;
		sequence0100 <= sequence0010;
		sequence0010 <= sequence0001;
		case(counter_1Hz[3:0])
			4'h0    : sequence0001 <= 7'b0000001;
			4'h1    : sequence0001 <= 7'b1001111;
			4'h2    : sequence0001 <= 7'b0010010;
			4'h3    : sequence0001 <= 7'b0000110;
			4'h4    : sequence0001 <= 7'b1001100;
			4'h5    : sequence0001 <= 7'b0100100;
			4'h6    : sequence0001 <= 7'b0100000;
			4'h7    : sequence0001 <= 7'b0001111;
			4'h8    : sequence0001 <= 7'b0000000;
			4'h9    : sequence0001 <= 7'b0000100;
			4'ha    : sequence0001 <= 7'b0001000;
			4'hb    : sequence0001 <= 7'b1100000;
			4'hc    : sequence0001 <= 7'b1110010;
			4'hd    : sequence0001 <= 7'b1000010;
			4'he    : sequence0001 <= 7'b0110000;
			default : sequence0001 <= 7'b0111000;
		endcase
	end
	always @(posedge digit_clock) begin
		if (reset==1) begin
			anode0001 <= 0; // turn off digit 0001
			anode0010 <= 0; // turn off digit 0010
			anode0100 <= 0; // turn off digit 0100
			anode1000 <= 0; // turn off digit 1000
		end else begin
			case(digit_counter)
				4'h0    : begin anode0001 <= 1; anode1000 <= 0; sequence <= sequence0001; end // turn on digit 0001; turn off digit 1000
				4'h1    : begin anode0010 <= 1; anode0001 <= 0; sequence <= sequence0010; end // turn on digit 0010; turn off digit 0001
				4'h2    : begin anode0100 <= 1; anode0010 <= 0; sequence <= sequence0100; end // turn on digit 0100; turn off digit 0010
				default : begin anode1000 <= 1; anode0100 <= 0; sequence <= sequence1000; end // turn on digit 1000; turn off digit 0100
			endcase
		end
	end
	always @(posedge dot_clock) begin
		if (reset==1) begin
			segment_a <= 1; // clear segment a
			segment_b <= 1; // clear segment b
			segment_c <= 1; // clear segment c
			segment_d <= 1; // clear segment d
			segment_e <= 1; // clear segment e
			segment_f <= 1; // clear segment f
			segment_g <= 1; // clear segment g
			dot_token <= 7'b0000001;
		end else begin
			case(dot_token)
				7'b0000001 : begin segment_a <= sequence[6]; segment_g <= 1; end // set or clear segment a as appropriate; clear segment g
				7'b0000010 : begin segment_b <= sequence[5]; segment_a <= 1; end // set or clear segment b as appropriate; clear segment a
				7'b0000100 : begin segment_c <= sequence[4]; segment_b <= 1; end // set or clear segment c as appropriate; clear segment b
				7'b0001000 : begin segment_d <= sequence[3]; segment_c <= 1; end // set or clear segment d as appropriate; clear segment c
				7'b0010000 : begin segment_e <= sequence[2]; segment_d <= 1; end // set or clear segment e as appropriate; clear segment d
				7'b0100000 : begin segment_f <= sequence[1]; segment_e <= 1; end // set or clear segment f as appropriate; clear segment e
				default    : begin segment_g <= sequence[0]; segment_f <= 1; end // set or clear segment g as appropriate; clear segment f
			endcase
			dot_token <= { dot_token[5:0], dot_token[6] }; // barrel shifter
		end
	end
endmodule // top

