// written 2018-07-06 by mza
// last updated 2018-07-06 by mza

module top(input CLK, 
output 
J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
J3_3, J3_4, J3_5, J3_6, J3_7,       J3_9, J3_10
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
//	assign J2_3  = 0; // e, but doensn't work
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
//	assign J3_8  = 1; // anode; DO NOT DRIVE!
	assign J3_9  = 1; // not connected
	assign J3_10 = 1; // not connected
	reg [31:0] counter;
	reg [15:0] sequence;
	wire reset;
	always @(posedge CLK) begin
		if (counter[31:16]==0) begin
			reset <= 1;
		end else begin
			reset <= 0;
		end
		counter++;
		case(counter[27:24])
			4'h0 : sequence <= 1111111100000000;
			4'h1 : sequence <= 0011000000000000;
		endcase
		case(counter[3:0])
			4'h0 : J2_7 <= sequence[15]; // segment a
			4'h1 : J2_2 <= sequence[14]; // segment b
			4'h2 : J2_4 <= sequence[13]; // segment c
			4'h3 : J1_5 <= sequence[12]; // segment d
			4'h4 : J2_3 <= sequence[11]; // segment e
			4'h5 : J3_7 <= sequence[10]; // segment f
			4'h6 : J3_5 <= sequence[09]; // segment g
			4'h7 : J3_4 <= sequence[08]; // segment h
			4'h8 : J3_3 <= sequence[07]; // segment k
			4'h9 : J2_1 <= sequence[06]; // segment m
			4'ha : J2_10<= sequence[05]; // segment n
			4'hb : J1_4 <= sequence[04]; // segment u
			4'hc : J1_3 <= sequence[03]; // segment p
			4'hd : J3_6 <= sequence[02]; // segment t
			4'he : J1_7 <= sequence[01]; // segment s
			4'hf : J1_6 <= sequence[00]; // segment r
		endcase
	end
endmodule // top

