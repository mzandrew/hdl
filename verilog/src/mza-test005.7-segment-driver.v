// written 2018-07-20 by mza
// based on mza-test004.16-segment-driver.v
// last updated 2018-07-20 by mza

module top(input CLK, 
output LED1, LED2, LED3, LED4, LED5,
J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10
);
	reg segment_a;
	reg segment_b;
	reg segment_c;
	reg segment_d;
	reg segment_e;
	reg segment_f;
	reg segment_g;
	assign J1_4  = segment_a;
	assign J3_8  = segment_b;
	assign J3_5  = segment_c;
	assign J3_3  = segment_d;
	assign J2_1  = segment_e;
	assign J1_5  = segment_f;
	assign J3_6  = segment_g;
	assign J3_4 = 1; // dp/colon
	assign J3_7 = 1; // connected via resistor to anode0001 for least significant digit
	assign J1_7 = 1; // connected via resistor to anode0010
	assign J1_6 = 1; // connected via resistor to anode0100
	assign J1_3 = 1; // connected via resistor to anode1000 for most significant digit
	reg [31:0] raw_counter;
	reg dot_clock;
	reg [3:0] dot_counter;
	reg clock_1Hz;
	reg [3:0] counter_1Hz;
	reg [6:0] sequence;
	reg reset;
	always @(posedge CLK) begin
		if (raw_counter[31:12]==0) begin // reset active for 4096 cycles
			reset <= 1;
			LED1 <= 0;
			LED2 <= 0;
			LED3 <= 0;
			LED4 <= 0;
			LED5 <= 0;
		end else begin
			LED5 <= dot_clock;
			reset <= 0;
		end
		raw_counter++;
	end
	always begin
		dot_clock <= raw_counter[12];
		dot_counter <= raw_counter[16:13];
	end
	always begin
		clock_1Hz <= raw_counter[23];
		counter_1Hz <= raw_counter[27:24];
	end
	always @(posedge clock_1Hz) begin
		case(counter_1Hz[3:0])
			4'h0    : sequence <= 7'b0000001;
			4'h1    : sequence <= 7'b1001111;
			4'h2    : sequence <= 7'b0010010;
			4'h3    : sequence <= 7'b0000110;
			4'h4    : sequence <= 7'b1001100;
			4'h5    : sequence <= 7'b0100100;
			4'h6    : sequence <= 7'b0100000;
			4'h7    : sequence <= 7'b0001111;
			4'h8    : sequence <= 7'b0000000;
			default : sequence <= 7'b0000100;
		endcase
	end
	always @(posedge dot_clock) begin
		if (reset==1) begin
			segment_a  <= 1; // clear segment a
			segment_b  <= 1; // clear segment b
			segment_c  <= 1; // clear segment c
			segment_d  <= 1; // clear segment d
			segment_e  <= 1; // clear segment e
			segment_f  <= 1; // clear segment f
			segment_g  <= 1; // clear segment g
		end else begin
			case(dot_counter)
				4'h0    : begin segment_a <= sequence[6];                 end // set or clear segment a as appropriate
				4'h1    : begin segment_b <= sequence[5]; segment_a <= 1; end // set or clear segment b as appropriate; clear segment a
				4'h2    : begin segment_c <= sequence[4]; segment_b <= 1; end // set or clear segment c as appropriate; clear segment b
				4'h3    : begin segment_d <= sequence[3]; segment_c <= 1; end // set or clear segment d as appropriate; clear segment c
				4'h4    : begin segment_e <= sequence[2]; segment_d <= 1; end // set or clear segment e as appropriate; clear segment d
				4'h5    : begin segment_f <= sequence[1]; segment_e <= 1; end // set or clear segment f as appropriate; clear segment e
				4'h6    : begin segment_g <= sequence[0]; segment_f <= 1; end // set or clear segment g as appropriate; clear segment f
				default : begin                           segment_g <= 1; end // clear segment g
			endcase
		end
	end
endmodule // top

