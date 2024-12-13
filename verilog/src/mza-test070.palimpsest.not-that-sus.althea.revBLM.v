// generated 2024-11-20 by https://github.com/mzandrew/bin/blob/master/physics/not_that_sus.py
// last updated 2024-12-13 by mza

`define althea_revBLM
`include "lib/generic.v"
`include "lib/i2s.v"

//grid quantity=[3, 3, 3]
//receiver_location = [[-0.017, 0.0, 0.0], [0.017, 0.0, 0.0]]
//receiver_bounding_box = [[-0.017, 0.0, 0.0], [0.017, 0.0, 0.0]]
//grid_location[0][0][0] = [-0.05, -0.05, 0.0]  delays_in_sample_times[0][0][0] = [2, 3]
//grid_location[0][1][0] = [-0.05, 0.0, 0.0]  delays_in_sample_times[0][1][0] = [2, 3]
//grid_location[0][2][0] = [-0.05, 0.05, 0.0]  delays_in_sample_times[0][2][0] = [2, 3]
//grid_location[1][0][0] = [0.0, -0.05, 0.0]  delays_in_sample_times[1][0][0] = [2, 2]
//grid_location[1][1][0] = [0.0, 0.0, 0.0]  delays_in_sample_times[1][1][0] = [1, 1]
//grid_location[1][2][0] = [0.0, 0.05, 0.0]  delays_in_sample_times[1][2][0] = [2, 2]
//grid_location[2][0][0] = [0.05, -0.05, 0.0]  delays_in_sample_times[2][0][0] = [3, 2]
//grid_location[2][1][0] = [0.05, 0.0, 0.0]  delays_in_sample_times[2][1][0] = [3, 2]
//grid_location[2][2][0] = [0.05, 0.05, 0.0]  delays_in_sample_times[2][2][0] = [3, 2]
//grid_bounding_box = [[-0.05, -0.05, 0.0], [0.05, 0.05, 0.0]]
//grid_center = [0.0, 0.0, 0.0]
//grid_quantity = [3, 3, 1]
//sample_rate = 11025 Hz
//bits_per_sample = 3
//distance_per_sample_time = 0.03111111111111111 m
//minimum_instrumented_delay = 1
//maximum_instrumented_delay = 3
//number_of_grid_points / correlators needed = 9
//number_of_receivers / number of taps per correlator needed = 2
//total number of delays needed = 18
//approximate total number of bits needed for samples = 18
//receiver delays in sample times:
//receiver 0: [2, 2, 2, 2, 1, 2, 3, 3, 3] (qty=9; max=3)
//receiver 1: [3, 3, 3, 2, 1, 2, 2, 2, 2] (qty=9; max=3)

module correlator2 #(
	parameter WIDTH = 3,
	parameter NUMBER_OF_INPUTS = 2,
	parameter NUMBER_OF_BITS_OF_OUTPUT = NUMBER_OF_INPUTS * WIDTH
) (
	input clock,
	input [WIDTH-1:0] i0, i1,
	output reg [NUMBER_OF_BITS_OF_OUTPUT-1:0] o = 0
);
	always @(posedge clock) begin
		o <= i0 * i1;
	end
endmodule

module sus #(
	parameter RECEIVER_SUBWORD_WIDTH = 3,
	parameter RECEIVER0_PIPELINE_LENGTH_IN_SUBWORDS = 3*RECEIVER_SUBWORD_WIDTH,
	parameter RECEIVER1_PIPELINE_LENGTH_IN_SUBWORDS = 3*RECEIVER_SUBWORD_WIDTH,
	parameter RECEIVER_WORD_WIDTH = 18,
	parameter NUMBER_OF_BITS_OF_OUTPUT = 6
) (
	input clock,
	input [RECEIVER_WORD_WIDTH-1:0] receiver0_data_word, receiver1_data_word,
	output [NUMBER_OF_BITS_OF_OUTPUT-1:0] grid_0_0_0, grid_0_1_0, grid_0_2_0, grid_1_0_0, grid_1_1_0, grid_1_2_0, grid_2_0_0, grid_2_1_0, grid_2_2_0
);
	reg [RECEIVER0_PIPELINE_LENGTH_IN_SUBWORDS*RECEIVER_SUBWORD_WIDTH-1:0] receiver0_pipeline = 0;
	reg [RECEIVER1_PIPELINE_LENGTH_IN_SUBWORDS*RECEIVER_SUBWORD_WIDTH-1:0] receiver1_pipeline = 0;
	always @(posedge clock) begin
		receiver0_pipeline <= { receiver0_pipeline[(RECEIVER0_PIPELINE_LENGTH_IN_SUBWORDS-1)*RECEIVER_SUBWORD_WIDTH-1:0], receiver0_data_word[RECEIVER_WORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH] };
	end
	always @(posedge clock) begin
		receiver1_pipeline <= { receiver1_pipeline[(RECEIVER1_PIPELINE_LENGTH_IN_SUBWORDS-1)*RECEIVER_SUBWORD_WIDTH-1:0], receiver1_data_word[RECEIVER_WORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH] };
	end
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_0_0 = receiver0_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_0_0 = receiver1_pipeline[3*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator2 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_0_0 (.clock(clock), .i0(tap0_0_0_0), .i1(tap1_0_0_0), .o(grid_0_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_1_0 = receiver0_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_1_0 = receiver1_pipeline[3*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator2 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_1_0 (.clock(clock), .i0(tap0_0_1_0), .i1(tap1_0_1_0), .o(grid_0_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_0_2_0 = receiver0_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_0_2_0 = receiver1_pipeline[3*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator2 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_0_2_0 (.clock(clock), .i0(tap0_0_2_0), .i1(tap1_0_2_0), .o(grid_0_2_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_0_0 = receiver0_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_0_0 = receiver1_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator2 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_0_0 (.clock(clock), .i0(tap0_1_0_0), .i1(tap1_1_0_0), .o(grid_1_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_1_0 = receiver0_pipeline[1*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_1_0 = receiver1_pipeline[1*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator2 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_1_0 (.clock(clock), .i0(tap0_1_1_0), .i1(tap1_1_1_0), .o(grid_1_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_1_2_0 = receiver0_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_1_2_0 = receiver1_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator2 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_1_2_0 (.clock(clock), .i0(tap0_1_2_0), .i1(tap1_1_2_0), .o(grid_1_2_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_0_0 = receiver0_pipeline[3*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_0_0 = receiver1_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator2 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_0_0 (.clock(clock), .i0(tap0_2_0_0), .i1(tap1_2_0_0), .o(grid_2_0_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_1_0 = receiver0_pipeline[3*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_1_0 = receiver1_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator2 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_1_0 (.clock(clock), .i0(tap0_2_1_0), .i1(tap1_2_1_0), .o(grid_2_1_0));
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap0_2_2_0 = receiver0_pipeline[3*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	wire [RECEIVER_SUBWORD_WIDTH-1:0] tap1_2_2_0 = receiver1_pipeline[2*RECEIVER_SUBWORD_WIDTH-1-:RECEIVER_SUBWORD_WIDTH];
	correlator2 #(.WIDTH(RECEIVER_SUBWORD_WIDTH)) correlator_2_2_0 (.clock(clock), .i0(tap0_2_2_0), .i1(tap1_2_2_0), .o(grid_2_2_0));
endmodule

module sus_tb #(
	parameter PERIOD = 1.0,
	parameter P = PERIOD,
	parameter HALF_PERIOD = PERIOD/2,
	parameter NUMBER_OF_BITS_OF_OUTPUT = 6,
	parameter WAVEFORM_LENGTH = 16,
	parameter PIPELINE_PICKOFF = WAVEFORM_LENGTH + 6
);
	reg clock = 0;
	wire [NUMBER_OF_BITS_OF_OUTPUT-1:0] grid_0_0_0, grid_0_1_0, grid_0_2_0, grid_1_0_0, grid_1_1_0, grid_1_2_0, grid_2_0_0, grid_2_1_0, grid_2_2_0;
	wire [14:0] zeroes = 0;
	reg [2:0] r0 [PIPELINE_PICKOFF:0];
	wire [17:0] receiver0_data_word = { r0[PIPELINE_PICKOFF], zeroes };
	reg [2:0] r1 [PIPELINE_PICKOFF:0];
	wire [17:0] receiver1_data_word = { r1[PIPELINE_PICKOFF], zeroes };
	wire [2:0] waveform_a [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd1, 3'd2, 3'd3, 3'd2, 3'd1, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0 }; // triangle 3
	wire [2:0] waveform_b [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd0, 3'd1, 3'd2, 3'd1, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0 }; // triangle 2
	wire [2:0] waveform_c [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd0, 3'd2, 3'd3, 3'd2, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0 }; // truncated triangle 3
	wire [2:0] waveform_d [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd2, 3'd3, 3'd3, 3'd1, 3'd0, 3'd0, 3'd2, 3'd3, 3'd2, 3'd1, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0 }; // double peak a 3
	wire [2:0] waveform_e [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd1, 3'd2, 3'd3, 3'd2, 3'd1, 3'd2, 3'd3, 3'd2, 3'd1, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0 }; // double peak b 3
	wire [2:0] waveform_f [WAVEFORM_LENGTH-1:0] = { 3'd1, 3'd1, 3'd1, 3'd3, 3'd1, 3'd1, 3'd1, 3'd1, 3'd1, 3'd3, 3'd2, 3'd1, 3'd0, 3'd0, 3'd0, 3'd0 }; // double peak c 3
	wire [2:0] waveform_g [WAVEFORM_LENGTH-1:0] = { 3'd1, 3'd2, 3'd3, 3'd3, 3'd3, 3'd3, 3'd3, 3'd3, 3'd3, 3'd3, 3'd3, 3'd3, 3'd3, 3'd3, 3'd2, 3'd1 }; // square a 3
	wire [2:0] waveform_h [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd1, 3'd2, 3'd2, 3'd2, 3'd2, 3'd2, 3'd2, 3'd2, 3'd2, 3'd2, 3'd2, 3'd2, 3'd2, 3'd1, 3'd0 }; // square b 2
	wire [2:0] waveform_i [WAVEFORM_LENGTH-1:0] = { 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd1, 3'd2, 3'd3, 3'd2, 3'd1, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0 }; // triangle 3
	reg stim = 0;
	sus mysus (.clock(clock),
		.receiver0_data_word(receiver0_data_word), .receiver1_data_word(receiver1_data_word),
		.grid_0_0_0(grid_0_0_0), .grid_0_1_0(grid_0_1_0), .grid_0_2_0(grid_0_2_0), .grid_1_0_0(grid_1_0_0), .grid_1_1_0(grid_1_1_0), .grid_1_2_0(grid_1_2_0), .grid_2_0_0(grid_2_0_0), .grid_2_1_0(grid_2_1_0), .grid_2_2_0(grid_2_2_0));
	always begin
		#0.5; clock <= ~clock;
	end
	integer i;
	always @(posedge clock) begin
		for (i=1; i<=PIPELINE_PICKOFF; i=i+1) begin
			r0[i] <= r0[i-1];
			r1[i] <= r1[i-1];
		end
		r0[0] <= 0;
		r1[0] <= 0;
	end
	initial begin
		for (i=0; i<=PIPELINE_PICKOFF; i=i+1) begin
			r0[i] <= 0;
			r1[i] <= 0;
		end
		#(12*P); stim<=1; #P; stim<=0; #P; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[2+i] <= waveform_g[WAVEFORM_LENGTH-i-1]; r1[3+i] <= waveform_h[WAVEFORM_LENGTH-i-1]; end // grid_0_0_0
		#(12*P); stim<=1; #P; stim<=0; #P; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[2+i] <= waveform_g[WAVEFORM_LENGTH-i-1]; r1[3+i] <= waveform_h[WAVEFORM_LENGTH-i-1]; end // grid_0_1_0
		#(12*P); stim<=1; #P; stim<=0; #P; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[2+i] <= waveform_g[WAVEFORM_LENGTH-i-1]; r1[3+i] <= waveform_h[WAVEFORM_LENGTH-i-1]; end // grid_0_2_0
		#(12*P); stim<=1; #P; stim<=0; #P; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[2+i] <= waveform_g[WAVEFORM_LENGTH-i-1]; r1[2+i] <= waveform_h[WAVEFORM_LENGTH-i-1]; end // grid_1_0_0
		#(12*P); stim<=1; #P; stim<=0; #P; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[1+i] <= waveform_g[WAVEFORM_LENGTH-i-1]; r1[1+i] <= waveform_h[WAVEFORM_LENGTH-i-1]; end // grid_1_1_0
		#(12*P); stim<=1; #P; stim<=0; #P; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[2+i] <= waveform_g[WAVEFORM_LENGTH-i-1]; r1[2+i] <= waveform_h[WAVEFORM_LENGTH-i-1]; end // grid_1_2_0
		#(12*P); stim<=1; #P; stim<=0; #P; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[3+i] <= waveform_g[WAVEFORM_LENGTH-i-1]; r1[2+i] <= waveform_h[WAVEFORM_LENGTH-i-1]; end // grid_2_0_0
		#(12*P); stim<=1; #P; stim<=0; #P; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[3+i] <= waveform_g[WAVEFORM_LENGTH-i-1]; r1[2+i] <= waveform_h[WAVEFORM_LENGTH-i-1]; end // grid_2_1_0
		#(12*P); stim<=1; #P; stim<=0; #P; for (i=0; i<WAVEFORM_LENGTH; i=i+1) begin r0[3+i] <= waveform_g[WAVEFORM_LENGTH-i-1]; r1[2+i] <= waveform_h[WAVEFORM_LENGTH-i-1]; end // grid_2_2_0
		#12; $finish;
	end
endmodule

module sus_implementation #(
	parameter NUMBER_OF_RECEIVERS = 3,
	parameter NUMBER_OF_BITS_OF_INPUT = 24,
	parameter NUMBER_OF_BITS_OF_INPUT_SIGNIFICANCE = 3,
	parameter NUMBER_OF_BITS_OF_INPUT_INSIGNIFICANCE = NUMBER_OF_BITS_OF_INPUT - NUMBER_OF_BITS_OF_INPUT_SIGNIFICANCE,
	parameter NUMBER_OF_BITS_OF_OUTPUT = NUMBER_OF_RECEIVERS * NUMBER_OF_BITS_OF_INPUT_SIGNIFICANCE,
	parameter OUTPUT_BIT_PICKOFF = 4,
	parameter EXTRA_FACTOR = 3,
	parameter NUMBER_OF_CHANNELS_IN_I2S = 2,
	parameter METASTABILITY_EXTRA = 3,
	parameter PIPELINE_PICKOFF = EXTRA_FACTOR * NUMBER_OF_BITS_OF_INPUT * NUMBER_OF_CHANNELS_IN_I2S + METASTABILITY_EXTRA,
	parameter SERDES_WIDTH = 8,
	parameter PLLPERIOD = 10.0, // 100 MHz
	parameter OVERALL_PLLDIVIDE = 2,
	parameter PLLMULTIPLY = 8,
	parameter PLLDIVIDE = 8,
	parameter SAMPLE_CLOCK_DIVIDE = 4,
	parameter WORD_CLOCK_DIVIDE = 3,
	parameter BIT_CLOCK_DIVIDE = 2
) (
	input clock_in_p, clock_in_n,
	output clock_a, clock_b, clock_c,
	input data_a, data_b, data_c,
	input ws_a, ws_b, ws_c,
	output [7:0] led
);
	wire reset = 0;
	wire clock_in;
	IBUFGDS hogarth (.I(clock_in_p), .IB(clock_in_n), .O(clock_in));
	wire raw_sample_clock, sample_clock;
	wire raw_word_clock, word_clock;
	wire bit_clock;
	wire pll_is_locked;
	simplepll_ADV #(
		.PERIOD(PLLPERIOD), .OVERALL_DIVIDE(OVERALL_PLLDIVIDE), .MULTIPLY(PLLMULTIPLY), .DIVIDE(PLLDIVIDE),
		.DIVIDE0(WORD_CLOCK_DIVIDE), .DIVIDE1(BIT_CLOCK_DIVIDE),
		.DIVIDE2(SAMPLE_CLOCK_DIVIDE), .DIVIDE3(1),
		.DIVIDE4(1), .DIVIDE5(1),
		.PHASE0(0.0),  .PHASE1(0.0),
		.PHASE2(0.0),  .PHASE3(0.0),
		.PHASE4(0.0),  .PHASE5(0.0)
	) mypll (
		.clockin(clock_in),
		.reset(reset),
		.clock0out(raw_word_clock), .clock1out(bit_clock),
		.clock2out(raw_sample_clock), .clock3out(),
		.clock4out(), .clock5out(),
		.locked(pll_is_locked));
//		.clock_1x(raw_word_clock), // word_clock for BUFG
//		.clock_nx(bit_clock) // bit clock for IOSERDES
	BUFG wordy (.I(raw_word_clock), .O(word_clock));
	reg [PIPELINE_PICKOFF:0] ws_a_pipeline = 0, ws_b_pipeline = 0;
	reg [PIPELINE_PICKOFF:0] data_a_pipeline = 0, data_b_pipeline = 0;
	always @(posedge clock_in) begin
		ws_a_pipeline <= { ws_a_pipeline[PIPELINE_PICKOFF-2:0], ws_a };
		ws_b_pipeline <= { ws_b_pipeline[PIPELINE_PICKOFF-2:0], ws_b };
		data_a_pipeline <= { data_a_pipeline[PIPELINE_PICKOFF-2:0], data_a };
		data_b_pipeline <= { data_b_pipeline[PIPELINE_PICKOFF-2:0], data_b };
		if (ws_a_pipeline[PIPELINE_PICKOFF]) begin
			//data_a_buffered <= data_a_pipeline;
		end
	end
	wire [17:0] receiver0_data_word;
	wire [17:0] receiver1_data_word;
	wire [NUMBER_OF_BITS_OF_OUTPUT-1:0] grid_0_0_0, grid_0_1_0, grid_0_2_0, grid_1_0_0, grid_1_1_0, grid_1_2_0, grid_2_0_0, grid_2_1_0, grid_2_2_0, grid_3_0_0, grid_3_1_0, grid_3_2_0;
	assign led[0] = grid_0_0_0[OUTPUT_BIT_PICKOFF];
	assign led[1] = grid_0_1_0[OUTPUT_BIT_PICKOFF];
	assign led[2] = grid_0_2_0[OUTPUT_BIT_PICKOFF];
	assign led[3] = grid_1_0_0[OUTPUT_BIT_PICKOFF];
	assign led[4] = grid_1_1_0[OUTPUT_BIT_PICKOFF];
	assign led[5] = grid_1_2_0[OUTPUT_BIT_PICKOFF];
	assign led[6] = grid_2_0_0[OUTPUT_BIT_PICKOFF];
	assign led[7] = grid_2_1_0[OUTPUT_BIT_PICKOFF];
	sus mysus (.clock(clock),
		.receiver0_data_word(receiver0_data_word), .receiver1_data_word(receiver1_data_word),
		.grid_0_0_0(grid_0_0_0), .grid_0_1_0(grid_0_1_0), .grid_0_2_0(grid_0_2_0), .grid_1_0_0(grid_1_0_0), .grid_1_1_0(grid_1_1_0), .grid_1_2_0(grid_1_2_0), .grid_2_0_0(grid_2_0_0), .grid_2_1_0(grid_2_1_0), .grid_2_2_0(grid_2_2_0), .grid_3_0_0(grid_3_0_0), .grid_3_1_0(grid_3_1_0), .grid_3_2_0(grid_3_2_0));
endmodule

module sus_implementation_tb;
endmodule

