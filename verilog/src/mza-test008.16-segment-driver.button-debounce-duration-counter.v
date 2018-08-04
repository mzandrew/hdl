// written 2018-07-27 by mza
// based on mza-test004.16-segment-driver.v
// last updated 2018-07-30 by mza

`include "lib/debounce.v"
`include "lib/edge_to_pulse.v"

module top(input CLK, 
input J3_10, 
output LED1, LED2, LED3, LED4, LED5,
output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9
);
	reg segment_a;
	reg segment_b;
	reg segment_c;
	reg segment_d;
	reg segment_e;
	reg segment_f;
	reg segment_g;
	reg segment_h;
	reg segment_k;
	reg segment_m;
	reg segment_n;
	reg segment_u;
	reg segment_p;
	reg segment_t;
	reg segment_s;
	reg segment_r;
	reg segment_dp;
	assign J3_9 = button;
	assign J1_10 = pulse;
	reg button;
	assign LED1 = button;
	debounce my_debounce_instance (.clock(CLK), .polarity(0), .raw_button_input(J3_10), .button_active(button));
	wire pulse;
	edge_to_pulse #(.polarity(1)) my_e2p_instance (.clock(CLK), .i(button), .o(pulse));
	assign J2_7  = segment_a;
	assign J2_2  = segment_b;
	assign J2_4  = segment_c;
	assign J1_5  = segment_d;
	assign J3_8  = segment_e;
	assign J3_7  = segment_f;
	assign J3_5  = segment_g;
	assign J3_4  = segment_h;
	assign J3_3  = segment_k;
	assign J2_1  = segment_m;
	assign J2_10 = segment_n;
	assign J1_4  = segment_u;
	assign J1_3  = segment_p;
	assign J3_6  = segment_t;
	assign J1_7  = segment_s;
	assign J1_6  = segment_r;
	assign J1_8  = segment_dp;
	assign J2_9  = 1; // res+pot connected to anode
	assign J1_9  = 1; // res+pot connected to anode
	assign J2_3  = 1; // not connected
	assign J2_8  = 1; // not connected
//	assign J1_10 = 1; // not connected
	reg [31:0] raw_counter;
	reg dot_clock;
	reg [3:0] dot_counter;
	reg clock_1Hz;
	reg clock_10Hz;
	reg [3:0] counter_1Hz;
	reg [15:0] sequence;
	reg reset;
	wire [3:0] nybble;
	reg [3:0] counter = 0;
//	assign nybble = counter_1Hz[3:0];
	assign nybble = counter[3:0];
	always @(posedge CLK) begin
		//if (button==1) begin // measures durations
		if (pulse==1) begin // counts button presses
			counter++;
		end
	end
	always @(posedge CLK) begin
		if (raw_counter[31:12]==0) begin // reset active for 4096 cycles
			reset <= 1;
//			LED1 <= 0;
			LED2 <= 0;
			LED3 <= 0;
			LED4 <= 0;
			LED5 <= 0;
		end else begin
//			LED5 <= dot_clock;
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
	always begin
		clock_10Hz <= raw_counter[21];
	end
	always @(posedge clock_10Hz) begin
		case(nybble)
			4'h0    : sequence <= 16'b0000000011111111;
			4'h1    : sequence <= 16'b1100111111111111;
			4'h2    : sequence <= 16'b0001000111100111;
			4'h3    : sequence <= 16'b0000001111100111;
			4'h4    : sequence <= 16'b1100111011100111;
			4'h5    : sequence <= 16'b0010001011100111;
			4'h6    : sequence <= 16'b0010000011100111;
			4'h7    : sequence <= 16'b0000111111111111;
			4'h8    : sequence <= 16'b0000000011100111;
			4'h9    : sequence <= 16'b0000001011100111;
			4'ha    : sequence <= 16'b0000110011100111;
			4'hb    : sequence <= 16'b1110000011100111;
			4'hc    : sequence <= 16'b0011000011111111;
			4'hd    : sequence <= 16'b1100000111100111;
			4'he    : sequence <= 16'b0011000011101111;
			default : sequence <= 16'b0011110011101111;
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
			segment_h  <= 1; // clear segment h
			segment_k  <= 1; // clear segment k
			segment_m  <= 1; // clear segment m
			segment_n  <= 1; // clear segment n
			segment_u  <= 1; // clear segment u
			segment_p  <= 1; // clear segment p
			segment_t  <= 1; // clear segment t
			segment_s  <= 1; // clear segment s
			segment_r  <= 1; // clear segment r
			segment_dp <= 1; // clear segment dp
		end else begin
			case(dot_counter)
				4'h0    : begin segment_a <= sequence[15]; segment_r <= 1; end // set or clear segment a as appropriate; clear segment r
				4'h1    : begin segment_b <= sequence[14]; segment_a <= 1; end // set or clear segment b as appropriate; clear segment a
				4'h2    : begin segment_c <= sequence[13]; segment_b <= 1; end // set or clear segment c as appropriate; clear segment b
				4'h3    : begin segment_d <= sequence[12]; segment_c <= 1; end // set or clear segment d as appropriate; clear segment c
				4'h4    : begin segment_e <= sequence[11]; segment_d <= 1; end // set or clear segment e as appropriate; clear segment d
				4'h5    : begin segment_f <= sequence[10]; segment_e <= 1; end // set or clear segment f as appropriate; clear segment e
				4'h6    : begin segment_g <= sequence[09]; segment_f <= 1; end // set or clear segment g as appropriate; clear segment f
				4'h7    : begin segment_h <= sequence[08]; segment_g <= 1; end // set or clear segment h as appropriate; clear segment g
				4'h8    : begin segment_k <= sequence[07]; segment_h <= 1; end // set or clear segment k as appropriate; clear segment h
				4'h9    : begin segment_m <= sequence[06]; segment_k <= 1; end // set or clear segment m as appropriate; clear segment k
				4'ha    : begin segment_n <= sequence[05]; segment_m <= 1; end // set or clear segment n as appropriate; clear segment m
				4'hb    : begin segment_u <= sequence[04]; segment_n <= 1; end // set or clear segment u as appropriate; clear segment n
				4'hc    : begin segment_p <= sequence[03]; segment_u <= 1; end // set or clear segment p as appropriate; clear segment u
				4'hd    : begin segment_t <= sequence[02]; segment_p <= 1; end // set or clear segment t as appropriate; clear segment p
				4'he    : begin segment_s <= sequence[01]; segment_t <= 1; end // set or clear segment s as appropriate; clear segment t
				default : begin segment_r <= sequence[00]; segment_s <= 1; end // set or clear segment r as appropriate; clear segment s
			endcase
		end
	end
endmodule // top

