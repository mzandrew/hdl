// last updated 2021-07-16 by mza

`ifndef FIFO_LIB
`define FIFO_LIB

`include "generic.v"

//	fifo_single_clock #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_DEPTH(LOG2_OF_DEPTH)) fsc (.clock(clock), .reset(reset),
//		.data_in(data_in), .write_enable(write_enable), .full(full), .almost_full(almost_full), .full_or_almost_full(full_or_almost_full),
//		.data_out(data_out), .read_enable(read_enable), .empty(empty), .almost_empty(almost_empty), .empty_or_almost_empty(empty_or_almost_empty));
module fifo_single_clock #(
	parameter DATA_WIDTH = 8,
	parameter LOG2_OF_DEPTH = 4,
	parameter DEPTH = 1<<LOG2_OF_DEPTH
) (
	input clock, reset,
	output almost_full, full, full_or_almost_full,
	input [DATA_WIDTH-1:0] data_in,
	input write_enable,
	output almost_empty, empty, empty_or_almost_empty,
	input read_enable,
	output [DATA_WIDTH-1:0] data_out
);
	reg [LOG2_OF_DEPTH-1:0] write_address = 0;
	reg [LOG2_OF_DEPTH-1:0] read_address = 0;
	reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
	localparam MIN_COUNT = 1;
	localparam MAX_COUNT = MIN_COUNT + DEPTH;
	reg [DEPTH:0] count = MIN_COUNT; // 1 extra bit
	reg [31:0] write_error_count = 0;
	reg [31:0] read_error_count = 0;
	wire [1:0] rw = {read_enable, write_enable};
	always @(posedge clock) begin
		if (reset) begin
			write_address <= 1;
			read_address <= 0;
			count <= MIN_COUNT;
			write_error_count <= 0;
			read_error_count <= 0;
		end else begin
			if (write_enable) begin
				if (~full) begin
					mem[write_address] <= data_in;
					write_address <= write_address + 1'd1;
				end
			end
			if (read_enable) begin
				if (~empty) begin
					read_address <= read_address + 1'd1;
				end
			end
			if (rw==2'b10) begin
				if (~empty) begin
					count <= count - 1'd1;
				end else begin
					read_error_count <= read_error_count + 1'd1;
				end
			end else if (rw==2'b01) begin
				if (~full) begin
					count <= count + 1'd1;
				end else begin
					write_error_count <= write_error_count + 1'd1;
				end
			end else if (rw==2'b11) begin
				if (full) begin
					mem[write_address] <= data_in;
					write_address <= write_address + 1'd1;
				end
				if (empty) begin
					read_address <= read_address + 1'd1;
				end
			end
		end
	end
	assign data_out = mem[read_address];
	assign full  = (count == MAX_COUNT) ? 1'b1 : 1'b0;
	assign empty = (count == MIN_COUNT) ? 1'b1 : 1'b0;
	assign almost_full  = (count == MAX_COUNT-1) ? 1'b1 : 1'b0;
	assign almost_empty = (count == MIN_COUNT+1) ? 1'b1 : 1'b0;
	assign full_or_almost_full   = full  || almost_full;
	assign empty_or_almost_empty = empty || almost_empty;
endmodule

module fifo_single_clock_tb;
	localparam DATA_WIDTH = 8;
	localparam LOG2_OF_DEPTH = 4;
	wire clock;
	reg reset = 1;
	wire full;
	wire empty;
	wire almost_full;
	wire almost_empty;
	wire full_or_almost_full;
	wire empty_or_almost_empty;
	reg [DATA_WIDTH-1:0] data_in = 0;
	wire [DATA_WIDTH-1:0] data_out;
	reg write_enable = 0;
	reg read_enable = 0;
	fifo_single_clock #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_DEPTH(LOG2_OF_DEPTH)) fsc (.clock(clock), .reset(reset),
		.data_in(data_in), .write_enable(write_enable), .full(full), .almost_full(almost_full), .full_or_almost_full(full_or_almost_full),
		.data_out(data_out), .read_enable(read_enable), .empty(empty), .almost_empty(almost_empty), .empty_or_almost_empty(empty_or_almost_empty));
	initial begin
		#40;
		reset <= 0;
		#40; data_in <= 8'h01; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h02; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h03; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h04; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h05; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h06; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h07; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h08; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h09; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h10; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h11; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h12; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h13; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h14; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h15; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h16; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h17; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h18; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40;
		#40; data_in <= 8'ha5; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h5a; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'hf0; write_enable <= 1; #4; write_enable <= 0;
		#40; data_in <= 8'h0f; write_enable <= 1; #4; write_enable <= 0;
		#40;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40; read_enable <= 1; #4; read_enable <= 0;
		#40;
		#40; data_in <= 8'h80; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h81; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h82; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h83; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h84; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h85; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h86; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h87; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h88; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h89; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h8a; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h8b; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h8c; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h8d; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h8e; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h8f; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h90; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h91; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h92; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40; data_in <= 8'h93; write_enable <= 1; read_enable <= 1; #4; write_enable <= 0; read_enable <= 0;
		#40;
//		#100; $finish;
	end
	clock #(.FREQUENCY_OF_CLOCK_HZ(250000000)) c (.clock(clock));
endmodule

`endif

