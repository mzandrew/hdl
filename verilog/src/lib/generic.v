// written 2019-09-22 by mza
// last updated 2021-07-01 by mza
`ifndef GENERIC_LIB
`define GENERIC_LIB

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

module mux_4to1 #(
	parameter WIDTH = 1
) (
	input [WIDTH-1:0] in0, in1, in2, in3,
	input [1:0] sel,
	output [WIDTH-1:0] out
);
	assign out =
		(sel==2'd0) ? in0 :
		(sel==2'd1) ? in1 :
		(sel==2'd2) ? in2 :
		              in3 ;
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

module mux_32to1 #(
	parameter WIDTH = 1
) (
	input [WIDTH-1:0]
		in00, in01, in02, in03, in04, in05, in06, in07,
		in08, in09, in10, in11, in12, in13, in14, in15,
		in16, in17, in18, in19, in20, in21, in22, in23,
		in24, in25, in26, in27, in28, in29, in30, in31,
	input [4:0] sel,
	output [WIDTH-1:0] out
);
	assign out =
		(sel==5'd00) ? in00 :
		(sel==5'd01) ? in01 :
		(sel==5'd02) ? in02 :
		(sel==5'd03) ? in03 :
		(sel==5'd04) ? in04 :
		(sel==5'd05) ? in05 :
		(sel==5'd06) ? in06 :
		(sel==5'd07) ? in07 :
		(sel==5'd08) ? in08 :
		(sel==5'd09) ? in09 :
		(sel==5'd10) ? in10 :
		(sel==5'd11) ? in11 :
		(sel==5'd12) ? in12 :
		(sel==5'd13) ? in13 :
		(sel==5'd14) ? in14 :
		(sel==5'd15) ? in15 :
		(sel==5'd16) ? in16 :
		(sel==5'd17) ? in17 :
		(sel==5'd18) ? in18 :
		(sel==5'd19) ? in19 :
		(sel==5'd20) ? in20 :
		(sel==5'd21) ? in21 :
		(sel==5'd22) ? in22 :
		(sel==5'd23) ? in23 :
		(sel==5'd24) ? in24 :
		(sel==5'd25) ? in25 :
		(sel==5'd26) ? in26 :
		(sel==5'd27) ? in27 :
		(sel==5'd28) ? in28 :
		(sel==5'd29) ? in29 :
		(sel==5'd30) ? in30 :
		               in31;
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

module demux_1to32 #(
	parameter WIDTH = 1,
	parameter [WIDTH-1:0] default_value = 0
) (
	input [WIDTH-1:0] in,
	input [4:0] sel,
	output [WIDTH-1:0]
		out00, out01, out02, out03, out04, out05, out06, out07,
		out08, out09, out10, out11, out12, out13, out14, out15,
		out16, out17, out18, out19, out20, out21, out22, out23,
		out24, out25, out26, out27, out28, out29, out30, out31
);
	assign out00 = (sel==5'd00) ? in : default_value;
	assign out01 = (sel==5'd01) ? in : default_value;
	assign out02 = (sel==5'd02) ? in : default_value;
	assign out03 = (sel==5'd03) ? in : default_value;
	assign out04 = (sel==5'd04) ? in : default_value;
	assign out05 = (sel==5'd05) ? in : default_value;
	assign out06 = (sel==5'd06) ? in : default_value;
	assign out07 = (sel==5'd07) ? in : default_value;
	assign out08 = (sel==5'd08) ? in : default_value;
	assign out09 = (sel==5'd09) ? in : default_value;
	assign out10 = (sel==5'd10) ? in : default_value;
	assign out11 = (sel==5'd11) ? in : default_value;
	assign out12 = (sel==5'd12) ? in : default_value;
	assign out13 = (sel==5'd13) ? in : default_value;
	assign out14 = (sel==5'd14) ? in : default_value;
	assign out15 = (sel==5'd15) ? in : default_value;
	assign out16 = (sel==5'd16) ? in : default_value;
	assign out17 = (sel==5'd17) ? in : default_value;
	assign out18 = (sel==5'd18) ? in : default_value;
	assign out19 = (sel==5'd19) ? in : default_value;
	assign out20 = (sel==5'd20) ? in : default_value;
	assign out21 = (sel==5'd21) ? in : default_value;
	assign out22 = (sel==5'd22) ? in : default_value;
	assign out23 = (sel==5'd23) ? in : default_value;
	assign out24 = (sel==5'd24) ? in : default_value;
	assign out25 = (sel==5'd25) ? in : default_value;
	assign out26 = (sel==5'd26) ? in : default_value;
	assign out27 = (sel==5'd27) ? in : default_value;
	assign out28 = (sel==5'd28) ? in : default_value;
	assign out29 = (sel==5'd29) ? in : default_value;
	assign out30 = (sel==5'd30) ? in : default_value;
	assign out31 = (sel==5'd31) ? in : default_value;
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
`ifdef XILINX
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
`endif
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

module ring_oscillator_tb;
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
	input T,
	inout [WIDTH-1:0] O
);
	assign O = T ? I : {WIDTH{1'bz}};
endmodule

//module bidirectional_bus #(
//	parameter WIDTH = 8
//) (
//	inout [WIDTH-1:0] A,
//	inout [WIDTH-1:0] B,
//	input direction
//);
//	assign A =  direction ? B : {WIDTH{1'bz}};
//	assign B = ~direction ? A : {WIDTH{1'bz}};
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
//		assign B = {WIDTH{1'bz}};
//	end
//endmodule

module clock #(
	parameter FREQUENCY_OF_CLOCK_HZ = 10000000.0,
	parameter PERIOD_OF_CLOCK_NS = 1000000000.0/FREQUENCY_OF_CLOCK_HZ, // WHOLE_PERIOD
	parameter HALF_PERIOD_OF_CLOCK_NS = PERIOD_OF_CLOCK_NS / 2.0
) (
	output reg clock = 0
);
	initial begin
		$display("creating clock with half period of %f ns", HALF_PERIOD_OF_CLOCK_NS);
	end
	always begin
		#HALF_PERIOD_OF_CLOCK_NS;
		clock = ~clock;
	end
endmodule

//	ddr mario (.clock(clock), .reset(reset), .data0_in(), .data1_in(), .data_out());
module ddr (
	input clock,
	input reset,
	input data0_in, data1_in,
	output data_out
);
	wire clock0, clock180;
	//BUFIO2 #(.DIVIDE(2), .USE_DOUBLER("TRUE"), .I_INVERT("FALSE")) b0 (.I(clock), .IOCLK(clock0),   .DIVCLK(), .SERDESSTROBE());
	//BUFIO2 #(.DIVIDE(2), .USE_DOUBLER("FALSE"), .I_INVERT("TRUE")) b1 (.I(clock), .IOCLK(clock180), .DIVCLK(), .SERDESSTROBE());
	assign clock0 = clock;
	assign clock180 = ~clock;
	ODDR2 #(.DDR_ALIGNMENT("NONE")) ddr (.C0(clock0), .C1(clock180), .CE(1'b1), .D0(data0_in), .D1(data1_in), .R(reset), .S(1'b0), .Q(data_out));
endmodule

`endif

