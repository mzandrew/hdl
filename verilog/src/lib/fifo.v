// last updated 2021-07-21 by mza

`ifndef FIFO_LIB
`define FIFO_LIB

`include "generic.v"
`include "RAM8.v"

//	fifo_single_clock_using_bram #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_DEPTH(LOG2_OF_DEPTH)) fsc (.clock(clock), .reset(reset),
//		.data_in(data_in), .write_enable(write_enable), .full(full), .almost_full(almost_full), .full_or_almost_full(full_or_almost_full),
//		.data_out(data_out), .read_enable(read_enable), .empty(empty), .almost_empty(almost_empty), .empty_or_almost_empty(empty_or_almost_empty));
module fifo_single_clock_using_bram #(
	parameter DATA_WIDTH = 8,
	parameter LOG2_OF_DEPTH = 4,
	parameter PRIMITIVE_ADDRESS_DEPTH = 14,
	parameter RAM_ADDRESS_DEPTH = PRIMITIVE_ADDRESS_DEPTH - $clog2(DATA_WIDTH),
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
	reg [RAM_ADDRESS_DEPTH-1:0] write_address = 0;
	reg [RAM_ADDRESS_DEPTH-1:0] read_address = 0;
	localparam MIN_COUNT = 1;
	localparam MAX_COUNT = MIN_COUNT + DEPTH;
	reg [LOG2_OF_DEPTH:0] count = MIN_COUNT; // 1 extra bit
	reg [31:0] write_error_count = 0;
	reg [31:0] read_error_count = 0;
	wire [3:0] rwef = {read_enable, write_enable, empty, full};
	wire ram_write_enable = write_enable && ((~full) || (read_enable && full));
	RAM_s6_primitive #(.DATA_WIDTH_A(DATA_WIDTH), .DATA_WIDTH_B(DATA_WIDTH)) mem (.reset(reset),
		.write_clock(clock), .write_address(write_address), .data_in(data_in), .write_enable(ram_write_enable),
		.read_clock(clock), .read_address(read_address), .read_enable(1'b1), .data_out(data_out));
	always @(posedge clock) begin
		if (reset) begin
			write_address <= 0;
			read_address <= 0;
			count <= MIN_COUNT;
			write_error_count <= 0;
			read_error_count <= 0;
		end else begin
			casez (rwef)
				4'b100? : begin read_address <= read_address + 1'd1; count <= count - 1'd1; end
				4'b101? : begin end // no data to read
				4'b01?0 : begin write_address <= write_address + 1'd1; count <= count + 1'd1; end
				4'b01?1 : begin end // no more room
				4'b1100 : begin write_address <= write_address + 1'd1; read_address <= read_address + 1'd1; end
				4'b1110 : begin write_address <= write_address + 1'd1; count <= count + 1'd1; end
				4'b1101 : begin read_address <= read_address + 1'd1; count <= count - 1'd1; end
				default : begin end
			endcase
		end
	end
	assign full  = (count == MAX_COUNT) ? 1'b1 : 1'b0;
	assign empty = (count == MIN_COUNT) ? 1'b1 : 1'b0;
	assign almost_full  = (count == MAX_COUNT-1) ? 1'b1 : 1'b0;
	assign almost_empty = (count == MIN_COUNT+1) ? 1'b1 : 1'b0;
	assign full_or_almost_full   = full  || almost_full;
	assign empty_or_almost_empty = empty || almost_empty;
endmodule

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
	reg [LOG2_OF_DEPTH:0] count = MIN_COUNT; // 1 extra bit
	reg [31:0] write_error_count = 0;
	reg [31:0] read_error_count = 0;
	wire [3:0] rwef = {read_enable, write_enable, empty, full};
	always @(posedge clock) begin
		if (reset) begin
			write_address <= 0;
			read_address <= 0;
			count <= MIN_COUNT;
			write_error_count <= 0;
			read_error_count <= 0;
		end else begin
			casez (rwef)
				4'b100? : begin read_address <= read_address + 1'd1; count <= count - 1'd1; end
				4'b101? : begin end // no data to read
				4'b01?0 : begin mem[write_address] <= data_in; write_address <= write_address + 1'd1; count <= count + 1'd1; end
				4'b01?1 : begin end // no more room
				4'b1100 : begin mem[write_address] <= data_in; write_address <= write_address + 1'd1; read_address <= read_address + 1'd1; end
				4'b1110 : begin mem[write_address] <= data_in; write_address <= write_address + 1'd1; count <= count + 1'd1; end
				4'b1101 : begin read_address <= read_address + 1'd1; count <= count - 1'd1; end
				default : begin end
			endcase
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
	wire full;
	wire empty;
	wire almost_full;
	wire almost_empty;
	wire full_or_almost_full;
	wire empty_or_almost_empty;
	wire [DATA_WIDTH-1:0] data_out;
	reg pre_reset = 1;
	reg reset = 1;
	reg [DATA_WIDTH-1:0] pre_data_in = 0;
	reg [DATA_WIDTH-1:0] data_in = 0;
	reg pre_write_enable = 0;
	reg write_enable = 0;
	reg pre_read_enable = 0;
	reg read_enable = 0;
	if (0) begin
		fifo_single_clock #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_DEPTH(LOG2_OF_DEPTH)) fsc (.clock(clock), .reset(reset),
			.data_in(data_in), .write_enable(write_enable), .full(full), .almost_full(almost_full), .full_or_almost_full(full_or_almost_full),
			.data_out(data_out), .read_enable(read_enable), .empty(empty), .almost_empty(almost_empty), .empty_or_almost_empty(empty_or_almost_empty));
	end else begin
		fifo_single_clock_using_bram #(.DATA_WIDTH(DATA_WIDTH), .LOG2_OF_DEPTH(LOG2_OF_DEPTH)) fsc (.clock(clock), .reset(reset),
			.data_in(data_in), .write_enable(write_enable), .full(full), .almost_full(almost_full), .full_or_almost_full(full_or_almost_full),
			.data_out(data_out), .read_enable(read_enable), .empty(empty), .almost_empty(almost_empty), .empty_or_almost_empty(empty_or_almost_empty));
	end
	integer r;
	integer w;
	initial begin
		#40;
		r = $fopen("fifo-reads", "w");
		w = $fopen("fifo-writes", "w");
		#40;
		pre_reset <= 0;
		// a write until full
		#40; pre_data_in <= 8'd00; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd01; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd02; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd03; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd04; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd05; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd06; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd07; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40;
		#40; pre_data_in <= 8'd08; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd09; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd10; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd11; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd12; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd13; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd14; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd15; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40;
		// and then an extra write while full
		#40; pre_data_in <= 8'd16; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40;
		// should be full now, but then simultaneous read+write
		#40; pre_data_in <= 8'd17; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40;
		// then we read to empty
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40;
		// and one more read while empty
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40;
		// write 4
		#40; pre_data_in <= 8'd18; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd19; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd20; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40; pre_data_in <= 8'd21; pre_write_enable <= 1; #4; pre_write_enable <= 0;
		#40;
		// read 4
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40;
		// simultaneous read+write
		#40; pre_data_in <= 8'd22; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd23; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd24; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd25; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd26; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd27; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd28; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd29; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40;
		#40; pre_data_in <= 8'd31; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd32; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd33; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd34; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd35; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd36; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd37; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd38; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40;
		#40; pre_data_in <= 8'd39; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd40; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd41; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40; pre_data_in <= 8'd42; pre_write_enable <= 1; pre_read_enable <= 1; #4; pre_write_enable <= 0; pre_read_enable <= 0;
		#40;
		// read one more to get it all out
		#40; pre_read_enable <= 1; #4; pre_read_enable <= 0;
		#40;
//		#100; $finish;
		#100; $fclose(r); $fclose(w);
	end
	clock #(.FREQUENCY_OF_CLOCK_HZ(250000000)) c (.clock(clock));
	reg [31:0] write_counter = 0;
	reg [31:0] read_counter = 0;
	localparam CHECK_MEM_DEPTH = 256;
	reg [DATA_WIDTH-1:0] mem [CHECK_MEM_DEPTH-1:0];
	always @(posedge clock) begin
		if (write_enable && ~full) begin
			$display("[%4d] %d (write)", write_counter, data_in);
			$fwrite(w, "%d\n", data_in);
			write_counter <= write_counter + 1'd1;
		end
		if (read_enable && ~empty) begin
			$display("[%4d] %d (read)", read_counter, data_out);
			$fwrite(r, "%d\n", data_out);
			read_counter <= read_counter + 1'd1;
		end
		data_in <= pre_data_in;
		write_enable <= pre_write_enable;
		read_enable <= pre_read_enable;
		reset <= pre_reset;
	end
endmodule

`endif

