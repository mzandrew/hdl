// written 2021-07-14 by mza
// last updated 2021-07-16 by mza

`ifndef HISTOGRAM_LIB
`define HISTOGRAM_LIB

`include "generic.v"

module histogram #(
	parameter DATA_WIDTH = 4,
	parameter LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE = 4
	// 8 uses up 92% of slice LUTs, fails timing by 78 ns and can't produce a static timing report; seems to work on hardware
	// 6 uses up 72% of slice LUTs, fails timing by 18 ns, but shows a lot of count->index[i]/j->index/index->index timing failures
	// 5 uses up 56% of slice LUTs, passes timing
) (
	input reset, clock,
	input sample,
	input clear_results,
	input [DATA_WIDTH-1:0] data_in,
	output [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count00,
	output [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count01,
	output [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count02,
	output [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count03,
	output [DATA_WIDTH-1:0] result00,
	output [DATA_WIDTH-1:0] result01,
	output [DATA_WIDTH-1:0] result02,
	output [DATA_WIDTH-1:0] result03,
	output reg max_count_reached = 0,
	output reg result_valid = 0
);
	localparam MAX_INDEX = (1<<DATA_WIDTH) - 1;
	localparam NUMBER_OF_SAMPLES_TO_ACQUIRE = (1<<LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE) - 1;
	localparam LOG2_OF_NUMBER_OF_RESULTS = 2;
	localparam LAST_RESULT = (1<<LOG2_OF_NUMBER_OF_RESULTS) - 1;
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count [MAX_INDEX:0];
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count_copy [LAST_RESULT:0];
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] sample_counter;
	reg [LAST_RESULT:0] i = 0; // i=result #
	reg [DATA_WIDTH-1:0] j = 0; // j=index of count to compare against
	reg [DATA_WIDTH-1:0] index [LAST_RESULT:0]; // result indices
	reg clear_count_already_found = 0;
	genvar k;
	for (k=0; k<=MAX_INDEX; k=k+1) begin : accumulate
		always @(posedge clock) begin
			if (reset || clear_results) begin
				count[k] <= 0;
			end else begin
				if (max_count_reached) begin
					if (clear_count_already_found) begin
						if (k==index[i]) begin
							count[k] <= 0;
						end
					end
				end else begin
					if (sample) begin
						if (k==data_in) begin
							count[k] <= count[k] + 1'd1;
						end
					end
				end
			end
		end
	end
	always @(posedge clock) begin // look for peaks
		if (reset || clear_results) begin
			sample_counter <= 0;
			max_count_reached <= 0;
			i <= 0;
			j <= 1;
			index[0] <= 0;
			index[1] <= 0;
			index[2] <= 0;
			index[3] <= 0;
			count_copy[0] <= 0;
			count_copy[1] <= 0;
			count_copy[2] <= 0;
			count_copy[3] <= 0;
			clear_count_already_found <= 0;
			result_valid <= 0;
		end else begin
			if (~max_count_reached) begin
				if (sample) begin
					if (sample_counter<NUMBER_OF_SAMPLES_TO_ACQUIRE) begin
						sample_counter <= sample_counter + 1'b1;
					end else begin
						max_count_reached <= 1;
					end
				end
			end else begin
				if (~result_valid) begin
					if (clear_count_already_found) begin
						count_copy[i] <= count[index[i]];
						clear_count_already_found <= 0;
						if (i!=LAST_RESULT) begin
							i <= i + 1'd1;
							j <= 1;
						end else begin
							result_valid <= 1;
						end
					end else begin
						if (count[index[i]]<count[j]) begin
							index[i] <= j;
						end
						if (j!=MAX_INDEX) begin
							j <= j + 1'd1;
						end else begin
							clear_count_already_found <= 1;
						end
					end
				end
			end
		end
	end
	assign result00 = index[0];
	assign result01 = index[1];
	assign result02 = index[2];
	assign result03 = index[3];
	assign count00 = count_copy[0];
	assign count01 = count_copy[1];
	assign count02 = count_copy[2];
	assign count03 = count_copy[3];
endmodule

module histogram_tb;
	localparam DATA_WIDTH = 8;
	localparam LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE = 5;
	wire clock;
	reg reset = 1;
	reg clear_results = 0;
	reg [DATA_WIDTH-1:0] data_in = 0;
	reg sample = 0;
	wire [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count00;
	wire [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count01;
	wire [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count02;
	wire [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count03;
	wire [DATA_WIDTH-1:0] result00;
	wire [DATA_WIDTH-1:0] result01;
	wire [DATA_WIDTH-1:0] result02;
	wire [DATA_WIDTH-1:0] result03;
	wire max_count_reached;
	wire result_valid;
	histogram #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE)) h1n1 (
		.clock(clock), .reset(reset), .clear_results(clear_results), .data_in(data_in), .sample(sample),
		.result00(result00), .result01(result01), .result02(result02), .result03(result03),
		.count00(count00), .count01(count01), .count02(count02), .count03(count03),
		.max_count_reached(max_count_reached), .result_valid(result_valid));
	initial begin
		#100; reset <= 0;
		#40; data_in <= 8'h01; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h02; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h04; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h08; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h20; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h40; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h80; #4; sample <= 1; #4; sample <= 0;
		#40;
		#40; data_in <= 8'h01; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h02; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h04; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h08; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h20; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h40; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h80; #4; sample <= 1; #4; sample <= 0;
		#40;
		#40; data_in <= 8'h08; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h08; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h08; #4; sample <= 1; #4; sample <= 0;
		#40;
		#40; data_in <= 8'h40; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h40; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h40; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h40; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h40; #4; sample <= 1; #4; sample <= 0;
		#40;
		#40; data_in <= 8'h55; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'haa; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h99; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h44; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h11; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h99; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h51; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h38; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 8'h83; #4; sample <= 1; #4; sample <= 0;
		#4200;
		#100; clear_results <= 1; #4; clear_results <= 0;
		#100; $finish;
	end
	clock #(.FREQUENCY_OF_CLOCK_HZ(250000000)) c (.clock(clock));
endmodule

`endif

