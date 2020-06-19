`timescale 1ns / 1ps
// written 2019-09-22 by mza
// last updated 2020-06-19 by mza

//	mux #(.WIDTH(8)) mymux (.I0(), .I1(), .S(), .O());
module mux #(
	parameter WIDTH = 1
) (
	input S,
	input [WIDTH-1:0] I0, I1,
	output [WIDTH-1:0] O
);
	assign O = S ? I1 : I0;
endmodule

//	mux_2to1 #(.WIDTH(8)) mymux (.in0(), .in1(), .sel(), .out());
module mux_2to1 #(
	parameter WIDTH = 1
) (
	input sel,
	input [WIDTH-1:0] in0, in1,
	output [WIDTH-1:0] out
);
	assign out = sel ? in1 : in0;
endmodule

module mux_8to1 #(
	parameter WIDTH = 1
) (
	input [WIDTH-1:0] in0, in1, in2, in3, in4, in5, in6, in7,
	input [2:0] sel,
	output [WIDTH-1:0] out
);
	assign out =
		(sel==3'd0) ? in0 :
		(sel==3'd1) ? in1 :
		(sel==3'd2) ? in2 :
		(sel==3'd3) ? in3 :
		(sel==3'd4) ? in4 :
		(sel==3'd5) ? in5 :
		(sel==3'd6) ? in6 :
		              in7;
endmodule

module demux_1to8 #(
	parameter WIDTH = 1,
	parameter [WIDTH-1:0] default_value = 0
) (
	input [WIDTH-1:0] in,
	input [2:0] sel,
	output [WIDTH-1:0] out0, out1, out2, out3, out4, out5, out6, out7
);
	assign out0 = (sel==3'd0) ? in : default_value;
	assign out1 = (sel==3'd1) ? in : default_value;
	assign out2 = (sel==3'd2) ? in : default_value;
	assign out3 = (sel==3'd3) ? in : default_value;
	assign out4 = (sel==3'd4) ? in : default_value;
	assign out5 = (sel==3'd5) ? in : default_value;
	assign out6 = (sel==3'd6) ? in : default_value;
	assign out7 = (sel==3'd7) ? in : default_value;
endmodule

module mux_8to1_tb;
	wire out;
	reg a, b, c, d, e, f, g, h;
	reg [2:0] sel = 3'd0;
	initial begin
		#1; sel <= 3'd0; a <= 0; b <= 0; c <= 0; d <= 0; e <= 0; f <= 0; g <= 0; h <= 0;
		// individual ones:
		#1; sel <= 3'd0; a <= 1; b <= 0; c <= 0; d <= 0; e <= 0; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd1; a <= 0; b <= 1; c <= 0; d <= 0; e <= 0; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd2; a <= 0; b <= 0; c <= 1; d <= 0; e <= 0; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd3; a <= 0; b <= 0; c <= 0; d <= 1; e <= 0; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd4; a <= 0; b <= 0; c <= 0; d <= 0; e <= 1; f <= 0; g <= 0; h <= 0;
		#1; sel <= 3'd5; a <= 0; b <= 0; c <= 0; d <= 0; e <= 0; f <= 1; g <= 0; h <= 0;
		#1; sel <= 3'd6; a <= 0; b <= 0; c <= 0; d <= 0; e <= 0; f <= 0; g <= 1; h <= 0;
		#1; sel <= 3'd7; a <= 0; b <= 0; c <= 0; d <= 0; e <= 0; f <= 0; g <= 0; h <= 1;
		// individual zeroes:
		#1; sel <= 3'd0; a <= 0; b <= 1; c <= 1; d <= 1; e <= 1; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd1; a <= 1; b <= 0; c <= 1; d <= 1; e <= 1; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd2; a <= 1; b <= 1; c <= 0; d <= 1; e <= 1; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd3; a <= 1; b <= 1; c <= 1; d <= 0; e <= 1; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd4; a <= 1; b <= 1; c <= 1; d <= 1; e <= 0; f <= 1; g <= 1; h <= 1;
		#1; sel <= 3'd5; a <= 1; b <= 1; c <= 1; d <= 1; e <= 1; f <= 0; g <= 1; h <= 1;
		#1; sel <= 3'd6; a <= 1; b <= 1; c <= 1; d <= 1; e <= 1; f <= 1; g <= 0; h <= 1;
		#1; sel <= 3'd7; a <= 1; b <= 1; c <= 1; d <= 1; e <= 1; f <= 1; g <= 1; h <= 0;
	end
	mux_8to1 tst (.in0(a), .in1(b), .in2(c), .in3(d), .in4(e), .in5(f), .in6(g), .in7(h), .sel(sel), .out(out));
endmodule

module demux_1to8_tb;
	reg [2:0] in;
	wire [2:0] a, b, c, d, e, f, g, h;
	reg [2:0] sel = 3'd0;
	initial begin
		in <= 0;
		#1; sel <= 3'd0;
		#1; sel <= 3'd1;
		#1; sel <= 3'd2;
		#1; sel <= 3'd3;
		#1; sel <= 3'd4;
		#1; sel <= 3'd5;
		#1; sel <= 3'd6;
		#1; sel <= 3'd7;
		//
		#1; sel <= 3'd7;
		#1; sel <= 3'd6;
		#1; sel <= 3'd5;
		#1; sel <= 3'd4;
		#1; sel <= 3'd3;
		#1; sel <= 3'd2;
		#1; sel <= 3'd1;
		#1; sel <= 3'd0;
	end
	always begin
		#1;
		in <= in + 1;
	end
	demux_1to8 #(.WIDTH(3)) tst (
		.in(in), .sel(sel),
		.out0(a), .out1(b), .out2(c), .out3(d),
		.out4(e), .out5(f), .out6(g), .out7(h));
endmodule

module and_gate #(
	parameter DELAY_RISE = 0.5,
	parameter DELAY_FALL = 0.5,
	parameter TESTBENCH = 0
) (
	input I0,
	input I1,
	output O
);
	wire O0;
	if (TESTBENCH) begin
		reg O0_prev = 0;
		reg O1 = 0;
		always begin
			case ({ O0_prev, O0 })
				2'b00:   begin #DELAY_RISE; O0_prev <= O0; end
				2'b01:   begin #DELAY_RISE; O1 <= O0; O0_prev <= O0; end
				2'b10:   begin #DELAY_FALL; O1 <= O0; O0_prev <= O0; end
				default: begin #DELAY_RISE; O0_prev <= O0; end
			endcase
		end
		assign O = O1;
	end else begin
		assign O = O0;
	end
	// from Xilinx HDL Libraries Guide, version 14.5 
	LUT5 #(
		//.INIT(32'h00000008) // Specify LUT Contents
		.INIT(32'b00000000000000000000000000001000) // Specify LUT Contents
	) LUT5_inst (
		.O(O0), // LUT general output
		.I0(I0), // LUT input
		.I1(I1), // LUT input
		.I2(1'b0), // LUT input
		.I3(1'b0), // LUT input
		.I4(1'b0)  // LUT input
	);
endmodule

// idea from Ken Chapman's solution here: https://forums.xilinx.com/t5/Other-FPGA-Architecture/How-to-implement-a-ring-oscillator-with-routings-of-FPGA-Where/m-p/768895/highlight/true#M21839
module ring_oscillator #(
	parameter number_of_bits_for_coarse_stages = 3,
	parameter number_of_bits_for_medium_stages = 3,
	parameter number_of_bits_for_fine_stages = 3,
	parameter number_of_bits = number_of_bits_for_coarse_stages + number_of_bits_for_medium_stages + number_of_bits_for_fine_stages,
//	parameter number_of_coarse_stages = 8,
//	parameter number_of_medium_stages = 8,
//	parameter number_of_fine_stages = 8,
//	parameter number_of_stages = number_of_coarse_stages + number_of_medium_stages + number_of_fine_stages,
	parameter TESTBENCH = 0
) (
	input enable,
//	input [$clog2(number_of_stages)-1:0] select,
	input [number_of_bits-1:0] select,
	output clock_out
);
	localparam number_of_coarse_stages = 2**number_of_bits_for_coarse_stages;
	localparam number_of_medium_stages = 2**number_of_bits_for_medium_stages;
	localparam number_of_fine_stages = 2**number_of_bits_for_fine_stages;
	localparam number_of_stages = number_of_coarse_stages + number_of_medium_stages + number_of_fine_stages;
	wire [number_of_stages-1:0] stage;
	genvar i;
	localparam COARSE_DELAY = 10.0;
	localparam MEDIUM_DELAY = 2.0;
	localparam FINE_DELAY = 0.5;
	wire [number_of_bits_for_coarse_stages-1:0] select_coarse = select[number_of_bits-1:number_of_bits_for_medium_stages+number_of_bits_for_fine_stages];
	wire [number_of_bits_for_medium_stages-1:0] select_medium = select[number_of_bits-number_of_bits_for_coarse_stages-1:number_of_bits_for_fine_stages];
	wire [number_of_bits_for_fine_stages-1:0] select_fine = select[number_of_bits_for_fine_stages-1:0];
	for (i=0; i<number_of_coarse_stages-1; i=i+2) begin : coarse_feedback_even
		and_gate #(.DELAY_RISE(COARSE_DELAY), .DELAY_FALL(COARSE_DELAY), .TESTBENCH(TESTBENCH)) coarse (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	for (i=1; i<number_of_coarse_stages-1; i=i+2) begin : coarse_feedback_odd
		and_gate #(.DELAY_RISE(COARSE_DELAY), .DELAY_FALL(COARSE_DELAY), .TESTBENCH(TESTBENCH)) coarse (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	and_gate #(.DELAY_RISE(COARSE_DELAY), .DELAY_FALL(COARSE_DELAY), .TESTBENCH(TESTBENCH)) coarse_bride (.I0(stage[select_coarse]), .I1(enable), .O(stage[number_of_coarse_stages]));
	wire aftercoarse = stage[number_of_coarse_stages];
	for (i=number_of_coarse_stages; i<number_of_coarse_stages+number_of_medium_stages-1; i=i+2) begin : medium_feedback_even
		and_gate #(.DELAY_RISE(MEDIUM_DELAY), .DELAY_FALL(MEDIUM_DELAY), .TESTBENCH(TESTBENCH)) mediumm (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	for (i=number_of_coarse_stages+1; i<number_of_coarse_stages+number_of_medium_stages-1; i=i+2) begin : medium_feedback_odd
		and_gate #(.DELAY_RISE(MEDIUM_DELAY), .DELAY_FALL(MEDIUM_DELAY), .TESTBENCH(TESTBENCH)) mediumm (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	and_gate #(.DELAY_RISE(MEDIUM_DELAY), .DELAY_FALL(MEDIUM_DELAY), .TESTBENCH(TESTBENCH)) mediumm_bride (.I0(stage[number_of_coarse_stages+select_medium]), .I1(enable), .O(stage[number_of_coarse_stages+number_of_medium_stages]));
	wire aftermedium = stage[number_of_coarse_stages+number_of_medium_stages];
	for (i=number_of_coarse_stages+number_of_medium_stages; i<number_of_stages-1; i=i+2) begin : fine_feedback_even
		and_gate #(.DELAY_RISE(FINE_DELAY), .DELAY_FALL(FINE_DELAY), .TESTBENCH(TESTBENCH)) fine (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	for (i=number_of_coarse_stages+number_of_medium_stages+1; i<number_of_stages-1; i=i+2) begin : fine_feedback_odd
		and_gate #(.DELAY_RISE(FINE_DELAY), .DELAY_FALL(FINE_DELAY), .TESTBENCH(TESTBENCH)) fine (.I0(stage[i]), .I1(enable), .O(stage[i+1]));
	end
	and_gate #(.DELAY_RISE(FINE_DELAY), .DELAY_FALL(FINE_DELAY), .TESTBENCH(TESTBENCH)) fine_bride (.I0(~stage[number_of_coarse_stages+number_of_medium_stages+select_fine]), .I1(enable), .O(stage[0]));
	wire afterfine = stage[0];
	assign clock_out = stage[0];
endmodule

module ring_oscillator_tb ();
	wire clock;
	reg enable = 0;
	reg [3:0] select_coarse = 4'd0;
	reg [1:0] select_medium = 2'd0;
	reg [1:0] select_fine = 2'd0;
	wire [7:0] select = { select_coarse, select_medium, select_fine };
	ring_oscillator #(.number_of_bits_for_coarse_stages(4), .number_of_bits_for_medium_stages(2), .number_of_bits_for_fine_stages(2), .TESTBENCH(1)) ro (.enable(enable), .select(select), .clock_out(clock));
	initial begin
		#20;
		enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd00; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd01; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd02; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd03; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd04; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd05; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd06; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd07; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd08; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd09; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd10; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd11; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd12; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd13; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd14; #100; enable <= 1;
		#2000; enable <= 0; select_coarse <= 4'd15; #100; enable <= 1;
		#4000;
		#2000; enable <= 0; select_medium <= 2'd0; #100; enable <= 1;
		#2000; enable <= 0; select_medium <= 2'd1; #100; enable <= 1;
		#2000; enable <= 0; select_medium <= 2'd2; #100; enable <= 1;
		#2000; enable <= 0; select_medium <= 2'd3; #100; enable <= 1;
		#4000;
		#2000; enable <= 0; select_fine <= 2'd0; #100; enable <= 1;
		#2000; enable <= 0; select_fine <= 2'd1; #100; enable <= 1;
		#2000; enable <= 0; select_fine <= 2'd2; #100; enable <= 1;
		#2000; enable <= 0; select_fine <= 2'd3; #100; enable <= 1;
		#4000;
		enable <= 0;
		#20;
		$finish;
	end
endmodule

//	bus_entry_3state #(.WIDTH(7)) my3sbe (.I(pre_bus), .O(bus), .T(write));
module bus_entry_3state #(
	parameter WIDTH = 8
) (
	input [WIDTH-1:0] I,
	output [WIDTH-1:0] O,
	input T
);
	assign O = T ? I : WIDTH*{1'bz};
endmodule

//module bidirectional_bus #(
//	parameter WIDTH = 8
//) (
//	inout [WIDTH-1:0] A,
//	inout [WIDTH-1:0] B,
//	input direction
//);
//	assign A =  direction ? B : WIDTH*{1'bz};
//	assign B = ~direction ? A : WIDTH*{1'bz};
////	always @(direction) begin
////	if (direction) begin
////		assign A = B;
////	end else begin
////		assign B = A;
////	end
//endmodule

//module bidirectional_bus_tb;
//	localparam WIDTH = 8;
//	reg [WIDTH-1:0] pre_A = 0;
//	reg [WIDTH-1:0] pre_B = 0;
//	wire [WIDTH-1:0] A;
//	wire [WIDTH-1:0] B;
//	reg direction = 0;
//	bidirectional_bus #(.WIDTH(8)) bdb (.A(A), .B(B), .direction(direction));
//	initial begin
//		#100;
//		pre_A <= 8'h45;
//		#100;
//		pre_B <= 8'h78;
//		#100;
//		direction <= 1;
//		assign B = pre_B;
//		#100;
//		direction <= 0;
//		assign A = pre_A;
//		assign B = WIDTH*{1'bz};
//	end
//endmodule

