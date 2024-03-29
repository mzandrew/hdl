// written 2021-07-14 by mza
// last updated 2021-07-23 by mza

`ifndef HISTOGRAM_LIB
`define HISTOGRAM_LIB

`include "RAM8.v"
`include "fifo.v"
`include "generic.v"

// takes 11 us @ 250 MHz in simulation (DATA_WIDTH=8; LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE=5)
// with USE_BLOCK_MEMORY=1, it uses 43% of slices (DATA_WIDTH=8; LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE=16) and compiles quickly
// with USE_BLOCK_MEMORY=0, LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE must be no more than 4 or 5 and it still takes a while to compile...
// takes 16.384 us to capture each burst (filling an 11-bit fifo) @ 125 MHz
// takes ~84 us to add up the hits in each burst
// takes ~8 us to do comparisons and find the top 4 results
// for LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE=24 it takes about 800 ms total
module histogram #(
	parameter DATA_WIDTH = 4,
	parameter LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE = 4,
	parameter TESTBENCH = 0,
	parameter PRELIMINARY_LOG2_OF_NUMBER_OF_TIMES_TO_FILL_FIFO = TESTBENCH ? 2 : LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE + $clog2(DATA_WIDTH) - `LOG2_OF_BASE_BLOCK_MEMORY_SIZE,
	parameter LOG2_OF_NUMBER_OF_TIMES_TO_FILL_FIFO = PRELIMINARY_LOG2_OF_NUMBER_OF_TIMES_TO_FILL_FIFO < 0 ? 0 : PRELIMINARY_LOG2_OF_NUMBER_OF_TIMES_TO_FILL_FIFO,
	parameter LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE_IN_ONE_BURST = LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE - LOG2_OF_NUMBER_OF_TIMES_TO_FILL_FIFO,
	parameter USE_BLOCK_MEMORY = 1
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
	output reg [LOG2_OF_NUMBER_OF_TIMES_TO_FILL_FIFO-1:0] capture_completion = 0,
	output reg partial_count_reached = 0,
	output reg max_count_reached = 0,
	output reg adding_finished = 0,
	output reg result_valid = 0,
	output [31:0] error_count
);
	localparam MAX_INDEX = (1<<DATA_WIDTH) - 1;
	localparam MAXIMUM_SAMPLE_NUMBER = (1<<LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE_IN_ONE_BURST) - 1;
	localparam LOG2_OF_NUMBER_OF_RESULTS = 2;
	localparam LAST_RESULT = (1<<LOG2_OF_NUMBER_OF_RESULTS) - 1;
	//localparam RAM_DATA_WIDTH = LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE < 8 ? 8 : 16;
	localparam RAM_DATA_WIDTH = USE_BLOCK_MEMORY ? 32 : LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE;
	localparam RAM_ADDRESS_DEPTH = USE_BLOCK_MEMORY ? 9 : DATA_WIDTH;
	localparam LAST_FIFO_FILL_NUMBER = (1<<LOG2_OF_NUMBER_OF_TIMES_TO_FILL_FIFO) - 1;
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count_copy [LAST_RESULT:0];
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE_IN_ONE_BURST-1:0] sample_counter = 0;
	reg [LAST_RESULT:0] i = 0; // i=result #
	reg [RAM_DATA_WIDTH-1:0] max_so_far = 0; // max_so_far=one of the counts
	reg [DATA_WIDTH-1:0] j = 0; // j=index of count to compare against
	reg [DATA_WIDTH-1:0] index [LAST_RESULT:0]; // result indices
	reg fifo_read_enable = 0;
	reg [DATA_WIDTH-1:0] previous_data_out_from_fifo = 0;
	wire [DATA_WIDTH-1:0] data_out_from_fifo;
	wire [RAM_ADDRESS_DEPTH-1:0] ram_read_address;
	wire [RAM_ADDRESS_DEPTH-1:0] ram_write_address;
	reg adding_ram_write_enable = 0;
	reg comparing_ram_write_enable = 0;
	wire ram_write_enable;
	wire fifo_full;
	wire should_keep_sampling = sample && (~partial_count_reached);
	wire [RAM_DATA_WIDTH-1:0] ram_data_in;
	wire [RAM_DATA_WIDTH-1:0] data_out_from_ram;
	reg [2:0] adding_state = 0;
	reg [2:0] comparing_state = 0;
	reg [RAM_DATA_WIDTH-1:0] count = 0;
	reg adding_not_comparing = 0;
	reg comparing_write_enable = 0;
	assign ram_read_address   = { {RAM_ADDRESS_DEPTH-DATA_WIDTH{1'b0}}, adding_not_comparing ? data_out_from_fifo : j };
	assign ram_write_address  = { {RAM_ADDRESS_DEPTH-DATA_WIDTH{1'b0}}, adding_not_comparing ? previous_data_out_from_fifo : j };
	assign ram_write_enable = adding_not_comparing ? adding_ram_write_enable : comparing_write_enable;
//	if (8<LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE) begin
	assign ram_data_in      = adding_not_comparing ? count : {RAM_DATA_WIDTH{1'b0}} ;
	fifo_single_clock_using_single_bram #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_DEPTH(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE_IN_ONE_BURST)) fsc (
		.clock(clock), .reset(reset), .error_count(error_count),
		.data_in(data_in), .write_enable(should_keep_sampling), .full(), .almost_full(), .full_or_almost_full(fifo_full),
		.data_out(data_out_from_fifo), .read_enable(fifo_read_enable), .empty(), .almost_empty(), .empty_or_almost_empty());
	if (USE_BLOCK_MEMORY) begin
		RAM_s6_primitive #(.DATA_WIDTH_A(RAM_DATA_WIDTH), .DATA_WIDTH_B(RAM_DATA_WIDTH)) mem (.reset(reset),
			.write_clock(clock), .write_address(ram_write_address), .data_in(ram_data_in), .write_enable(ram_write_enable),
			.read_clock(clock), .read_address(ram_read_address), .read_enable(1'b1), .data_out(data_out_from_ram));
	end else begin
		reg [RAM_ADDRESS_DEPTH-1:0] mem [(1<<RAM_ADDRESS_DEPTH)-1:0];
		always @(posedge clock) begin
			if (reset || clear_results) begin
			end else begin
				if (ram_write_enable) begin
					mem[ram_write_address] <= ram_data_in;
				end
			end
		end
		assign data_out_from_ram = mem[ram_read_address];
	end
	always @(posedge clock) begin
		if (reset || clear_results) begin
			fifo_read_enable <= 0;
			sample_counter <= 0;
			adding_ram_write_enable <= 0;
			adding_state <= 3'd0;
			count <= 0;
			max_count_reached <= 0;
			previous_data_out_from_fifo <= 0;
			adding_finished <= 0;
			partial_count_reached <= 0;
			capture_completion <= 0;
		end else begin
			if (~result_valid) begin
				if (~adding_finished) begin
					if (partial_count_reached) begin // count up hits
						case (adding_state) // read (new data and old count for that new data), modify (increment), write
							3'd0    : begin // wait for other state machine to clear ram
								if (adding_not_comparing) begin
									adding_state <= 3'd1;
								end
							end
							3'd1    : begin
								fifo_read_enable <= 1; // get ready for the next one
								adding_state <= 3'd2;
							end
							3'd2    : begin
								// grab the next new data word from the fifo, which is the read address for the ram
								fifo_read_enable <= 0;
								count <= data_out_from_ram; // fetch the associated count for that data word
								previous_data_out_from_fifo <= data_out_from_fifo; // hold on to the old data word which is the write_address for our result
								adding_state <= 3'd3;
							end
							3'd3    : begin
								count <= count + 3'd1;
								adding_ram_write_enable <= 1; // get ready to store the result
								adding_state <= 3'd4;
							end
							3'd4    : begin
								adding_ram_write_enable <= 0;
								adding_state <= 3'd5;
							end
							default : begin // get ready to do it again or be done adding
								if (sample_counter!=MAXIMUM_SAMPLE_NUMBER) begin
									sample_counter <= sample_counter + 1'd1;
								end else begin
									if (max_count_reached) begin
										adding_finished <= 1;
									end else begin
										partial_count_reached <= 0;
										sample_counter <= 0;
									end
									fifo_read_enable <= 0;
								end
								adding_state <= 3'd1;
							end
						endcase
					end
					if (fifo_full && ~partial_count_reached) begin
						partial_count_reached <= 1;
						if (capture_completion!=LAST_FIFO_FILL_NUMBER) begin
							capture_completion <= capture_completion + 1'd1;
						end else begin
							max_count_reached <= 1;
						end
					end
				end
			end
		end
	end
	always @(posedge clock) begin // look for peaks
		if (reset || clear_results) begin
			i <= 0;
			j <= 0;
			max_so_far <= 0;
			index[0] <= 0;
			index[1] <= 0;
			index[2] <= 0;
			index[3] <= 0;
			count_copy[0] <= 0;
			count_copy[1] <= 0;
			count_copy[2] <= 0;
			count_copy[3] <= 0;
			result_valid <= 0;
			comparing_state <= 0;
			comparing_write_enable <= 0;
			adding_not_comparing <= 0;
		end else begin
			if (~result_valid) begin
				if ((~adding_not_comparing) && adding_state==3'd0) begin
					comparing_write_enable <= 1;
					if (j!=MAX_INDEX) begin
						j <= j + 1'd1;
					end else begin
						j <= 0;
						comparing_write_enable <= 0;
						adding_not_comparing <= 1; // give control of the ram to the adding state machine
					end
				end
				if (max_count_reached && adding_finished) begin
					adding_not_comparing <= 0; // take control of the ram from the adding state machine
					case (comparing_state)
						3'd0    : begin
							comparing_write_enable <= 0;
							comparing_state <= 3'd1;
						end
						3'd1    : begin
							j <= 1'd1; // start the comparison with the next one
							comparing_state <= 3'd2;
						end
						3'd2    : begin
							max_so_far <= data_out_from_ram; // the count for data_in of 0
							comparing_state <= 3'd3;
						end
						3'd3    : begin
							comparing_state <= 3'd4;
						end
						3'd4    : begin
							if (max_so_far<data_out_from_ram) begin // do comparison against the current max
								index[i] <= j; // save the index of the max seen so far
								max_so_far <= data_out_from_ram;
							end
							if (j!=MAX_INDEX) begin
								j <= j + 1'd1;
								comparing_state <= 3'd3;
							end else begin
								j <= index[i]; // get ready to save and then clear the count of the max we just found
								comparing_state <= 3'd5;
							end
						end
						3'd5    : begin
							count_copy[i] <= max_so_far[LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0]; // save the max count that we just found
							comparing_write_enable <= 1; // clear the max count that we just found
							comparing_state <= 3'd6;
						end
						default : begin
							comparing_write_enable <= 0;
							if (i!=LAST_RESULT) begin
								i <= i + 1'd1;
								j <= 0;
							end else begin
								result_valid <= 1;
							end
							comparing_state <= 3'd1;
						end
					endcase
				end
			end
		end
	end
	assign result00 = index[0];
	assign result01 = index[1];
	assign result02 = index[2];
	assign result03 = index[3];
	assign count00 = count_copy[0][LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0];
	assign count01 = count_copy[1][LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0];
	assign count02 = count_copy[2][LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0];
	assign count03 = count_copy[3][LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0];
endmodule

// don't go for more than LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE=5 when using this non-block-ram version (on an lx9 anyway)
// 8 uses up 92% of slice LUTs, fails timing by 78 ns and can't produce a static timing report; seems to work on hardware
// 6 uses up 72% of slice LUTs, fails timing by 18 ns, but shows a lot of count->index[i]/j->index/index->index timing failures
// 5 uses up 56% of slice LUTs, passes timing sometimes (79% occupied slices)
module histogram_original #(
	parameter DATA_WIDTH = 4,
	parameter LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE = 4
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
	output reg adding_finished = 0, // dummy output for compatibility with above module
	output reg result_valid = 0
);
	localparam MAX_INDEX = (1<<DATA_WIDTH) - 1;
	localparam MAXIMUM_SAMPLE_NUMBER = (1<<LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE) - 1;
	localparam LOG2_OF_NUMBER_OF_RESULTS = 2;
	localparam LAST_RESULT = (1<<LOG2_OF_NUMBER_OF_RESULTS) - 1;
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count [MAX_INDEX:0];
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count_copy [LAST_RESULT:0];
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] sample_counter = 0;
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
					if (sample_counter<MAXIMUM_SAMPLE_NUMBER) begin
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
						if (count[index[i]]<count[j]) begin // replacing this comparison with something more like temp<count[j] would probably be significantly more efficient on LUTs
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
	localparam LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE = 4;
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
	wire partial_count_reached;
	wire max_count_reached;
	wire adding_finished;
	wire result_valid;
	wire [31:0] histogram_error_count;
	if (0) begin
		histogram_original #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE)) h1n1 (
			.clock(clock), .reset(reset), .clear_results(clear_results), .data_in(data_in), .sample(sample),
			.result00(result00), .result01(result01), .result02(result02), .result03(result03),
			.count00(count00), .count01(count01), .count02(count02), .count03(count03),
			.max_count_reached(max_count_reached), .adding_finished(adding_finished), .result_valid(result_valid));
	end else begin
		histogram #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE), .USE_BLOCK_MEMORY(0), .TESTBENCH(1)) h1n1 (
			.clock(clock), .reset(reset), .clear_results(clear_results), .data_in(data_in), .sample(sample),
			.result00(result00), .result01(result01), .result02(result02), .result03(result03),
			.count00(count00), .count01(count01), .count02(count02), .count03(count03),
			.partial_count_reached(partial_count_reached), .max_count_reached(max_count_reached), .adding_finished(adding_finished), .result_valid(result_valid), .error_count(histogram_error_count));
	end
	initial begin
		#100; reset <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h15; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h22; #4; sample <= 1; #4; sample <= 0;
		#80; @(negedge partial_count_reached); #80;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h10; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h06; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h06; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h06; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h06; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h06; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h06; #4; sample <= 1; #4; sample <= 0;
		#80; @(negedge partial_count_reached); #80;
		sample <= 1;
		data_in <= 8'h13;
		#(4*13);
		data_in <= 8'h93;
		#(4*3);
		sample <= 0;
		#80; @(negedge partial_count_reached); #80;
		#20; data_in <= 8'h55; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'haa; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h99; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h44; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h11; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h11; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h51; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h83; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h55; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'haa; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h38; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h44; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h51; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h38; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h83; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h55; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'haa; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h99; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h44; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h11; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h99; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h51; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h38; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h83; #4; sample <= 1; #4; sample <= 0;
		#20;
		#20; data_in <= 8'd23; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd29; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd31; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd37; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd41; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd43; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd47; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd53; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd59; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd61; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd67; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd71; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd73; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd79; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd83; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd89; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'd97; #4; sample <= 1; #4; sample <= 0;
		#20;
		#20; data_in <= 8'h84; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h85; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h86; #4; sample <= 1; #4; sample <= 0;
		#20; data_in <= 8'h87; #4; sample <= 1; #4; sample <= 0;
		#20;
		#20; @(posedge result_valid);
		#20;
		#1000; clear_results <= 1; #4; clear_results <= 0;
		#1000;
		#100; $finish;
	end
	clock #(.FREQUENCY_OF_CLOCK_HZ(250000000)) c (.clock(clock));
endmodule

`endif

