`timescale 1ns / 1ps
// written 2020-04-01 by mza
// last updated 2020-04-13 by mza

// 5,120 buckets/revolution * 9 revolutions = 46,080 buckets
// need off-between-on functionality, so double that (=92,160)
// 11,520 bytes of ram (so will fit in a 16k-by-8bit)
module function_generator #(
	parameter DATA_BUS_WIDTH = 8, // should correspond to corresponding oserdes input width
	parameter ADDRESS_BUS_DEPTH = 11,
	parameter NUMBER_OF_CHANNELS = 1
	//parameter CHANNELS_LOG2 = $clog2(NUMBER_OF_CHANNELS),
	//parameter CHANNELS_LOG2 = 3, // hardcoded to a max of 8 channels here
	//parameter CHANNELS_LOG2 = 2
) (
	input clock,
	input reset,
//	input [NUMBER_OF_CHANNELS-1:0] outputs_enabled,
	input [$clog2(NUMBER_OF_CHANNELS)-1:0] channel,
	input [DATA_BUS_WIDTH-1:0] data_in,
	input [ADDRESS_BUS_DEPTH-1:0] write_address,
	input [ADDRESS_BUS_DEPTH-1:0] end_read_address,
	input write_enable,
	output [DATA_BUS_WIDTH-1:0] data_out
//	output [NUMBER_OF_CHANNELS-1:0] outputs
	//output output_0, output_1, output_2, output_3,
	//output output_4, output_5, output_6, output_7
);
	reg [ADDRESS_BUS_DEPTH-1:0] read_address = 0;
	reg [ADDRESS_BUS_DEPTH-1:0] last_read_address = ADDRESS_BUS_DEPTH*{1'b1};
//	reg outputs_enabled = 0;
//	reg [NUMBER_OF_CHANNELS-1:0] potential_outputs = 0;
//	reg [channel][ADDRESS_BUS_DEPTH-1:0]
	genvar ch; // generate
	for (ch=0; ch<NUMBER_OF_CHANNELS; ch=ch+1) begin : chan
		if (ADDRESS_BUS_DEPTH==10) begin
			RAM_s6_1k_8bit mem (.write_clock(clock), .read_clock(clock), .reset(reset), .data_in(data_in), .data_out(data_out), .write_address(write_address), .read_address(read_address), .write_enable(write_enable), .read_enable(1'b1));
		end else if (ADDRESS_BUS_DEPTH==11) begin
			RAM_s6_2k_8bit mem (.write_clock(clock), .read_clock(clock), .reset(reset), .data_in(data_in), .data_out(data_out), .write_address(write_address), .read_address(read_address), .write_enable(write_enable), .read_enable(1'b1));
		end else if (ADDRESS_BUS_DEPTH==14) begin
			RAM_s6_16k_8bit mem (.write_clock(clock), .read_clock(clock), .reset(reset), .data_in(data_in), .data_out(data_out), .write_address(write_address), .read_address(read_address), .write_enable(write_enable), .read_enable(1'b1));
//		end else begin
			// assert
		end
		always @(posedge clock) begin
			if (reset) begin
				read_address <= 0;
//				write_address <= 0;
//				potential_outputs[i] <= 0;
///			end else if (write) begin
//				memory[channel][address] <= data;
			end else begin
				if (read_address==last_read_address) begin
					read_address <= 0;
					last_read_address <= end_read_address - 1'b1;
				end else begin
					read_address <= read_address + 1'b1;
				end
//				if (outputs_enabled[i]) begin
//					potential_outputs[i] <= 1;
//				end
			end
		end
	end // end generate
//	wire [NUMBER_OF_CHANNELS-1:0] outputs;
//	assign outputs = potential_outputs;
//	assign { output_0, output_1, output_2, output_3, output_4, output_5, output_6, output_7 } = outputs;
endmodule

module function_generator_tb;
	parameter DATA_BUS_WIDTH = 8; // should correspond to corresponding oserdes input width
	parameter ADDRESS_BUS_DEPTH = 11;
	parameter NUMBER_OF_CHANNELS = 1;
	parameter ADDRESS_MAX = (2**ADDRESS_BUS_DEPTH)-1;
	reg clock = 0;
	reg reset = 1;
//	reg [NUMBER_OF_CHANNELS-1:0] outputs_enabled = 0;
//	wire outputs;
	reg [DATA_BUS_WIDTH-1:0] data_in = 0;
	reg [ADDRESS_BUS_DEPTH-1:0] write_address = 0;
	reg write_enable = 0;
	wire [DATA_BUS_WIDTH-1:0] data_out;
	function_generator #(
		.DATA_BUS_WIDTH(DATA_BUS_WIDTH),
		.ADDRESS_BUS_DEPTH(ADDRESS_BUS_DEPTH),
		.NUMBER_OF_CHANNELS(NUMBER_OF_CHANNELS)
	) fg (
		.clock(clock),
		.reset(reset),
		.write_address(write_address),
		.data_in(data_in),
		.write_enable(write_enable),
		.data_out(data_out)
//		.outputs_enabled(outputs_enabled),
//		.outputs(outputs)
	);
	reg [ADDRESS_BUS_DEPTH-1:0] ad; // generate
	initial begin
		clock <= 0;
		reset <= 1;
//		outputs_enabled <= 8'b11111111;
		data_in <= 0;
		write_address <= 0;
		write_enable <= 0;
		#8;
		reset <= 0;
		#8;
		for (ad=0; ad<=ADDRESS_MAX; ad=ad+1) begin : ramp
			write_address <= ad;
			if (0) begin
				if (write_address==123) begin
					data_in <= 1;
				end else begin
					data_in <= 0;
				end
			end else begin
				data_in <= ad[7:0];
			end
			#8;
			write_enable <= 1;
			#8;
			write_enable <= 0;
			#8;
		end // end generate
//		outputs_enabled <= 8'b00000000;
//		#500;
//		outputs_enabled <= 8'b00000001;
//		#500;
//		outputs_enabled <= 8'b00000010;
//		#500;
//		outputs_enabled <= 8'b00000011;
//		#500;
//		outputs_enabled <= 8'b00000100;
//		#500;
//		outputs_enabled <= 8'b00000101;
//		#500;
//		outputs_enabled <= 8'b00000110;
//		#500;
//		outputs_enabled <= 8'b00000111;
	end
	always begin
		#4;
		clock = ~clock;
	end
endmodule

