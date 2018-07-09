// written 2018-07-06 by mza
// last updated 2018-07-06 by mza

module top(input CLK, 
output LED1, LED2, LED3, LED4, LED5,
J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
J2_1, J2_2,       J2_4, J2_7, J2_8, J2_9, J2_10,
J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10
);
//	assign J1_3  = 1; // segment p
//	assign J1_4  = 1; // segment u
//	assign J1_5  = 1; // segment d
//	assign J1_6  = 1; // segment r
//	assign J1_7  = 1; // segment s
	assign J1_8  = 1; // segment dp
	assign J1_9  = 1; // not connected
	assign J1_10 = 1; // not connected

//	assign J2_1  = 1; // segment m
//	assign J2_2  = 1; // segment b
//	assign J2_3  = 0; // anode; DO NOT DRIVE
//	assign J2_4  = 1; // segment c
//	assign J2_7  = 1; // segment a
	assign J2_8  = 1; // not connected
	assign J2_9  = 1; // not connected
//	assign J2_10 = 1; // segment n

//	assign J3_3  = 1; // segment k
//	assign J3_4  = 1; // segment h
//	assign J3_5  = 1; // segment g
//	assign J3_6  = 1; // segment t
//	assign J3_7  = 1; // segment f
//	assign J3_8  = 1; // segment e
	assign J3_9  = 1; // not connected
	assign J3_10 = 1; // not connected
	reg [31:0] raw_counter;
	reg dot_clock;
	reg [3:0] dot_counter;
	reg clock_1Hz;
	reg [3:0] counter_1Hz;
	reg [15:0] sequence;
	reg reset;
	always @(posedge CLK) begin
		if (raw_counter[31:12]==0) begin
			reset <= 1;
			//sequence <= {2'b00,2'b11,2'b00,2'b11,3'b111,2'b00,3'b111};
			//sequence <= {2'b11,2'b11,2'b11,2'b11,3'b111,2'b11,3'b111};
			LED1 <= 0;
			LED2 <= 0;
			LED3 <= 0;
			LED4 <= 0;
			//LED5 <= 0;
		end else begin
			//LED1 <= dot_clock;
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
		//case(counter[27:24])
		//case(raw_counter[31:27])
		case(counter_1Hz[3:0])
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
//		LED1 <= dot_counter[0];
//		LED2 <= dot_counter[1];
//		LED3 <= dot_counter[2];
//		LED4 <= dot_counter[3];
		if (reset==1) begin
			J2_7  <= 1; // clear segment a
			J2_2  <= 1; // clear segment b
			J2_4  <= 1; // clear segment c
			J1_5  <= 1; // clear segment d
			J3_8  <= 1; // clear segment e
			J3_7  <= 1; // clear segment f
			J3_5  <= 1; // clear segment g
			J3_4  <= 1; // clear segment h
			J3_3  <= 1; // clear segment k
			J2_1  <= 1; // clear segment m
			J2_10 <= 1; // clear segment n
			J1_4  <= 1; // clear segment u
			J1_3  <= 1; // clear segment p
			J3_6  <= 1; // clear segment t
			J1_7  <= 1; // clear segment s
			J1_6  <= 1; // clear segment r
		end else begin
			case(dot_counter)
				4'h0 : begin J2_7  <= sequence[15]; J1_6  <= 1; LED5 <= 1; end // set or clear segment a as appropriate; clear segment r
				4'h1 : begin J2_2  <= sequence[14]; J2_7  <= 1; LED5 <= 0; end // set or clear segment b as appropriate; clear segment a
				4'h2 : begin J2_4  <= sequence[13]; J2_2  <= 1; end // set or clear segment c as appropriate; clear segment b
				4'h3 : begin J1_5  <= sequence[12]; J2_4  <= 1; end // set or clear segment d as appropriate; clear segment c
				4'h4 : begin J3_8  <= sequence[11]; J1_5  <= 1; end // set or clear segment e as appropriate; clear segment d
				4'h5 : begin J3_7  <= sequence[10]; J3_8  <= 1; end // set or clear segment f as appropriate; clear segment e
				4'h6 : begin J3_5  <= sequence[09]; J3_7  <= 1; end // set or clear segment g as appropriate; clear segment f
				4'h7 : begin J3_4  <= sequence[08]; J3_5  <= 1; end // set or clear segment h as appropriate; clear segment g
				4'h8 : begin J3_3  <= sequence[07]; J3_4  <= 1; end // set or clear segment k as appropriate; clear segment h
				4'h9 : begin J2_1  <= sequence[06]; J3_3  <= 1; end // set or clear segment m as appropriate; clear segment k
				4'ha : begin J2_10 <= sequence[05]; J2_1  <= 1; end // set or clear segment n as appropriate; clear segment m
				4'hb : begin J1_4  <= sequence[04]; J2_10 <= 1; end // set or clear segment u as appropriate; clear segment n
				4'hc : begin J1_3  <= sequence[03]; J1_4  <= 1; end // set or clear segment p as appropriate; clear segment u
				4'hd : begin J3_6  <= sequence[02]; J1_3  <= 1; end // set or clear segment t as appropriate; clear segment p
				4'he : begin J1_7  <= sequence[01]; J3_6  <= 1; end // set or clear segment s as appropriate; clear segment t
				default : begin J1_6  <= sequence[00]; J1_7  <= 1; end // set or clear segment r as appropriate; clear segment s
			endcase
		end
	end
endmodule // top

