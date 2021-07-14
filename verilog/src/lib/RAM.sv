// written 2021-07-13 by mza
// contents taken from RAM8.v and modified for systemverilog
// last updated 2021-07-13 by mza

`ifndef RAM_LIB
`define RAM_LIB

// untested
module RAM_inferred_with_register_outputs #(
	parameter ADDR_WIDTH = 4,
	parameter NUMBER_OF_ADDRESSES = 1<<ADDR_WIDTH,
	parameter DATA_WIDTH = 32
) (
	input reset,
	input [ADDR_WIDTH-1:0] waddr, raddr,
	input [DATA_WIDTH-1:0] din,
	input write_en, wclk, rclk,
	output reg [DATA_WIDTH-1:0] dout = 0,
	output reg [DATA_WIDTH-1:0] mem [NUMBER_OF_ADDRESSES-1:0]
);
	always @(posedge wclk) begin
		if (~reset) begin
			if (write_en) begin
				mem[waddr] <= din;
			end
		end
	end
	always @(posedge rclk) begin
		if (~reset) begin
			dout <= mem[raddr];
		end
	end
endmodule

// untested
// port a takes precedence here
module RAM_inferred_with_register_inputs #(
	parameter ADDR_WIDTH = 4,
	parameter NUMBER_OF_ADDRESSES = 1<<ADDR_WIDTH,
	parameter DATA_WIDTH = 32
) (
	input reset,
	input [ADDR_WIDTH-1:0] waddr, raddr,
	input [DATA_WIDTH-1:0] din,
	input write_en, wclk, rclk,
	output reg [DATA_WIDTH-1:0] dout = 0,
	input [DATA_WIDTH-1:0] mem_in [NUMBER_OF_ADDRESSES-1:0]
);
	reg [DATA_WIDTH-1:0] mem [NUMBER_OF_ADDRESSES-1:0];
	genvar i;
	always @(posedge wclk) begin
		if (~reset) begin
			if (write_en) begin
				mem[waddr] <= din;
			end else begin
				for (i=0; i<NUMBER_OF_ADDRESSES; i=i+1) begin : write_block
					mem[i] <= mem_in[i];
				end
			end
		end
	end
	always @(posedge rclk) begin
		if (~reset) begin
			dout <= mem[raddr];
		end
	end
endmodule

//// https://stackoverflow.com/q/60315588/5728815
//module dp_async_ram (clk, rst, rd0, rd1, wr0, wr1, in1, in0, out1,out0, addr0, addr1);
//  parameter DEPTH = 16;
//  parameter WIDTH = 8;
//  parameter ADDR = 4;
//  input clk, rst;
//  input rd0, rd1;
//  input wr0, wr1;
//  input [WIDTH-1:0] in0, in1;
//  input [ADDR-1:0] addr0, addr1;
//  output [WIDTH-1:0] out0, out1;
//  //Define Memory
//  logic [WIDTH-1:0] mem [0:DEPTH-1];
//  logic [WIDTH-1:0] data0, data1;
//// with modification from https://stackoverflow.com/a/60315691/5728815
//always @ (posedge clk) begin
//    if (wr0 && ~rd0)
//        mem[addr0] <= in0;
//    if (rd0 && ~wr0)
//        data0 <= mem[addr0];
//end
//always @ (posedge clk) begin
//    if (wr1 && ~rd1)
//        mem[addr1] <= in1;
//    if (rd1 && ~wr1)
//        data1 <= mem[addr1];
//end
////Read Logic
//  assign out0 = (rd0 && (!wr0))? data0: {WIDTH{1'bz}}; //High Impedance Mode here
//  assign out1 = (rd0 && (!wr0))? data1: {WIDTH{1'bz}};
//endmodule // dp_async_ram

// altera Recommended HDL Coding Styles
// Example 12-22: SystemVerilog Mixed-Width RAM with Read Width Smaller than Write Width
// module mixed_width_ram // 256x32 write and 1024x8 read
//(
// input [7:0] waddr,
// input [31:0] wdata,
// input we, clk,
// input [9:0] raddr,
// output [7:0] q
//);
// logic [3:0][7:0] ram[0:255];
// always_ff@(posedge clk)
// begin
// if(we) ram[waddr] <= wdata;
// q <= ram[raddr / 4][raddr % 4];
// end
//endmodule : mixed_width_ram

//// system verilog version (from UG901)
//// 3-D Ram Inference Example (Simple Dual port)
//module rams_sdp_3d #(
//	parameter NUM_RAMS = 2,
//	A_WID = 10,
//	D_WID = 32
//) (
//	input clka,
//	input clkb,
//	input [NUM_RAMS-1:0] wea,
//	input [NUM_RAMS-1:0] ena,
//	input [NUM_RAMS-1:0] enb,
//	input [A_WID-1:0] addra [NUM_RAMS-1:0],
//	input [A_WID-1:0] addrb [NUM_RAMS-1:0],
//	input [D_WID-1:0] dina [NUM_RAMS-1:0],
//	output reg [D_WID-1:0] doutb [NUM_RAMS-1:0]
//);
//	reg [D_WID-1:0] mem [NUM_RAMS-1:0][2**A_WID-1:0];
//	genvar i;
//	// PORT_A
//	generate
//	for (i=0; i<NUM_RAMS; i=i+1) begin : port_a_ops
//		always @ (posedge clka) begin
//			if (ena[i]) begin
//				if (wea[i]) begin
//					mem[i][addra[i]] <= dina[i];
//				end
//			end
//		end
//	end
//	endgenerate
//	//PORT_B
//	generate
//	for (i=0; i<NUM_RAMS; i=i+1) begin : port_b_ops
//		always @ (posedge clkb) begin
//			if (enb[i]) begin
//				doutb[i] <= mem[i][addrb[i]];
//			end
//		end
//	end
//	endgenerate
//endmodule

//// system verilog version (from UG901)
//// 3-D Ram Inference Example (True Dual port)
//module rams_tdp_3d #(
//	parameter NUM_RAMS = 2,
//	A_WID = 10,
//	D_WID = 32
//) (
//	input clka,
//	input clkb,
//	input [NUM_RAMS-1:0] wea,
//	input [NUM_RAMS-1:0] web,
//	input [NUM_RAMS-1:0] ena,
//	input [NUM_RAMS-1:0] enb,
//	input [A_WID-1:0] addra [NUM_RAMS-1:0],
//	input [A_WID-1:0] addrb [NUM_RAMS-1:0],
//	input [D_WID-1:0] dina [NUM_RAMS-1:0],
//	input [D_WID-1:0] dinb [NUM_RAMS-1:0],
//	output reg [D_WID-1:0] douta [NUM_RAMS-1:0],
//	output reg [D_WID-1:0] doutb [NUM_RAMS-1:0]
//);
//	reg [D_WID-1:0] mem [NUM_RAMS-1:0][2**A_WID-1:0];
//	genvar i;
//	// PORT_A
//	generate
//	for (i=0; i<NUM_RAMS; i=i+1) begin:port_a_ops
//		always @ (posedge clka) begin
//			if (ena[i]) begin
//				if (wea[i]) begin
//					mem[i][addra[i]] <= dina[i];
//				end
//				douta[i] <= mem[i][addra[i]];
//			end
//		end
//	end
//	endgenerate
//	//PORT_B
//	generate
//	for (i=0; i<NUM_RAMS; i=i+1) begin:port_b_ops
//		always @ (posedge clkb) begin
//			if (enb[i]) begin
//				if (web[i]) begin
//					mem[i][addrb[i]] <= dinb[i];
//				end
//				doutb[i] <= mem[i][addrb[i]];
//			end
//		end
//	end
//	endgenerate
//endmodule

`endif

