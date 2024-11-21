// generated 2024-11-20 by https://github.com/mzandrew/bin/blob/master/physics/not_that_sus.py
// last updated 2024-11-20 by mza

module correlator3 #(
	parameter WIDTH = 3,
	parameter NUMBER_OF_INPUTS = 3,
	parameter NUMBER_OF_BITS_OF_OUTPUT = NUMBER_OF_INPUTS * WIDTH
) (
	input clock,
	input [WIDTH-1:0] i0, i1, i2,
	output reg [NUMBER_OF_BITS_OF_OUTPUT-1:0] o = 0
);
	always @(posedge clock) begin
		o <= i0 * i1 * i2;
	end
endmodule

module sus #(
	parameter RECEIVER_SUBWORD_WIDTH = 3,
	parameter RECEIVER0_PIPELINE_LENGTH_IN_SUBWORDS = 11*RECEIVER_SUBWORD_WIDTH,
	parameter RECEIVER1_PIPELINE_LENGTH_IN_SUBWORDS = 11*RECEIVER_SUBWORD_WIDTH,
	parameter RECEIVER2_PIPELINE_LENGTH_IN_SUBWORDS = 10*RECEIVER_SUBWORD_WIDTH,
	parameter RECEIVER_WORD_WIDTH = 18,
	parameter NUMBER_OF_BITS_OF_OUTPUT = 9
) (
	input clock,
	input [RECEIVER_WORD_WIDTH-1:0] receiver0_data_word, receiver1_data_word, receiver2_data_word,
	output [NUMBER_OF_BITS_OF_OUTPUT-1:0] grid_0_0_0, grid_0_1_0, grid_0_2_0, grid_0_3_0, grid_1_0_0, grid_1_1_0, grid_1_2_0, grid_1_3_0, grid_2_0_0, grid_2_1_0, grid_2_2_0, grid_2_3_0, grid_3_0_0, grid_3_1_0, grid_3_2_0, grid_3_3_0
);
	reg [RECEIVER0_PIPELINE_LENGTH_IN_SUBWORDS*RECEIVER_SUBWORD_WIDTH-1:0] receiver0_pipeline = 0;
	reg [RECEIVER1_PIPELINE_LENGTH_IN_SUBWORDS*RECEIVER_SUBWORD_WIDTH-1:0] receiver1_pipeline = 0;
	reg [RECEIVER2_PIPELINE_LENGTH_IN_SUBWORDS*RECEIVER_SUBWORD_WIDTH-1:0] receiver2_pipeline = 0;
	always @(posedge clock) begin
		receiver0_pipeline <= { receiver0_pipeline[(RECEIVER0_PIPELINE_LENGTH_IN_SUBWORDS-1)*RECEIVER_SUBWORD_WIDTH-1:0], receiver0_data_word[RECEIVER_WORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH] };
		receiver1_pipeline <= { receiver1_pipeline[(RECEIVER1_PIPELINE_LENGTH_IN_SUBWORDS-1)*RECEIVER_SUBWORD_WIDTH-1:0], receiver1_data_word[RECEIVER_WORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH] };
		receiver2_pipeline <= { receiver2_pipeline[(RECEIVER2_PIPELINE_LENGTH_IN_SUBWORDS-1)*RECEIVER_SUBWORD_WIDTH-1:0], receiver2_data_word[RECEIVER_WORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH] };
	end
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_0_0 = receiver0_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_0_0 = receiver1_pipeline[11*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_0_0_0 = receiver2_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_0_0 (.clock(clock), .i0(tap0_0_0_0), .i1(tap1_0_0_0), .i2(tap2_0_0_0), .o(grid_0_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_1_0 = receiver0_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_1_0 = receiver1_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_0_1_0 = receiver2_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_1_0 (.clock(clock), .i0(tap0_0_1_0), .i1(tap1_0_1_0), .i2(tap2_0_1_0), .o(grid_0_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_2_0 = receiver0_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_2_0 = receiver1_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_0_2_0 = receiver2_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_2_0 (.clock(clock), .i0(tap0_0_2_0), .i1(tap1_0_2_0), .i2(tap2_0_2_0), .o(grid_0_2_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_3_0 = receiver0_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_3_0 = receiver1_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_0_3_0 = receiver2_pipeline[10*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_3_0 (.clock(clock), .i0(tap0_0_3_0), .i1(tap1_0_3_0), .i2(tap2_0_3_0), .o(grid_0_3_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_0_0 = receiver0_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_0_0 = receiver1_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_1_0_0 = receiver2_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_0_0 (.clock(clock), .i0(tap0_1_0_0), .i1(tap1_1_0_0), .i2(tap2_1_0_0), .o(grid_1_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_1_0 = receiver0_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_1_0 = receiver1_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_1_1_0 = receiver2_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_1_0 (.clock(clock), .i0(tap0_1_1_0), .i1(tap1_1_1_0), .i2(tap2_1_1_0), .o(grid_1_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_2_0 = receiver0_pipeline[0*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_2_0 = receiver1_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_1_2_0 = receiver2_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_2_0 (.clock(clock), .i0(tap0_1_2_0), .i1(tap1_1_2_0), .i2(tap2_1_2_0), .o(grid_1_2_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_3_0 = receiver0_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_3_0 = receiver1_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_1_3_0 = receiver2_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_3_0 (.clock(clock), .i0(tap0_1_3_0), .i1(tap1_1_3_0), .i2(tap2_1_3_0), .o(grid_1_3_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_0_0 = receiver0_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_0_0 = receiver1_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_2_0_0 = receiver2_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_0_0 (.clock(clock), .i0(tap0_2_0_0), .i1(tap1_2_0_0), .i2(tap2_2_0_0), .o(grid_2_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_1_0 = receiver0_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_1_0 = receiver1_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_2_1_0 = receiver2_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_1_0 (.clock(clock), .i0(tap0_2_1_0), .i1(tap1_2_1_0), .i2(tap2_2_1_0), .o(grid_2_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_2_0 = receiver0_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_2_0 = receiver1_pipeline[0*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_2_2_0 = receiver2_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_2_0 (.clock(clock), .i0(tap0_2_2_0), .i1(tap1_2_2_0), .i2(tap2_2_2_0), .o(grid_2_2_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_3_0 = receiver0_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_3_0 = receiver1_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_2_3_0 = receiver2_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_3_0 (.clock(clock), .i0(tap0_2_3_0), .i1(tap1_2_3_0), .i2(tap2_2_3_0), .o(grid_2_3_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_3_0_0 = receiver0_pipeline[11*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_3_0_0 = receiver1_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_3_0_0 = receiver2_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_3_0_0 (.clock(clock), .i0(tap0_3_0_0), .i1(tap1_3_0_0), .i2(tap2_3_0_0), .o(grid_3_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_3_1_0 = receiver0_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_3_1_0 = receiver1_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_3_1_0 = receiver2_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_3_1_0 (.clock(clock), .i0(tap0_3_1_0), .i1(tap1_3_1_0), .i2(tap2_3_1_0), .o(grid_3_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_3_2_0 = receiver0_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_3_2_0 = receiver1_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_3_2_0 = receiver2_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_3_2_0 (.clock(clock), .i0(tap0_3_2_0), .i1(tap1_3_2_0), .i2(tap2_3_2_0), .o(grid_3_2_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_3_3_0 = receiver0_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_3_3_0 = receiver1_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_3_3_0 = receiver2_pipeline[10*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_3_3_0 (.clock(clock), .i0(tap0_3_3_0), .i1(tap1_3_3_0), .i2(tap2_3_3_0), .o(grid_3_3_0));
endmodule

module sus_tb;
	reg clock = 0;
	reg reset = 1;
	wire [8:0] grid_0_0_0;
	reg [17:0] receiver0_data_word = 0;
	reg [17:0] receiver1_data_word = 0;
	reg [17:0] receiver2_data_word = 0;
	sus mysus (.clock(clock),
		.receiver0_data_word(receiver0_data_word),.receiver1_data_word(receiver1_data_word), .receiver2_data_word(receiver2_data_word),
		.grid_0_0_0(grid_0_0_0), .grid_0_1_0(), .grid_0_2_0(), .grid_0_3_0(), .grid_1_0_0(), .grid_1_1_0(), .grid_1_2_0(), .grid_1_3_0(),
		.grid_2_0_0(), .grid_2_1_0(), .grid_2_2_0(), .grid_2_3_0(), .grid_3_0_0(), .grid_3_1_0(), .grid_3_2_0(), .grid_3_3_0());
	always begin
		#1; clock <= ~clock;
	end
	initial begin
		receiver0_data_word <= { 3'd1, 15'd0 };
		receiver1_data_word <= { 3'd6, 15'd0 };
		receiver2_data_word <= { 3'd7, 15'd0 };
		#10; reset <= 0;
		#250;
		receiver0_data_word <= { 3'd3, 15'd0 };
		receiver1_data_word <= { 3'd3, 15'd0 };
		receiver2_data_word <= { 3'd3, 15'd0 };
		#250;
		receiver0_data_word <= { 3'd0, 15'd0 };
		receiver1_data_word <= { 3'd2, 15'd0 };
		receiver2_data_word <= { 3'd4, 15'd0 };
		#250;
		receiver0_data_word <= { 3'd7, 15'd0 };
		receiver1_data_word <= { 3'd7, 15'd0 };
		receiver2_data_word <= { 3'd7, 15'd0 };
		#1000; $finish;
	end
endmodule

