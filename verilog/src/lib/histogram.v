// written 2021-07-14 by mza
// last updated 2021-07-14 by mza

module histogram #(
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
	output reg result_valid = 0
);
	localparam MAX_INDEX = (1<<DATA_WIDTH) - 1;
	localparam NUMBER_OF_SAMPLES_TO_ACQUIRE = (1<<LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE) - 1;
	localparam LOG2_OF_NUMBER_OF_RESULTS = 2;
	localparam LAST_RESULT = (1<<LOG2_OF_NUMBER_OF_RESULTS) - 1;
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count [MAX_INDEX:0];
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] count_copy [LAST_RESULT:0];
	reg [LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE-1:0] sample_counter;
	reg [DATA_WIDTH-1:0] i = 0; // i=result #
	reg [DATA_WIDTH-1:0] j = 0; // j=index of count to compare against
	reg [DATA_WIDTH-1:0] index [LAST_RESULT:0]; // result indices
	reg clear_count_already_found = 0;
	always @(posedge clock) begin
		if (reset || clear_results) begin
			count[0]  <= 0;
			count[1]  <= 0;
			count[2]  <= 0;
			count[3]  <= 0;
			count[4]  <= 0;
			count[5]  <= 0;
			count[6]  <= 0;
			count[7]  <= 0;
			count[8]  <= 0;
			count[9]  <= 0;
			count[10] <= 0;
			count[11] <= 0;
			count[12] <= 0;
			count[13] <= 0;
			count[14] <= 0;
			count[15] <= 0;
			sample_counter <= 0;
			max_count_reached <= 0;
			result_valid <= 0;
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
		end else begin
			if (~max_count_reached) begin
				if (sample) begin
					case (data_in)
						4'h0    : begin count[0]  <=  count[0] + 1'b1; end
						4'h1    : begin count[1]  <=  count[1] + 1'b1; end
						4'h2    : begin count[2]  <=  count[2] + 1'b1; end
						4'h3    : begin count[3]  <=  count[3] + 1'b1; end
						4'h4    : begin count[4]  <=  count[4] + 1'b1; end
						4'h5    : begin count[5]  <=  count[5] + 1'b1; end
						4'h6    : begin count[6]  <=  count[6] + 1'b1; end
						4'h7    : begin count[7]  <=  count[7] + 1'b1; end
						4'h8    : begin count[8]  <=  count[8] + 1'b1; end
						4'h9    : begin count[9]  <=  count[9] + 1'b1; end
						4'ha    : begin count[10] <= count[10] + 1'b1; end
						4'hb    : begin count[11] <= count[11] + 1'b1; end
						4'hc    : begin count[12] <= count[12] + 1'b1; end
						4'hd    : begin count[13] <= count[13] + 1'b1; end
						4'he    : begin count[14] <= count[14] + 1'b1; end
						default : begin count[15] <= count[15] + 1'b1; end
					endcase
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
						count[index[i]] <= 0;
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
	localparam DATA_WIDTH = 4;
	localparam LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE = 4;
	localparam LOG2_OF_NUMBER_OF_RESULTS = 2;
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
	histogram #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE(LOG2_OF_NUMBER_OF_SAMPLES_TO_ACQUIRE),
		.LOG2_OF_NUMBER_OF_RESULTS(LOG2_OF_NUMBER_OF_RESULTS)
		) h1n1 (
		.clock(clock), .reset(reset), .clear_results(clear_results), .data_in(data_in), .sample(sample),
		.result00(result00), .result01(result01), .result02(result02), .result03(result03),
		.count00(count00), .count01(count01), .count02(count02), .count03(count03),
		.max_count_reached(max_count_reached), .result_valid(result_valid));
	initial begin
		#100; reset <= 0;
		#40; data_in <= 4'b0000; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b1110; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b1011; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b0110; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b1011; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b1100; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b1101; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b1111; #4; sample <= 1; #4; sample <= 0;
		#40;
		#40; data_in <= 4'b0110; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b0110; #4; sample <= 1; #4; sample <= 0;
		#40;
		#40; data_in <= 4'b1010; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b1011; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b0101; #4; sample <= 1; #4; sample <= 0;
		#40;
		#40; data_in <= 4'b0001; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b1110; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b0111; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b0011; #4; sample <= 1; #4; sample <= 0;
		#40; data_in <= 4'b0011; #4; sample <= 1; #4; sample <= 0;
		#1000;
		#100; clear_results <= 1; #4; clear_results <= 0;
		#100; $finish;
	end
	clock #(.FREQUENCY_OF_CLOCK_HZ(250000000)) c (.clock(clock));
endmodule

