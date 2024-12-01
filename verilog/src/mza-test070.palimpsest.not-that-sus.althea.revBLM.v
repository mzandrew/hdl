// generated 2024-11-20 by https://github.com/mzandrew/bin/blob/master/physics/not_that_sus.py
// last updated 2024-11-30 by mza

module pipeline_correlator3 #(
	parameter WIDTH = 3,
	parameter NUMBER_OF_INPUTS = 3,
	parameter NUMBER_OF_BITS_OF_OUTPUT = NUMBER_OF_INPUTS * WIDTH
) (
	input clock,
	input [WIDTH-1:0] i0, i1, i2,
	output reg [NUMBER_OF_BITS_OF_OUTPUT-1:0] o = 0
);
	reg [WIDTH-1:0] i0_old0 = 0, i1_old0 = 0, i2_old0 = 0, i2_old1 = 0;
	reg [NUMBER_OF_BITS_OF_OUTPUT-1:0] o_old1 = 0, o_old2 = 0;
	always @(posedge clock) begin
		i0_old0 <= i0; i1_old0 <= i1; i2_old0 <= i2;
		i2_old1 <= i2_old0;
		o_old1 <= i0_old0 * i1_old0;
		o_old2 <= o_old1 * i2_old1;
		o <= o_old2;
	end
endmodule

module instant_correlator3 #(
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

module correlator3 #(
	parameter WIDTH = 3,
	parameter NUMBER_OF_INPUTS = 3,
	parameter NUMBER_OF_BITS_OF_OUTPUT = NUMBER_OF_INPUTS * WIDTH,
	parameter PIPELINED = 1
) (
	input clock,
	input [WIDTH-1:0] i0, i1, i2,
	output [NUMBER_OF_BITS_OF_OUTPUT-1:0] o
);
	if (PIPELINED) begin
		pipeline_correlator3 #(.WIDTH(WIDTH)) pipeco (.clock(clock), .i0(i0), .i1(i1), .i2(i2), .o(o));
	end else begin
		instant_correlator3 #(.WIDTH(WIDTH)) insta (.clock(clock), .i0(i0), .i1(i1), .i2(i2), .o(o));
	end
endmodule

module sus #(
	parameter RECEIVER_SUBWORD_WIDTH = 3,
	parameter RECEIVER0_PIPELINE_LENGTH_IN_SUBWORDS = 10*RECEIVER_SUBWORD_WIDTH,
	parameter RECEIVER1_PIPELINE_LENGTH_IN_SUBWORDS = 10*RECEIVER_SUBWORD_WIDTH,
	parameter RECEIVER2_PIPELINE_LENGTH_IN_SUBWORDS = 8*RECEIVER_SUBWORD_WIDTH,
	parameter RECEIVER_WORD_WIDTH = 18,
	parameter NUMBER_OF_BITS_OF_OUTPUT = 9
) (
	input clock,
	input [RECEIVER_WORD_WIDTH-1:0] receiver0_data_word, receiver1_data_word, receiver2_data_word,
	output [NUMBER_OF_BITS_OF_OUTPUT-1:0] grid_0_0_0, grid_0_1_0, grid_0_2_0, grid_1_0_0, grid_1_1_0, grid_1_2_0, grid_2_0_0, grid_2_1_0, grid_2_2_0, grid_3_0_0, grid_3_1_0, grid_3_2_0
);
	reg [RECEIVER0_PIPELINE_LENGTH_IN_SUBWORDS*RECEIVER_SUBWORD_WIDTH-1:0] receiver0_pipeline = 0;
	reg [RECEIVER1_PIPELINE_LENGTH_IN_SUBWORDS*RECEIVER_SUBWORD_WIDTH-1:0] receiver1_pipeline = 0;
	reg [RECEIVER2_PIPELINE_LENGTH_IN_SUBWORDS*RECEIVER_SUBWORD_WIDTH-1:0] receiver2_pipeline = 0;
	always @(posedge clock) begin
		receiver0_pipeline <= { receiver0_pipeline[(RECEIVER0_PIPELINE_LENGTH_IN_SUBWORDS-1)*RECEIVER_SUBWORD_WIDTH-1:0], receiver0_data_word[RECEIVER_WORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH] };
	end
	always @(posedge clock) begin
		receiver1_pipeline <= { receiver1_pipeline[(RECEIVER1_PIPELINE_LENGTH_IN_SUBWORDS-1)*RECEIVER_SUBWORD_WIDTH-1:0], receiver1_data_word[RECEIVER_WORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH] };
	end
	always @(posedge clock) begin
		receiver2_pipeline <= { receiver2_pipeline[(RECEIVER2_PIPELINE_LENGTH_IN_SUBWORDS-1)*RECEIVER_SUBWORD_WIDTH-1:0], receiver2_data_word[RECEIVER_WORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH] };
	end
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_0_0 = receiver0_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_0_0 = receiver1_pipeline[10*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_0_0_0 = receiver2_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_0_0 (.clock(clock), .i0(tap0_0_0_0), .i1(tap1_0_0_0), .i2(tap2_0_0_0), .o(grid_0_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_1_0 = receiver0_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_1_0 = receiver1_pipeline[9*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_0_1_0 = receiver2_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_1_0 (.clock(clock), .i0(tap0_0_1_0), .i1(tap1_0_1_0), .i2(tap2_0_1_0), .o(grid_0_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_2_0 = receiver0_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_2_0 = receiver1_pipeline[9*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_0_2_0 = receiver2_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_2_0 (.clock(clock), .i0(tap0_0_2_0), .i1(tap1_0_2_0), .i2(tap2_0_2_0), .o(grid_0_2_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_0_0 = receiver0_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_0_0 = receiver1_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_1_0_0 = receiver2_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_0_0 (.clock(clock), .i0(tap0_1_0_0), .i1(tap1_1_0_0), .i2(tap2_1_0_0), .o(grid_1_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_1_0 = receiver0_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_1_0 = receiver1_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_1_1_0 = receiver2_pipeline[3*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_1_0 (.clock(clock), .i0(tap0_1_1_0), .i1(tap1_1_1_0), .i2(tap2_1_1_0), .o(grid_1_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_2_0 = receiver0_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_2_0 = receiver1_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_1_2_0 = receiver2_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_2_0 (.clock(clock), .i0(tap0_1_2_0), .i1(tap1_1_2_0), .i2(tap2_1_2_0), .o(grid_1_2_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_0_0 = receiver0_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_0_0 = receiver1_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_2_0_0 = receiver2_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_0_0 (.clock(clock), .i0(tap0_2_0_0), .i1(tap1_2_0_0), .i2(tap2_2_0_0), .o(grid_2_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_1_0 = receiver0_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_1_0 = receiver1_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_2_1_0 = receiver2_pipeline[3*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_1_0 (.clock(clock), .i0(tap0_2_1_0), .i1(tap1_2_1_0), .i2(tap2_2_1_0), .o(grid_2_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_2_0 = receiver0_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_2_0 = receiver1_pipeline[4*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_2_2_0 = receiver2_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_2_0 (.clock(clock), .i0(tap0_2_2_0), .i1(tap1_2_2_0), .i2(tap2_2_2_0), .o(grid_2_2_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_3_0_0 = receiver0_pipeline[10*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_3_0_0 = receiver1_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_3_0_0 = receiver2_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_3_0_0 (.clock(clock), .i0(tap0_3_0_0), .i1(tap1_3_0_0), .i2(tap2_3_0_0), .o(grid_3_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_3_1_0 = receiver0_pipeline[9*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_3_1_0 = receiver1_pipeline[5*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_3_1_0 = receiver2_pipeline[7*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_3_1_0 (.clock(clock), .i0(tap0_3_1_0), .i1(tap1_3_1_0), .i2(tap2_3_1_0), .o(grid_3_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_3_2_0 = receiver0_pipeline[9*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_3_2_0 = receiver1_pipeline[6*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap2_3_2_0 = receiver2_pipeline[8*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator3 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_3_2_0 (.clock(clock), .i0(tap0_3_2_0), .i1(tap1_3_2_0), .i2(tap2_3_2_0), .o(grid_3_2_0));
endmodule

module sus_tb #(
	parameter NUMBER_OF_BITS_OF_OUTPUT = 9,
	parameter WAVEFORM_LENGTH = 7,
	parameter PIPELINE_PICKOFF = 43
);
	reg clock = 0;
	reg reset = 1;
	wire [NUMBER_OF_BITS_OF_OUTPUT-1:0] grid_0_0_0, grid_0_1_0, grid_0_2_0, grid_1_0_0, grid_1_1_0, grid_1_2_0, grid_2_0_0, grid_2_1_0, grid_2_2_0, grid_3_0_0, grid_3_1_0, grid_3_2_0;
	wire [14:0] zeroes = 0;
	reg [2:0] r0 [PIPELINE_PICKOFF:0];
	reg [2:0] r1 [PIPELINE_PICKOFF:0];
	reg [2:0] r2 [PIPELINE_PICKOFF:0];
	wire [17:0] receiver0_data_word = { r0[PIPELINE_PICKOFF], zeroes };
	wire [17:0] receiver1_data_word = { r1[PIPELINE_PICKOFF], zeroes };
	wire [17:0] receiver2_data_word = { r2[PIPELINE_PICKOFF], zeroes };
	reg stim = 0;
	wire [2:0] waveform_a [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd1, 3'd2, 3'd3, 3'd2, 3'd1, 3'd0 }; // triangle 3
	wire [2:0] waveform_b [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd0, 3'd1, 3'd2, 3'd1, 3'd0, 3'd0 }; // triangle 2
	wire [2:0] waveform_c [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd0, 3'd2, 3'd3, 3'd2, 3'd0, 3'd0 }; // truncated triangle 3
	sus mysus (.clock(clock),
		.receiver0_data_word(receiver0_data_word),.receiver1_data_word(receiver1_data_word), .receiver2_data_word(receiver2_data_word),
		.grid_0_0_0(grid_0_0_0), .grid_0_1_0(grid_0_1_0), .grid_0_2_0(grid_0_2_0), .grid_1_0_0(grid_1_0_0), .grid_1_1_0(grid_1_1_0), .grid_1_2_0(grid_1_2_0), .grid_2_0_0(grid_2_0_0), .grid_2_1_0(grid_2_1_0), .grid_2_2_0(grid_2_2_0), .grid_3_0_0(grid_3_0_0), .grid_3_1_0(grid_3_1_0), .grid_3_2_0(grid_3_2_0));
	always begin
		#0.5; clock <= ~clock;
	end
	integer i;
	always @(posedge clock) begin
		for (i=1; i<=PIPELINE_PICKOFF; i=i+1) begin
			r0[i] <= r0[i-1];
			r1[i] <= r1[i-1];
			r2[i] <= r2[i-1];
		end
		r0[0] <= 0;
		r1[0] <= 0;
		r2[0] <= 0;
	end
	initial begin
		for (i=0; i<=PIPELINE_PICKOFF; i=i+1) begin
			r0[i] <= 0;
			r1[i] <= 0;
			r2[i] <= 0;
		end
		#(2*PIPELINE_PICKOFF); reset <= 0;
		#100; stim<=1; #1; stim<=0; #1; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[ 7+i] <= waveform_a[WAVEFORM_LENGTH-i-1]; r1[10+i] <= waveform_b[WAVEFORM_LENGTH-i-1]; r2[ 7+i] <= waveform_c[WAVEFORM_LENGTH-i-1]; end // grid_0_0_0 peaks at 18
		#100; $finish;
	end
endmodule

