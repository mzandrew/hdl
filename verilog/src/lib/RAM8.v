// updated 2020-10-02 by mza
// last updated 2021-07-12 by mza

`ifndef RAM8_LIB
`define RAM8_LIB

`include "generic.v"

// modified from MemoryUsageGuideforiCE40Devices.pdf
module RAM_inferred #(
	parameter addr_width = 9,
	parameter data_width = 8
) (
	input reset,
	input [addr_width-1:0] waddr, raddr,
	input [data_width-1:0] din,
	input write_en, wclk, rclk,
	output reg [data_width-1:0] dout = 0
);
	reg [data_width-1:0] mem [(1<<addr_width)-1:0];
	always @(posedge wclk) begin
		if (reset) begin
//			for (i=0; i<waddr
		end else begin
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
// from the untested systemverilog version
module RAM_inferred_with_register_outputs #(
	parameter ADDR_WIDTH = 4,
	parameter NUMBER_OF_ADDRESSES = 1<<ADDR_WIDTH,
	parameter DATA_WIDTH = 32
) (
	input reset,
	input [ADDR_WIDTH-1:0] waddr_a, raddr_a,
	input [DATA_WIDTH-1:0] din_a,
	input write_en_a, wclk_a, rclk_a,
	output reg [DATA_WIDTH-1:0] dout_a = 0,
	output [DATA_WIDTH-1:0] dout_b_0,
	output [DATA_WIDTH-1:0] dout_b_1,
	output [DATA_WIDTH-1:0] dout_b_2,
	output [DATA_WIDTH-1:0] dout_b_3,
	output [DATA_WIDTH-1:0] dout_b_4,
	output [DATA_WIDTH-1:0] dout_b_5,
	output [DATA_WIDTH-1:0] dout_b_6,
	output [DATA_WIDTH-1:0] dout_b_7,
	output [DATA_WIDTH-1:0] dout_b_8,
	output [DATA_WIDTH-1:0] dout_b_9,
	output [DATA_WIDTH-1:0] dout_b_a,
	output [DATA_WIDTH-1:0] dout_b_b,
	output [DATA_WIDTH-1:0] dout_b_c,
	output [DATA_WIDTH-1:0] dout_b_d,
	output [DATA_WIDTH-1:0] dout_b_e,
	output [DATA_WIDTH-1:0] dout_b_f
);
	reg [DATA_WIDTH-1:0] mem [NUMBER_OF_ADDRESSES-1:0];
	always @(posedge wclk_a) begin
		if (~reset) begin
			if (write_en_a) begin
				mem[waddr_a] <= din_a;
			end
		end
	end
	always @(posedge rclk_a) begin
		if (~reset) begin
			dout_a <= mem[raddr_a];
		end
	end
	assign dout_b_0 = mem[0];
	assign dout_b_1 = mem[1];
	assign dout_b_2 = mem[2];
	assign dout_b_3 = mem[3];
	assign dout_b_4 = mem[4];
	assign dout_b_5 = mem[5];
	assign dout_b_6 = mem[6];
	assign dout_b_7 = mem[7];
	assign dout_b_8 = mem[8];
	assign dout_b_9 = mem[9];
	assign dout_b_a = mem[10];
	assign dout_b_b = mem[11];
	assign dout_b_c = mem[12];
	assign dout_b_d = mem[13];
	assign dout_b_e = mem[14];
	assign dout_b_f = mem[15];
endmodule

// untested
// port a takes precedence here
// from the untested systemverilog version
//	RAM_inferred_with_register_inputs #(.ADDR_WIDTH(4), .DATA_WIDTH(32)) riwri (.reset(),
//		.wclk_a(), .waddr_a(), .din_a(), .write_en_a(),
//		.rclk_a(), .raddr_a(), .dout_a(),
//		.din_b_0(), .din_b_1(), .din_b_2(), .din_b_3(), .din_b_4(), .din_b_5(), .din_b_6(), .din_b_7(),
//		.din_b_8(), .din_b_9(), .din_b_a(), .din_b_b(), .din_b_c(), .din_b_d(), .din_b_e(), .din_b_f());
module RAM_inferred_with_register_inputs #(
	parameter ADDR_WIDTH = 4,
	parameter NUMBER_OF_ADDRESSES = 1<<ADDR_WIDTH,
	parameter DATA_WIDTH = 32
) (
	input reset,
	input [ADDR_WIDTH-1:0] waddr_a, raddr_a,
	input [DATA_WIDTH-1:0] din_a,
	input write_en_a, wclk_a, rclk_a,
	output reg [DATA_WIDTH-1:0] dout_a = 0,
	input [DATA_WIDTH-1:0] din_b_0,
	input [DATA_WIDTH-1:0] din_b_1,
	input [DATA_WIDTH-1:0] din_b_2,
	input [DATA_WIDTH-1:0] din_b_3,
	input [DATA_WIDTH-1:0] din_b_4,
	input [DATA_WIDTH-1:0] din_b_5,
	input [DATA_WIDTH-1:0] din_b_6,
	input [DATA_WIDTH-1:0] din_b_7,
	input [DATA_WIDTH-1:0] din_b_8,
	input [DATA_WIDTH-1:0] din_b_9,
	input [DATA_WIDTH-1:0] din_b_a,
	input [DATA_WIDTH-1:0] din_b_b,
	input [DATA_WIDTH-1:0] din_b_c,
	input [DATA_WIDTH-1:0] din_b_d,
	input [DATA_WIDTH-1:0] din_b_e,
	input [DATA_WIDTH-1:0] din_b_f
);
	reg [DATA_WIDTH-1:0] mem [NUMBER_OF_ADDRESSES-1:0];
	genvar i;
	always @(posedge wclk_a) begin
		if (~reset) begin
			if (write_en_a) begin
				mem[waddr_a] <= din_a;
			end else begin
				mem[0]  <= din_b_0;
				mem[1]  <= din_b_1;
				mem[2]  <= din_b_2;
				mem[3]  <= din_b_3;
				mem[4]  <= din_b_4;
				mem[5]  <= din_b_5;
				mem[6]  <= din_b_6;
				mem[7]  <= din_b_7;
				mem[8]  <= din_b_8;
				mem[9]  <= din_b_9;
				mem[10] <= din_b_a;
				mem[11] <= din_b_b;
				mem[12] <= din_b_c;
				mem[13] <= din_b_d;
				mem[14] <= din_b_e;
				mem[15] <= din_b_f;
			end
		end
	end
	always @(posedge rclk_a) begin
		if (~reset) begin
			dout_a <= mem[raddr_a];
		end
	end
endmodule

module RAM_inferred_with_register_outputs_and_inputs #(
	parameter addr_width = 9,
	parameter data_width = 8
) (
	input reset,
	input [addr_width-1:0] waddr, raddr,
	input [data_width-1:0] din,
	input write_en, wclk, rclk,
	output reg [data_width-1:0] dout = 0,
	output [31:0] register0, register1, register2, register3,
	input [31:0] registerC, registerD, registerE, registerF
);
	reg [data_width-1:0] mem [(1<<addr_width)-1:0];
	always @(posedge wclk) begin
		if (reset) begin
//			for (i=0; i<waddr
		end else begin
			if (write_en) begin
				mem[waddr] <= din;
			end else begin
				mem[4'hc] <= registerC;
				mem[4'hd] <= registerD;
				mem[4'he] <= registerE;
				mem[4'hf] <= registerF;
			end
		end
	end
	always @(posedge rclk) begin
		if (~reset) begin
			dout <= mem[raddr];
		end
	end
	assign register0 = mem[0];
	assign register1 = mem[1];
	assign register2 = mem[2];
	assign register3 = mem[3];
endmodule

module RAM_inferred_with_register_outputs #(
	parameter addr_width = 9,
	parameter data_width = 8
) (
	input reset,
	input [addr_width-1:0] waddr, raddr,
	input [data_width-1:0] din,
	input write_en, wclk, rclk,
	output reg [data_width-1:0] dout = 0,
	output [31:0] register0, register1, register2, register3
);
	reg [data_width-1:0] mem [(1<<addr_width)-1:0];
	always @(posedge wclk) begin
		if (reset) begin
//			for (i=0; i<waddr
		end else begin
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
	assign register0 = mem[0];
	assign register1 = mem[1];
	assign register2 = mem[2];
	assign register3 = mem[3];
endmodule

module RAM_inferred_dual_port_nonworking #(
	parameter ADDR_WIDTH_A = 9,
	parameter ADDR_WIDTH_B = 11,
	parameter DATA_WIDTH_A = 32,
	parameter DATA_WIDTH_B = 8,
	parameter ADDR_WIDTH_DIFF = ADDR_WIDTH_B - ADDR_WIDTH_A,
	parameter GEARBOX_RATIO = 1<<ADDR_WIDTH_DIFF
) (
	input write_en_a, clk_a, clk_b,
	input [ADDR_WIDTH_A-1:0] addr_a,
	input [ADDR_WIDTH_B-1:0] addr_b,
	input [DATA_WIDTH_A-1:0] din_a,
	output reg [DATA_WIDTH_A-1:0] dout_a = 0,
	output [DATA_WIDTH_B-1:0] dout_b
);
	reg [DATA_WIDTH_A-1:0] mem [(1<<ADDR_WIDTH_A)-1:0];
	//wire [ADDR_WIDTH_B-1-ADDR_WIDTH_DIFF:0] addr_b_upper = addr_b[ADDR_WIDTH_B-1:ADDR_WIDTH_DIFF]; // [10:2]
	wire [ADDR_WIDTH_A-1:0] addr_b_upper = addr_b[ADDR_WIDTH_B-1:ADDR_WIDTH_DIFF]; // [10:2]
//	wire [ADDR_WIDTH_DIFF-1:0] addr_b_lower = addr_b[ADDR_WIDTH_DIFF-1:0]; // [1:0]
	reg [DATA_WIDTH_A-1:0] mem_pipeline = 0;
	reg [ADDR_WIDTH_B-1:0] addr_b_middle_pipeline = 0;
	reg [ADDR_WIDTH_B-1:0] addr_b_lower_pipeline = 0;
	reg [DATA_WIDTH_B-1:0] dout_b_pipeline = 0;
	always @(posedge clk_a) begin
		if (write_en_a) begin
			mem[addr_a] <= din_a;
		end
	end
	always @(posedge clk_a) begin
		dout_a <= mem[addr_a];
	end
	always @(posedge clk_b) begin
		// this kind of assignment to a multidimentional entity is disallowed in verilog:
//		mem_pipeline <= { mem_pipeline[1:0], mem[addr_b_upper] };
//		addr_b_middle_pipeline <= { addr_b_middle_pipeline[1:0], DATA_WIDTH_B * addr_b[ADDR_WIDTH_DIFF-1:0] + DATA_WIDTH_B - 1 };
//		addr_b_lower_pipeline  <= { addr_b_lower_pipeline[1:0],  DATA_WIDTH_B * addr_b[ADDR_WIDTH_DIFF-1:0] };
//		dout_b_pipeline <= { dout_b_pipeline[1:0], mem_pipeline[2][addr_b_middle_pipeline[2]:addr_b_lower_pipeline[2]] };
//		dout_b_pipeline <= mem_pipeline[addr_b_middle_pipeline:addr_b_lower_pipeline];
		mem_pipeline <= mem[addr_b_upper];
		addr_b_middle_pipeline <= DATA_WIDTH_B * addr_b[ADDR_WIDTH_DIFF-1:0] + DATA_WIDTH_B - 1;
		addr_b_lower_pipeline  <= DATA_WIDTH_B * addr_b[ADDR_WIDTH_DIFF-1:0];
	end
	assign dout_b = dout_b_pipeline;
endmodule

module RAM_inferred_dual_port_nonworking_tb;
	localparam ADDR_WIDTH_A = 5;
	localparam ADDR_WIDTH_B = 7;
	localparam DATA_WIDTH_A = 32;
	localparam DATA_WIDTH_B = 8;
	reg write_en_a = 0;
	reg clk_a = 0;
	reg clk_b = 0;
	reg [ADDR_WIDTH_A-1:0] addr_a = 0;
	reg [ADDR_WIDTH_B-1:0] addr_b = 0;
	reg [DATA_WIDTH_A-1:0] din_a = 0;
	wire [DATA_WIDTH_A-1:0] dout_a;
	wire [DATA_WIDTH_B-1:0] dout_b;
	RAM_inferred_dual_port #(
		.ADDR_WIDTH_A(ADDR_WIDTH_A),
		.ADDR_WIDTH_B(ADDR_WIDTH_B),
		.DATA_WIDTH_A(DATA_WIDTH_A),
		.DATA_WIDTH_B(DATA_WIDTH_B)
	) myram (
		.write_en_a(write_en_a),
		.clk_a(clk_a),
		.clk_b(clk_b),
		.addr_a(addr_a),
		.addr_b(addr_b),
		.din_a(din_a),
		.dout_a(dout_a),
		.dout_b(dout_b)
	);
	initial begin
		din_a <= 32'h0123;
		addr_a <= 5'b00001;
		addr_b <= 7'b0000010;
		#100;
		write_en_a <= 1;
		#20;
		write_en_a <= 0;
		#100;
		addr_b <= 7'b0000001;
	end
	always begin
		#10;
		clk_a <= ~clk_a;
	end
	always begin
		#10;
		clk_b <= ~clk_b;
	end
endmodule

module RAM_inferred_dual_port #(
	parameter ADDR_WIDTH = 9,
	parameter DATA_WIDTH = 32
) (
	input write_en_a, write_en_b, clk_a, clk_b,
	input [ADDR_WIDTH-1:0] addr_a,
	input [ADDR_WIDTH-1:0] addr_b,
	input [DATA_WIDTH-1:0] din_a,
	input [DATA_WIDTH-1:0] din_b,
	output reg [DATA_WIDTH-1:0] dout_a = 0,
	output reg [DATA_WIDTH-1:0] dout_b = 0
);
	reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
	always @(posedge clk_a) begin
		if (write_en_a) begin
			mem[addr_a] <= din_a;
		end
	end
	always @(posedge clk_b) begin
		if (write_en_b) begin
			mem[addr_b] <= din_b;
		end
	end
	always @(posedge clk_a) begin
		dout_a <= mem[addr_a];
	end
	always @(posedge clk_b) begin
		dout_b <= mem[addr_b];
	end
endmodule

module RAM_inferred_dual_port_tb;
	localparam ADDR_WIDTH = 3;
	localparam DATA_WIDTH = 8;
	reg clk_a = 0;
	reg clk_b = 1;
	reg write_en_a = 0;
	reg write_en_b = 0;
	reg [ADDR_WIDTH-1:0] addr_a = 0;
	reg [ADDR_WIDTH-1:0] addr_b = 0;
	reg [DATA_WIDTH-1:0] din_a = 0;
	reg [DATA_WIDTH-1:0] din_b = 0;
	wire [DATA_WIDTH-1:0] dout_a;
	wire [DATA_WIDTH-1:0] dout_b;
	RAM_inferred_dual_port #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) myram (
		.write_en_a(write_en_a),
		.write_en_b(write_en_b),
		.clk_a(clk_a),
		.clk_b(clk_b),
		.addr_a(addr_a),
		.addr_b(addr_b),
		.din_a(din_a),
		.din_b(din_b),
		.dout_a(dout_a),
		.dout_b(dout_b)
	);
	initial begin
		write_en_a <= 0;
		write_en_b <= 0;
		din_a <= 8'h45;
		din_b <= 8'h67;
		addr_a <= 4'h1;
		addr_b <= 4'h2;
		#100;
		write_en_a <= 1;
		#20;
		write_en_a <= 0;
		#100;
		addr_b <= 4'h1;
		#100;
		write_en_b <= 1;
		#20;
		write_en_b <= 0;
	end
	always begin
		#10;
		clk_a <= ~clk_a;
	end
	always begin
		#10;
		clk_b <= ~clk_b;
	end
endmodule

module RAM_inferred_dual_port_no_writes_on_port_b #(
	parameter ADDR_WIDTH = 9,
	parameter DATA_WIDTH = 32
) (
	input write_en_a, clk_a, clk_b,
	input [ADDR_WIDTH-1:0] addr_a,
	input [ADDR_WIDTH-1:0] addr_b,
	input [DATA_WIDTH-1:0] din_a,
	output reg [DATA_WIDTH-1:0] dout_a = 0,
	output reg [DATA_WIDTH-1:0] dout_b = 0
);
	reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
	always @(posedge clk_a) begin
		if (write_en_a) begin
			mem[addr_a] <= din_a;
		end
	end
	always @(posedge clk_a) begin
		dout_a <= mem[addr_a];
	end
	always @(posedge clk_b) begin
		dout_b <= mem[addr_b];
	end
endmodule

module RAM_inferred_dual_port_gearbox #(
	parameter ADDR_WIDTH_A = 9,
	parameter DATA_WIDTH_A = 32,
	parameter GEARBOX_RATIO = 4,
	parameter LOG2_OF_GEARBOX_RATIO = $clog2(GEARBOX_RATIO),
	parameter ADDR_WIDTH_B = ADDR_WIDTH_A + LOG2_OF_GEARBOX_RATIO,
	parameter DATA_WIDTH_B = DATA_WIDTH_A / GEARBOX_RATIO
) (
	input write_en_a, clk_a, clk_b,
	input [ADDR_WIDTH_A-1:0] addr_a,
	input [ADDR_WIDTH_B-1:0] addr_b,
	input [DATA_WIDTH_A-1:0] din_a,
	output [DATA_WIDTH_A-1:0] dout_a,
	output [DATA_WIDTH_B-1:0] dout_b
);
	wire [DATA_WIDTH_A-1:0] dout_b_full;
	RAM_inferred_dual_port_no_writes_on_port_b #(
		.ADDR_WIDTH(ADDR_WIDTH_A),
		.DATA_WIDTH(DATA_WIDTH_A)
	) myram (
		.write_en_a(write_en_a),
//		.write_en_b(1'b0),
		.clk_a(clk_a),
		.clk_b(clk_b),
		.addr_a(addr_a),
		.addr_b(addr_b[ADDR_WIDTH_B-1:LOG2_OF_GEARBOX_RATIO]),
		.din_a(din_a),
//		.din_b({DATA_WIDTH_A{1'b0}}),
		.dout_a(dout_a),
		.dout_b(dout_b_full)
	);
	if (GEARBOX_RATIO==4) begin
		mux_4to1 #(.WIDTH(DATA_WIDTH_B)) gearbox (
			.sel(addr_b[LOG2_OF_GEARBOX_RATIO-1:0]),
			.in0(dout_b_full[31:24]), .in1(dout_b_full[23:16]), .in2(dout_b_full[15:8]), .in3(dout_b_full[7:0]),
			.out(dout_b)
		);
	end else begin
		mux_2to1 #(.WIDTH(DATA_WIDTH_B)) gearbox (
			.sel(addr_b[LOG2_OF_GEARBOX_RATIO-1:0]),
			.in0(dout_b_full[15:8]), .in1(dout_b_full[7:0]),
			.out(dout_b)
		);
	end
endmodule

module RAM_inferred_dual_port_gearbox_tb;
	localparam ADDR_WIDTH_A = 5;
	localparam ADDR_WIDTH_B = 7;
	localparam DATA_WIDTH_A = 32;
	localparam DATA_WIDTH_B = 8;
	reg write_en_a = 0;
	reg clk_a = 0;
	reg clk_b = 1;
	reg [ADDR_WIDTH_A-1:0] addr_a = 0;
	reg [ADDR_WIDTH_B-1:0] addr_b = 0;
	reg [DATA_WIDTH_A-1:0] din_a = 0;
	wire [DATA_WIDTH_A-1:0] dout_a;
	wire [DATA_WIDTH_B-1:0] dout_b;
	RAM_inferred_dual_port_gearbox #(
		.ADDR_WIDTH_A(ADDR_WIDTH_A),
		.ADDR_WIDTH_B(ADDR_WIDTH_B),
		.DATA_WIDTH_A(DATA_WIDTH_A),
		.DATA_WIDTH_B(DATA_WIDTH_B)
	) myram (
		.write_en_a(write_en_a),
		.clk_a(clk_a),
		.clk_b(clk_b),
		.addr_a(addr_a),
		.addr_b(addr_b),
		.din_a(din_a),
		.dout_a(dout_a),
		.dout_b(dout_b)
	);
	initial begin
		din_a <= 32'h12345678;
		addr_a <= 5'd8;
		addr_b <= { 5'd7, 2'b00 };
		#100;
		write_en_a <= 1;
		#20;
		write_en_a <= 0;
		#40;
		addr_b <= { 5'd8, 2'd0 };
		#40;
		addr_b <= { 5'd8, 2'd1 };
		#40;
		addr_b <= { 5'd8, 2'd2 };
		#40;
		addr_b <= { 5'd8, 2'd3 };
	end
	always begin
		#10;
		clk_a <= ~clk_a;
	end
	always begin
		#10;
		clk_b <= ~clk_b;
	end
endmodule

//(* keep_hierarchy = "yes" *)
//(* BMM_INFO = " " *)
//(* BMM_INFO = "ADDRESS_SPACE map_name RAMB16 [start:end] END_ADDRESS_MAP;" *)

module RAM_s6_16k_8bit #(
	parameter ENDIANNESS = "LITTLE"
) (
	input read_clock,
	input write_clock,
	input reset,
	input [7:0] data_in,
	output [7:0] data_out,
	input [13:0] write_address,
	input [13:0] read_address,
	input write_enable,
	input read_enable
);
	wire [7:0] data_out_array [7:0];
	wire [7:0] write_enable_array;
//	RAM_s6_2k_8bit #(.INIT_FILENAME("bcm_init.mem")) mem00 (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[0]), .read_enable(1'b1));
	genvar i;
	for (i=0; i<8; i=i+1) begin : mem_array
		RAM_s6_2k_8bit #(.ENDIANNESS(ENDIANNESS)) mem (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[i]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[i]), .read_enable(1'b1));
	end
	reg [2:0] buffered_sel_0 = 0;
	wire [7:0] buffered_data_out_0;
	reg [7:0] buffered_data_out_1 = 0;
	always @(posedge read_clock) begin
		buffered_sel_0 <= read_address[13:11];
		buffered_data_out_1 <= buffered_data_out_0;
	end
	assign data_out = buffered_data_out_1;
	mux_8to1 #(.WIDTH(8)) db (
		.in0(data_out_array[0]), .in1(data_out_array[1]), .in2(data_out_array[2]), .in3(data_out_array[3]),
		.in4(data_out_array[4]), .in5(data_out_array[5]), .in6(data_out_array[6]), .in7(data_out_array[7]),
		.sel(buffered_sel_0), .out(buffered_data_out_0));
	demux_1to8 we (
		.in(write_enable), .sel(write_address[13:11]),
		.out0(write_enable_array[0]), .out1(write_enable_array[1]), .out2(write_enable_array[2]), .out3(write_enable_array[3]),
		.out4(write_enable_array[4]), .out5(write_enable_array[5]), .out6(write_enable_array[6]), .out7(write_enable_array[7]));
endmodule

// RAMB16BWER 16k-bit dual-port memory (instantiation example from spartan6_hdl.pdf from xilinx)
module RAM_s6_2k_8bit #(
	parameter INIT_FILENAME = "NONE"
) (
	input read_clock,
	input write_clock,
	input reset,
	input [7:0] data_in,
	output [7:0] data_out,
	input [10:0] write_address,
	input [10:0] read_address,
	input write_enable,
	input read_enable
);
	wire [31:0] data_in_32;
	assign data_in_32 = { 16'h0000, data_in };
	wire [31:0] data_out_32;
	assign data_out = data_out_32[7:0];
	wire [13:0] write_address_14;
	assign write_address_14 = { write_address, 3'b000 };
	wire [13:0] read_address_14;
	assign read_address_14 = { read_address, 3'b000 };
	wire [3:0] write_enable_4;
	assign write_enable_4 = { write_enable, write_enable, write_enable, write_enable };
	RAMB16BWER #(
		// DATA_WIDTH_A/DATA_WIDTH_B: 0, 1, 2, 4, 9, 18, or 36
		.DATA_WIDTH_A(9),
		.DATA_WIDTH_B(9),
		// DOA_REG/DOB_REG: Optional output register (0 or 1)
		.DOA_REG(0),
		.DOB_REG(0),
		// EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		.EN_RSTRAM_A("TRUE"),
		.EN_RSTRAM_B("TRUE"),
		// INIT_A/INIT_B: Initial values on output port
//		.INIT_A(36’h000000000),
//		.INIT_B(36’h000000000),
		// INIT_FILE: Optional file used to specify initial RAM contents
		//.INIT_FILE("NONE"),
		.INIT_FILE(INIT_FILENAME),
		// RSTTYPE: "SYNC" or "ASYNC"
		.RSTTYPE("SYNC"),
		// RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		.RST_PRIORITY_A("CE"),
		.RST_PRIORITY_B("CE"),
		// SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		.SIM_COLLISION_CHECK("ALL"),
		// SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		.SIM_DEVICE("SPARTAN6"),
		// SRVAL_A/SRVAL_B: Set/Reset value for RAM output
//		.SRVAL_A(36’h000000000),
//		.SRVAL_B(36’h000000000),
		// WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		.WRITE_MODE_A("WRITE_FIRST"),
		.WRITE_MODE_B("WRITE_FIRST")
	) RAMB16BWER_inst (
		// Port A Data: 32-bit (each) output: Port A data
		.DOA(), // 32-bit output: A port data output
		.DOPA(), // 4-bit output: A port parity output
		// Port B Data: 32-bit (each) output: Port B data
		.DOB(data_out_32), // 32-bit output: B port data output
		.DOPB(), // 4-bit output: B port parity output
		// Port A Address/Control Signals: 14-bit (each) input: Port A address and control signals
		.ADDRA(write_address_14), // 14-bit input: A port address input
		.CLKA(write_clock), // 1-bit input: A port clock input
		.ENA(1'b1), // 1-bit input: A port enable input
		.REGCEA(1'b0), // 1-bit input: A port register clock enable input
		.RSTA(reset), // 1-bit input: A port register set/reset input
		.WEA(write_enable_4), // 4-bit input: Port A byte-wide write enable input
		// Port A Data: 32-bit (each) input: Port A data
		.DIA(data_in_32), // 32-bit input: A port data input
		.DIPA(4'h0), // 4-bit input: A port parity input
		// Port B Address/Control Signals: 14-bit (each) input: Port B address and control signals
		.ADDRB(read_address_14), // 14-bit input: B port address input
		.CLKB(read_clock), // 1-bit input: B port clock input
		.ENB(read_enable), // 1-bit input: B port enable input
		.REGCEB(1'b0), // 1-bit input: B port register clock enable input
		.RSTB(1'b0), // 1-bit input: B port register set/reset input
		.WEB(4'h0), // 4-bit input: Port B byte-wide write enable input
		// Port B Data: 32-bit (each) input: Port B data
		.DIB(32'd0), // 32-bit input: B port data input
		.DIPB(4'h0) // 4-bit input: B port parity input
	);
endmodule

// RAMB8BWER 8k-bit dual-port memory (instantiation example from spartan6_hdl.pdf from xilinx)
module RAM_s6_1k_8bit (
	input read_clock,
	input write_clock,
	input reset,
	input [7:0] data_in,
	output [7:0] data_out,
	input [9:0] write_address,
	input [9:0] read_address,
	input write_enable,
	input read_enable
);
	wire [15:0] data_in_16;
	assign data_in_16 = { 8'h00, data_in };
	wire [15:0] data_out_16;
	assign data_out = data_out_16[7:0];
	wire [1:0] write_enable_2;
	assign write_enable_2 = { 1'b0, write_enable };
	wire [12:0] write_address_13;
	assign write_address_13 = { write_address, 3'b000 };
	wire [12:0] read_address_13;
	assign read_address_13 = { read_address, 3'b000 };
	RAMB8BWER #(
		.DATA_WIDTH_A(9), // (TDP) 0, 1, 2, 4, 9, 18, or (SDP) 36
		.DATA_WIDTH_B(9), // (TDP) 0, 1, 2, 4, 9, 18, or (SDP) 36
		.DOA_REG(0), // Optional output register on A port (0 or 1)
		.DOB_REG(0), // Optional output register on B port (0 or 1)
		.EN_RSTRAM_A("TRUE"), // Enable/disable A port RST
		.EN_RSTRAM_B("TRUE"), // Enable/disable B port RST
//		.INIT_A(18’h00000), // Initial values on A output port
//		.INIT_B(18’h00000), // Initial values on B output port
		.INIT_FILE("NONE"), // File name of file used to specify initial RAM contents.
		.RAM_MODE("TDP"), // SDP (simple dual-port) or TDP (true dual-port)
		.RSTTYPE("SYNC"), // SYNC or ASYNC reset
		.RST_PRIORITY_A("CE"), // CE or SR priority: ena:rst (TDP mode) and regce:rst (SDP mode)
		.RST_PRIORITY_B("CE"), // CE or SR priority: ena:rst (TDP mode) and regce:rst (SDP mode)
		.SIM_COLLISION_CHECK("ALL"), // Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
//		.SRVAL_A(18’h00000), // Set/Reset value for A port output
//		.SRVAL_B(18’h00000), // Set/Reset value for B port output
		//.WRITE_MODE_A("WRITE_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		.WRITE_MODE_A("READ_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		.WRITE_MODE_B("WRITE_FIRST") // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
	) RAMB8BWER_inst (
		.CLKAWRCLK(write_clock), .CLKBRDCLK(read_clock), // 1 bit input: write clock / read clock
		.ADDRAWRADDR(write_address_13), .ADDRBRDADDR(read_address_13), // 13 bits input: write address / read address
		.ENAWREN(write_enable), .ENBRDEN(read_enable), // 1 bit input: port A enable / port B enable
		.WEAWEL(write_enable_2), .WEBWEU(2'b00), // 2 bits input: byte write enable
		.DIADI(data_in_16), .DIBDI(16'h0000), // 16 bits input: data
		.DOADO(), .DOBDO(data_out_16), // 16 bits output: data
		.DIPADIP(2'b00), .DIPBDIP(2'b00), // 2 bits input: parity
		.DOPADOP(), .DOPBDOP(), // 2 bits output: parity
		.REGCEA(1'b0), .REGCEBREGCE(1'b0), // 1 bit input: register enable
		.RSTA(reset), .RSTBRST(1'b0) // 1 bit input: reset
	);
endmodule

// RAMB16BWER 16k-bit dual-port memory (instantiation example from spartan6_hdl.pdf from xilinx)
module RAM_s6_512_32bit #(
	parameter INIT_FILENAME = "NONE"
) (
	input read_clock,
	input write_clock,
	input reset,
	input [31:0] data_in,
	output [31:0] data_out,
	input [8:0] write_address,
	input [8:0] read_address,
	input write_enable,
	input read_enable
);
	wire [13:0] write_address_14;
	assign write_address_14 = { write_address, 5'b00000 };
	wire [13:0] read_address_14;
	assign read_address_14 = { read_address, 5'b00000 };
	wire [3:0] write_enable_4;
	assign write_enable_4 = { write_enable, write_enable, write_enable, write_enable };
	RAMB16BWER #(
		// DATA_WIDTH_A/DATA_WIDTH_B: 0, 1, 2, 4, 9, 18, or 36
		.DATA_WIDTH_A(36),
		.DATA_WIDTH_B(36),
		// DOA_REG/DOB_REG: Optional output register (0 or 1)
		.DOA_REG(0),
		.DOB_REG(0),
		// EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		.EN_RSTRAM_A("TRUE"),
		.EN_RSTRAM_B("TRUE"),
		// INIT_A/INIT_B: Initial values on output port
//		.INIT_A(36’h000000000),
//		.INIT_B(36’h000000000),
		// INIT_FILE: Optional file used to specify initial RAM contents
		//.INIT_FILE("NONE"),
		.INIT_FILE(INIT_FILENAME),
		// RSTTYPE: "SYNC" or "ASYNC"
		.RSTTYPE("SYNC"),
		// RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		.RST_PRIORITY_A("CE"),
		.RST_PRIORITY_B("CE"),
		// SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		.SIM_COLLISION_CHECK("ALL"),
		// SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		.SIM_DEVICE("SPARTAN6"),
		// SRVAL_A/SRVAL_B: Set/Reset value for RAM output
//		.SRVAL_A(36’h000000000),
//		.SRVAL_B(36’h000000000),
		// WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		.WRITE_MODE_A("WRITE_FIRST"),
		.WRITE_MODE_B("WRITE_FIRST")
	) RAMB16BWER_inst (
		// Port A Data: 32-bit (each) output: Port A data
		.DOA(), // 32-bit output: A port data output
		.DOPA(), // 4-bit output: A port parity output
		// Port B Data: 32-bit (each) output: Port B data
		.DOB(data_out), // 32-bit output: B port data output
		.DOPB(), // 4-bit output: B port parity output
		// Port A Address/Control Signals: 14-bit (each) input: Port A address and control signals
		.ADDRA(write_address_14), // 14-bit input: A port address input
		.CLKA(write_clock), // 1-bit input: A port clock input
		.ENA(1'b1), // 1-bit input: A port enable input
		.REGCEA(1'b0), // 1-bit input: A port register clock enable input
		.RSTA(reset), // 1-bit input: A port register set/reset input
		.WEA(write_enable_4), // 4-bit input: Port A byte-wide write enable input
		// Port A Data: 32-bit (each) input: Port A data
		.DIA(data_in), // 32-bit input: A port data input
		.DIPA(4'h0), // 4-bit input: A port parity input
		// Port B Address/Control Signals: 14-bit (each) input: Port B address and control signals
		.ADDRB(read_address_14), // 14-bit input: B port address input
		.CLKB(read_clock), // 1-bit input: B port clock input
		.ENB(read_enable), // 1-bit input: B port enable input
		.REGCEB(1'b0), // 1-bit input: B port register clock enable input
		.RSTB(1'b0), // 1-bit input: B port register set/reset input
		.WEB(4'h0), // 4-bit input: Port B byte-wide write enable input
		// Port B Data: 32-bit (each) input: Port B data
		.DIB(32'd0), // 32-bit input: B port data input
		.DIPB(4'h0) // 4-bit input: B port parity input
	);
endmodule

//	RAM_s6_16k_32bit_8bit mem (.reset(),
//		.clock_a(), .address_a(), .data_in_a(), .write_enable_a(), .data_out_a(),
//		.clock_b(), .address_b(), .data_out_b());
module RAM_s6_16k_32bit_8bit #(
	parameter ENDIANNESS = "LITTLE"
) (
	input reset,
	input clock_a,
	input [13:0] address_a,
	input [31:0] data_in_a,
	input write_enable_a,
	output [31:0] data_out_a,
	input clock_b,
	input [15:0] address_b,
	output [7:0] data_out_b
);
	wire [31:0] data_out_a_array [31:0];
	wire [7:0] data_out_b_array [31:0];
	wire [31:0] write_enable_a_array;
	genvar i;
	for (i=0; i<32; i=i+1) begin : mem_array
		RAM_s6_512_32bit_8bit #(.ENDIANNESS(ENDIANNESS)) mem (.reset(reset),
			.clock_a(clock_a), .address_a(address_a[8:0]), .data_in_a(data_in_a), .write_enable_a(write_enable_a_array[i]), .data_out_a(data_out_a_array[i]),
			.clock_b(clock_b), .address_b(address_b[10:0]), .data_out_b(data_out_b_array[i]));
	end
	reg [4:0] buffered_sel_a_0 = 0;
	reg [4:0] buffered_sel_b_0 = 0;
	wire [31:0] buffered_data_out_a_0;
	wire [7:0] buffered_data_out_b_0;
	reg [31:0] buffered_data_out_a_1 = 0;
	reg [7:0] buffered_data_out_b_1 = 0;
	always @(posedge clock_a) begin
		buffered_sel_a_0 <= address_a[13:9];
		buffered_data_out_a_1 <= buffered_data_out_a_0;
	end
	always @(posedge clock_b) begin
		buffered_sel_b_0 <= address_b[15:11];
		buffered_data_out_b_1 <= buffered_data_out_b_0;
	end
	assign data_out_a = buffered_data_out_a_1;
	assign data_out_b = buffered_data_out_b_1;
	mux_32to1 #(.WIDTH(32)) db_a (
		.in00(data_out_a_array[00]), .in01(data_out_a_array[01]), .in02(data_out_a_array[02]), .in03(data_out_a_array[03]),
		.in04(data_out_a_array[04]), .in05(data_out_a_array[05]), .in06(data_out_a_array[06]), .in07(data_out_a_array[07]),
		.in08(data_out_a_array[08]), .in09(data_out_a_array[09]), .in10(data_out_a_array[10]), .in11(data_out_a_array[11]),
		.in12(data_out_a_array[12]), .in13(data_out_a_array[13]), .in14(data_out_a_array[14]), .in15(data_out_a_array[15]),
		.in16(data_out_a_array[16]), .in17(data_out_a_array[17]), .in18(data_out_a_array[18]), .in19(data_out_a_array[19]),
		.in20(data_out_a_array[20]), .in21(data_out_a_array[21]), .in22(data_out_a_array[22]), .in23(data_out_a_array[23]),
		.in24(data_out_a_array[24]), .in25(data_out_a_array[25]), .in26(data_out_a_array[26]), .in27(data_out_a_array[27]),
		.in28(data_out_a_array[28]), .in29(data_out_a_array[29]), .in30(data_out_a_array[30]), .in31(data_out_a_array[31]),
		.sel(buffered_sel_a_0), .out(buffered_data_out_a_0));
	mux_32to1 #(.WIDTH(8)) db_b (
		.in00(data_out_b_array[00]), .in01(data_out_b_array[01]), .in02(data_out_b_array[02]), .in03(data_out_b_array[03]),
		.in04(data_out_b_array[04]), .in05(data_out_b_array[05]), .in06(data_out_b_array[06]), .in07(data_out_b_array[07]),
		.in08(data_out_b_array[08]), .in09(data_out_b_array[09]), .in10(data_out_b_array[10]), .in11(data_out_b_array[11]),
		.in12(data_out_b_array[12]), .in13(data_out_b_array[13]), .in14(data_out_b_array[14]), .in15(data_out_b_array[15]),
		.in16(data_out_b_array[16]), .in17(data_out_b_array[17]), .in18(data_out_b_array[18]), .in19(data_out_b_array[19]),
		.in20(data_out_b_array[20]), .in21(data_out_b_array[21]), .in22(data_out_b_array[22]), .in23(data_out_b_array[23]),
		.in24(data_out_b_array[24]), .in25(data_out_b_array[25]), .in26(data_out_b_array[26]), .in27(data_out_b_array[27]),
		.in28(data_out_b_array[28]), .in29(data_out_b_array[29]), .in30(data_out_b_array[30]), .in31(data_out_b_array[31]),
		.sel(buffered_sel_b_0), .out(buffered_data_out_b_0));
	demux_1to32 we (
		.out00(write_enable_a_array[00]), .out01(write_enable_a_array[01]), .out02(write_enable_a_array[02]), .out03(write_enable_a_array[03]),
		.out04(write_enable_a_array[04]), .out05(write_enable_a_array[05]), .out06(write_enable_a_array[06]), .out07(write_enable_a_array[07]),
		.out08(write_enable_a_array[08]), .out09(write_enable_a_array[09]), .out10(write_enable_a_array[10]), .out11(write_enable_a_array[11]),
		.out12(write_enable_a_array[12]), .out13(write_enable_a_array[13]), .out14(write_enable_a_array[14]), .out15(write_enable_a_array[15]),
		.out16(write_enable_a_array[16]), .out17(write_enable_a_array[17]), .out18(write_enable_a_array[18]), .out19(write_enable_a_array[19]),
		.out20(write_enable_a_array[20]), .out21(write_enable_a_array[21]), .out22(write_enable_a_array[22]), .out23(write_enable_a_array[23]),
		.out24(write_enable_a_array[24]), .out25(write_enable_a_array[25]), .out26(write_enable_a_array[26]), .out27(write_enable_a_array[27]),
		.out28(write_enable_a_array[28]), .out29(write_enable_a_array[29]), .out30(write_enable_a_array[30]), .out31(write_enable_a_array[31]),
		.in(write_enable_a), .sel(address_a[13:9]));
endmodule

//	RAM_s6_8k_32bit_8bit mem (.reset(),
//		.clock_a(), .address_a(), .data_in_a(), .write_enable_a(), .data_out_a(),
//		.clock_b(), .address_b(), .data_out_b());
module RAM_s6_8k_32bit_8bit #(
	parameter ENDIANNESS = "LITTLE"
) (
	input reset,
	input clock_a,
	input [12:0] address_a,
	input [31:0] data_in_a,
	input write_enable_a,
	output [31:0] data_out_a,
	input clock_b,
	input [14:0] address_b,
	output [7:0] data_out_b
);
	wire [31:0] data_out_a_array [15:0];
	wire [7:0] data_out_b_array [15:0];
	wire [31:0] write_enable_a_array;
	genvar i;
	for (i=0; i<16; i=i+1) begin : mem_array
		RAM_s6_512_32bit_8bit #(.ENDIANNESS(ENDIANNESS)) mem (.reset(reset),
			.clock_a(clock_a), .address_a(address_a[8:0]), .data_in_a(data_in_a), .write_enable_a(write_enable_a_array[i]), .data_out_a(data_out_a_array[i]),
			.clock_b(clock_b), .address_b(address_b[10:0]), .data_out_b(data_out_b_array[i]));
	end
	reg [3:0] buffered_sel_a_0 = 0;
	reg [3:0] buffered_sel_b_0 = 0;
	wire [31:0] buffered_data_out_a_0;
	wire [7:0] buffered_data_out_b_0;
	reg [31:0] buffered_data_out_a_1 = 0;
	reg [7:0] buffered_data_out_b_1 = 0;
	always @(posedge clock_a) begin
		buffered_sel_a_0 <= address_a[12:9];
		buffered_data_out_a_1 <= buffered_data_out_a_0;
	end
	always @(posedge clock_b) begin
		buffered_sel_b_0 <= address_b[14:11];
		buffered_data_out_b_1 <= buffered_data_out_b_0;
	end
	assign data_out_a = buffered_data_out_a_1;
	assign data_out_b = buffered_data_out_b_1;
	mux_16to1 #(.WIDTH(32)) db_a (
		.in00(data_out_a_array[00]), .in01(data_out_a_array[01]), .in02(data_out_a_array[02]), .in03(data_out_a_array[03]),
		.in04(data_out_a_array[04]), .in05(data_out_a_array[05]), .in06(data_out_a_array[06]), .in07(data_out_a_array[07]),
		.in08(data_out_a_array[08]), .in09(data_out_a_array[09]), .in10(data_out_a_array[10]), .in11(data_out_a_array[11]),
		.in12(data_out_a_array[12]), .in13(data_out_a_array[13]), .in14(data_out_a_array[14]), .in15(data_out_a_array[15]),
		.sel(buffered_sel_a_0), .out(buffered_data_out_a_0));
	mux_16to1 #(.WIDTH(8)) db_b (
		.in00(data_out_b_array[00]), .in01(data_out_b_array[01]), .in02(data_out_b_array[02]), .in03(data_out_b_array[03]),
		.in04(data_out_b_array[04]), .in05(data_out_b_array[05]), .in06(data_out_b_array[06]), .in07(data_out_b_array[07]),
		.in08(data_out_b_array[08]), .in09(data_out_b_array[09]), .in10(data_out_b_array[10]), .in11(data_out_b_array[11]),
		.in12(data_out_b_array[12]), .in13(data_out_b_array[13]), .in14(data_out_b_array[14]), .in15(data_out_b_array[15]),
		.sel(buffered_sel_b_0), .out(buffered_data_out_b_0));
	demux_1to16 we (
		.out00(write_enable_a_array[00]), .out01(write_enable_a_array[01]), .out02(write_enable_a_array[02]), .out03(write_enable_a_array[03]),
		.out04(write_enable_a_array[04]), .out05(write_enable_a_array[05]), .out06(write_enable_a_array[06]), .out07(write_enable_a_array[07]),
		.out08(write_enable_a_array[08]), .out09(write_enable_a_array[09]), .out10(write_enable_a_array[10]), .out11(write_enable_a_array[11]),
		.out12(write_enable_a_array[12]), .out13(write_enable_a_array[13]), .out14(write_enable_a_array[14]), .out15(write_enable_a_array[15]),
		.in(write_enable_a), .sel(address_a[12:9]));
endmodule

//	RAM_s6_4k_32bit_8bit mem (.reset(),
//		.clock_a(), .address_a(), .data_in_a(), .write_enable_a(), .data_out_a(),
//		.clock_b(), .address_b(), .data_out_b());
module RAM_s6_4k_32bit_8bit #(
	parameter ENDIANNESS = "LITTLE"
) (
	input reset,
	input clock_a,
	input [11:0] address_a,
	input [31:0] data_in_a,
	input write_enable_a,
	output [31:0] data_out_a,
	input clock_b,
	input [13:0] address_b,
	output [7:0] data_out_b
);
	wire [31:0] data_out_a_array [7:0];
	wire [7:0] data_out_b_array [7:0];
	wire [7:0] write_enable_a_array;
	genvar i;
	for (i=0; i<8; i=i+1) begin : mem_array
//		RAM_s6_2k_8bit mem (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[i]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[i]), .read_enable(1'b1));
		RAM_s6_512_32bit_8bit #(.ENDIANNESS(ENDIANNESS)) mem (.reset(reset),
			.clock_a(clock_a), .address_a(address_a[8:0]), .data_in_a(data_in_a), .write_enable_a(write_enable_a_array[i]), .data_out_a(data_out_a_array[i]),
			.clock_b(clock_b), .address_b(address_b[10:0]), .data_out_b(data_out_b_array[i]));
	end
	reg [2:0] buffered_sel_a_0 = 0;
	reg [2:0] buffered_sel_b_0 = 0;
	wire [31:0] buffered_data_out_a_0;
	wire [7:0] buffered_data_out_b_0;
	reg [31:0] buffered_data_out_a_1 = 0;
	reg [7:0] buffered_data_out_b_1 = 0;
	always @(posedge clock_a) begin
		buffered_sel_a_0 <= address_a[11:9];
		buffered_data_out_a_1 <= buffered_data_out_a_0;
	end
	always @(posedge clock_b) begin
		buffered_sel_b_0 <= address_b[13:11];
		buffered_data_out_b_1 <= buffered_data_out_b_0;
	end
	assign data_out_a = buffered_data_out_a_1;
	assign data_out_b = buffered_data_out_b_1;
	mux_8to1 #(.WIDTH(32)) db_a (
		.in0(data_out_a_array[0]), .in1(data_out_a_array[1]), .in2(data_out_a_array[2]), .in3(data_out_a_array[3]),
		.in4(data_out_a_array[4]), .in5(data_out_a_array[5]), .in6(data_out_a_array[6]), .in7(data_out_a_array[7]),
		.sel(buffered_sel_a_0), .out(buffered_data_out_a_0));
	mux_8to1 #(.WIDTH(8)) db_b (
		.in0(data_out_b_array[0]), .in1(data_out_b_array[1]), .in2(data_out_b_array[2]), .in3(data_out_b_array[3]),
		.in4(data_out_b_array[4]), .in5(data_out_b_array[5]), .in6(data_out_b_array[6]), .in7(data_out_b_array[7]),
		.sel(buffered_sel_b_0), .out(buffered_data_out_b_0));
	demux_1to8 we (
		.in(write_enable_a), .sel(address_a[11:9]),
		.out0(write_enable_a_array[0]), .out1(write_enable_a_array[1]), .out2(write_enable_a_array[2]), .out3(write_enable_a_array[3]),
		.out4(write_enable_a_array[4]), .out5(write_enable_a_array[5]), .out6(write_enable_a_array[6]), .out7(write_enable_a_array[7]));
endmodule

//	RAM_s6_8k_16bit_8bit mem (.reset(),
//		.clock_a(), .address_a(), .data_in_a(), .write_enable_a(), .data_out_a(),
//		.clock_b(), .address_b(), .data_out_b());
module RAM_s6_8k_16bit_32bit #(
	parameter ENDIANNESS = "LITTLE"
) (
	input reset,
	input clock_a,
	input [12:0] address_a,
	input [15:0] data_in_a,
	input write_enable_a,
	output [15:0] data_out_a,
	input clock_b,
	input [11:0] address_b,
	output [31:0] data_out_b
);
	wire [15:0] data_out_a_array [7:0];
	wire [31:0] data_out_b_array [7:0];
	wire [7:0] write_enable_a_array;
	genvar i;
	for (i=0; i<8; i=i+1) begin : mem_array
		RAM_s6_1k_16bit_32bit #(.ENDIANNESS(ENDIANNESS)) mem (.reset(reset),
			.clock_a(clock_a), .address_a(address_a[9:0]), .data_in_a(data_in_a), .write_enable_a(write_enable_a_array[i]), .data_out_a(data_out_a_array[i]),
			.clock_b(clock_b), .address_b(address_b[8:0]), .data_out_b(data_out_b_array[i]));
	end
	reg [2:0] buffered_sel_a_0 = 0;
	reg [2:0] buffered_sel_b_0 = 0;
	wire [15:0] buffered_data_out_a_0;
	wire [31:0] buffered_data_out_b_0;
	reg [15:0] buffered_data_out_a_1 = 0;
	reg [31:0] buffered_data_out_b_1 = 0;
	always @(posedge clock_a) begin
		buffered_sel_a_0 <= address_a[12:10];
		buffered_data_out_a_1 <= buffered_data_out_a_0;
	end
	always @(posedge clock_b) begin
		buffered_sel_b_0 <= address_b[11:9];
		buffered_data_out_b_1 <= buffered_data_out_b_0;
	end
	assign data_out_a = buffered_data_out_a_1;
	assign data_out_b = buffered_data_out_b_1;
	mux_8to1 #(.WIDTH(16)) db_a (
		.in0(data_out_a_array[0]), .in1(data_out_a_array[1]), .in2(data_out_a_array[2]), .in3(data_out_a_array[3]),
		.in4(data_out_a_array[4]), .in5(data_out_a_array[5]), .in6(data_out_a_array[6]), .in7(data_out_a_array[7]),
		.sel(buffered_sel_a_0), .out(buffered_data_out_a_0));
	mux_8to1 #(.WIDTH(32)) db_b (
		.in0(data_out_b_array[0]), .in1(data_out_b_array[1]), .in2(data_out_b_array[2]), .in3(data_out_b_array[3]),
		.in4(data_out_b_array[4]), .in5(data_out_b_array[5]), .in6(data_out_b_array[6]), .in7(data_out_b_array[7]),
		.sel(buffered_sel_b_0), .out(buffered_data_out_b_0));
	demux_1to8 we (
		.in(write_enable_a), .sel(address_a[12:10]),
		.out0(write_enable_a_array[0]), .out1(write_enable_a_array[1]), .out2(write_enable_a_array[2]), .out3(write_enable_a_array[3]),
		.out4(write_enable_a_array[4]), .out5(write_enable_a_array[5]), .out6(write_enable_a_array[6]), .out7(write_enable_a_array[7]));
endmodule

//	RAM_s6_8k_16bit_8bit mem (.reset(),
//		.clock_a(), .address_a(), .data_in_a(), .write_enable_a(), .data_out_a(),
//		.clock_b(), .address_b(), .data_out_b());
module RAM_s6_8k_16bit_8bit #(
	parameter ENDIANNESS = "LITTLE"
) (
	input reset,
	input clock_a,
	input [12:0] address_a,
	input [15:0] data_in_a,
	input write_enable_a,
	output [15:0] data_out_a,
	input clock_b,
	input [13:0] address_b,
	output [7:0] data_out_b
);
	wire [15:0] data_out_a_array [7:0];
	wire [7:0] data_out_b_array [7:0];
	wire [7:0] write_enable_a_array;
	genvar i;
	for (i=0; i<8; i=i+1) begin : mem_array
		RAM_s6_1k_16bit_8bit #(.ENDIANNESS(ENDIANNESS)) mem (.reset(reset),
			.clock_a(clock_a), .address_a(address_a[9:0]), .data_in_a(data_in_a), .write_enable_a(write_enable_a_array[i]), .data_out_a(data_out_a_array[i]),
			.clock_b(clock_b), .address_b(address_b[10:0]), .data_out_b(data_out_b_array[i]));
	end
	reg [2:0] buffered_sel_a_0 = 0;
	reg [2:0] buffered_sel_b_0 = 0;
	wire [15:0] buffered_data_out_a_0;
	wire [7:0] buffered_data_out_b_0;
	reg [15:0] buffered_data_out_a_1 = 0;
	reg [7:0] buffered_data_out_b_1 = 0;
	always @(posedge clock_a) begin
		buffered_sel_a_0 <= address_a[12:10];
		buffered_data_out_a_1 <= buffered_data_out_a_0;
	end
	always @(posedge clock_b) begin
		buffered_sel_b_0 <= address_b[13:11];
		buffered_data_out_b_1 <= buffered_data_out_b_0;
	end
	assign data_out_a = buffered_data_out_a_1;
	assign data_out_b = buffered_data_out_b_1;
	mux_8to1 #(.WIDTH(16)) db_a (
		.in0(data_out_a_array[0]), .in1(data_out_a_array[1]), .in2(data_out_a_array[2]), .in3(data_out_a_array[3]),
		.in4(data_out_a_array[4]), .in5(data_out_a_array[5]), .in6(data_out_a_array[6]), .in7(data_out_a_array[7]),
		.sel(buffered_sel_a_0), .out(buffered_data_out_a_0));
	mux_8to1 #(.WIDTH(8)) db_b (
		.in0(data_out_b_array[0]), .in1(data_out_b_array[1]), .in2(data_out_b_array[2]), .in3(data_out_b_array[3]),
		.in4(data_out_b_array[4]), .in5(data_out_b_array[5]), .in6(data_out_b_array[6]), .in7(data_out_b_array[7]),
		.sel(buffered_sel_b_0), .out(buffered_data_out_b_0));
	demux_1to8 we (
		.in(write_enable_a), .sel(address_a[12:10]),
		.out0(write_enable_a_array[0]), .out1(write_enable_a_array[1]), .out2(write_enable_a_array[2]), .out3(write_enable_a_array[3]),
		.out4(write_enable_a_array[4]), .out5(write_enable_a_array[5]), .out6(write_enable_a_array[6]), .out7(write_enable_a_array[7]));
endmodule

//RAM_s6_512_32bit_8bit mem (.reset(),
//	.clock_a(), .address_a(), .data_in_a(), .write_enable_a(), .data_out_a(),
//	.clock_b(), .address_b(), .data_out_b());
// RAMB16BWER 16k-bit dual-port memory (instantiation example from spartan6_hdl.pdf from xilinx)
module RAM_s6_512_32bit_8bit #(
	parameter INIT_FILENAME = "NONE",
	parameter ENDIANNESS = "LITTLE"
) (
	input reset,
	input clock_a,
	input [8:0] address_a,
	input [31:0] data_in_a,
	input write_enable_a,
	output [31:0] data_out_a,
	input clock_b,
	input [10:0] address_b,
	output [7:0] data_out_b
);
	wire [13:0] address_a_14;
	assign address_a_14 = { address_a, 5'b00000 };
	wire [13:0] address_b_14;
	if (ENDIANNESS=="LITTLE") begin
		assign address_b_14 = { address_b, 3'b000 };
	end else begin
		assign address_b_14 = { address_b[10:2], 2'd3-address_b[1:0], 3'b000 };
	end
	wire [3:0] write_enable_4;
	assign write_enable_4 = { write_enable_a, write_enable_a, write_enable_a, write_enable_a };
	wire [31:0] data_out_b_32;
	assign data_out_b = data_out_b_32[7:0];
	RAMB16BWER #(
		// DATA_WIDTH_A/DATA_WIDTH_B: 0, 1, 2, 4, 9, 18, or 36
		.DATA_WIDTH_A(36),
		.DATA_WIDTH_B(9),
		// DOA_REG/DOB_REG: Optional output register (0 or 1)
		.DOA_REG(0),
		.DOB_REG(0),
		// EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		.EN_RSTRAM_A("TRUE"),
		.EN_RSTRAM_B("TRUE"),
		// INIT_A/INIT_B: Initial values on output port
//		.INIT_A(36’h000000000),
//		.INIT_B(36’h000000000),
		// INIT_FILE: Optional file used to specify initial RAM contents
		//.INIT_FILE("NONE"),
		.INIT_FILE(INIT_FILENAME),
		// RSTTYPE: "SYNC" or "ASYNC"
		.RSTTYPE("SYNC"),
		// RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		.RST_PRIORITY_A("CE"),
		.RST_PRIORITY_B("CE"),
		// SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		.SIM_COLLISION_CHECK("ALL"),
		// SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		.SIM_DEVICE("SPARTAN6"),
		// SRVAL_A/SRVAL_B: Set/Reset value for RAM output
//		.SRVAL_A(36’h000000000),
//		.SRVAL_B(36’h000000000),
		// WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		.WRITE_MODE_A("WRITE_FIRST"),
		.WRITE_MODE_B("WRITE_FIRST")
	) RAMB16BWER_inst (
		// Port A Data: 32-bit (each) output: Port A data
		.DOA(data_out_a), // 32-bit output: A port data output
		.DOPA(), // 4-bit output: A port parity output
		// Port B Data: 32-bit (each) output: Port B data
		.DOB(data_out_b_32), // 32-bit output: B port data output
		.DOPB(), // 4-bit output: B port parity output
		// Port A Address/Control Signals: 14-bit (each) input: Port A address and control signals
		.ADDRA(address_a_14), // 14-bit input: A port address input
		.CLKA(clock_a), // 1-bit input: A port clock input
		.ENA(1'b1), // 1-bit input: A port enable input
		.REGCEA(1'b0), // 1-bit input: A port register clock enable input
		.RSTA(reset), // 1-bit input: A port register set/reset input
		.WEA(write_enable_4), // 4-bit input: Port A byte-wide write enable input
		// Port A Data: 32-bit (each) input: Port A data
		.DIA(data_in_a), // 32-bit input: A port data input
		.DIPA(4'h0), // 4-bit input: A port parity input
		// Port B Address/Control Signals: 14-bit (each) input: Port B address and control signals
		.ADDRB(address_b_14), // 14-bit input: B port address input
		.CLKB(clock_b), // 1-bit input: B port clock input
		.ENB(1'b1), // 1-bit input: B port enable input
		.REGCEB(1'b0), // 1-bit input: B port register clock enable input
		.RSTB(1'b0), // 1-bit input: B port register set/reset input
		.WEB(4'h0), // 4-bit input: Port B byte-wide write enable input
		// Port B Data: 32-bit (each) input: Port B data
		.DIB(32'd0), // 32-bit input: B port data input
		.DIPB(4'h0) // 4-bit input: B port parity input
	);
endmodule

//RAM_s6_1k_16bit_32bit mem (.reset(),
//	.clock_a(), .address_a(), .data_in_a(), .write_enable_a(), .data_out_a(),
//	.clock_b(), .address_b(), .data_out_b());
// RAMB16BWER 16k-bit dual-port memory (instantiation example from spartan6_hdl.pdf from xilinx)
module RAM_s6_1k_16bit_32bit #(
	parameter INIT_FILENAME = "NONE",
	parameter ENDIANNESS = "LITTLE"
) (
	input reset,
	input clock_a,
	input [9:0] address_a,
	input [15:0] data_in_a,
	input write_enable_a,
	output [15:0] data_out_a,
	input clock_b,
	input [8:0] address_b,
	output [31:0] data_out_b
);
	wire [13:0] address_a_14;
	assign address_a_14 = { address_a, 4'b0000 };
	wire [13:0] address_b_14;
	if (ENDIANNESS=="LITTLE") begin
		assign address_b_14 = { address_b, 5'b00000 };
	end else begin
		assign address_b_14 = { address_b[8:1], 1'd1-address_b[0], 5'b00000 };
	end
	wire [3:0] write_enable_4;
	assign write_enable_4 = { write_enable_a, write_enable_a, write_enable_a, write_enable_a };
	wire [31:0] data_in_a_32;
	assign data_in_a_32 = { 16'd0, data_in_a };
	wire [31:0] data_out_a_32;
	assign data_out_a = data_out_a_32[15:0];
	wire [31:0] data_out_b_32;
	assign data_out_b = data_out_b_32;
	RAMB16BWER #(
		// DATA_WIDTH_A/DATA_WIDTH_B: 0, 1, 2, 4, 9, 18, or 36
		.DATA_WIDTH_A(18),
		.DATA_WIDTH_B(36),
		// DOA_REG/DOB_REG: Optional output register (0 or 1)
		.DOA_REG(0),
		.DOB_REG(0),
		// EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		.EN_RSTRAM_A("TRUE"),
		.EN_RSTRAM_B("TRUE"),
		// INIT_A/INIT_B: Initial values on output port
//		.INIT_A(36’h000000000),
//		.INIT_B(36’h000000000),
		// INIT_FILE: Optional file used to specify initial RAM contents
		//.INIT_FILE("NONE"),
		.INIT_FILE(INIT_FILENAME),
		// RSTTYPE: "SYNC" or "ASYNC"
		.RSTTYPE("SYNC"),
		// RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		.RST_PRIORITY_A("CE"),
		.RST_PRIORITY_B("CE"),
		// SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		.SIM_COLLISION_CHECK("ALL"),
		// SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		.SIM_DEVICE("SPARTAN6"),
		// SRVAL_A/SRVAL_B: Set/Reset value for RAM output
//		.SRVAL_A(36’h000000000),
//		.SRVAL_B(36’h000000000),
		// WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		.WRITE_MODE_A("WRITE_FIRST"),
		.WRITE_MODE_B("WRITE_FIRST")
	) RAMB16BWER_inst (
		// Port A Data: 32-bit (each) output: Port A data
		.DOA(data_out_a_32), // 32-bit output: A port data output
		.DOPA(), // 4-bit output: A port parity output
		// Port B Data: 32-bit (each) output: Port B data
		.DOB(data_out_b_32), // 32-bit output: B port data output
		.DOPB(), // 4-bit output: B port parity output
		// Port A Address/Control Signals: 14-bit (each) input: Port A address and control signals
		.ADDRA(address_a_14), // 14-bit input: A port address input
		.CLKA(clock_a), // 1-bit input: A port clock input
		.ENA(1'b1), // 1-bit input: A port enable input
		.REGCEA(1'b0), // 1-bit input: A port register clock enable input
		.RSTA(reset), // 1-bit input: A port register set/reset input
		.WEA(write_enable_4), // 4-bit input: Port A byte-wide write enable input
		// Port A Data: 32-bit (each) input: Port A data
		.DIA(data_in_a_32), // 32-bit input: A port data input
		.DIPA(4'h0), // 4-bit input: A port parity input
		// Port B Address/Control Signals: 14-bit (each) input: Port B address and control signals
		.ADDRB(address_b_14), // 14-bit input: B port address input
		.CLKB(clock_b), // 1-bit input: B port clock input
		.ENB(1'b1), // 1-bit input: B port enable input
		.REGCEB(1'b0), // 1-bit input: B port register clock enable input
		.RSTB(1'b0), // 1-bit input: B port register set/reset input
		.WEB(4'h0), // 4-bit input: Port B byte-wide write enable input
		// Port B Data: 32-bit (each) input: Port B data
		.DIB(32'd0), // 32-bit input: B port data input
		.DIPB(4'h0) // 4-bit input: B port parity input
	);
endmodule

//RAM_s6_1k_16bit_8bit mem (.reset(),
//	.clock_a(), .address_a(), .data_in_a(), .write_enable_a(), .data_out_a(),
//	.clock_b(), .address_b(), .data_out_b());
// RAMB16BWER 16k-bit dual-port memory (instantiation example from spartan6_hdl.pdf from xilinx)
module RAM_s6_1k_16bit_8bit #(
	parameter INIT_FILENAME = "NONE",
	parameter ENDIANNESS = "LITTLE"
) (
	input reset,
	input clock_a,
	input [9:0] address_a,
	input [15:0] data_in_a,
	input write_enable_a,
	output [15:0] data_out_a,
	input clock_b,
	input [10:0] address_b,
	output [7:0] data_out_b
);
	wire [13:0] address_a_14;
	assign address_a_14 = { address_a, 4'b0000 };
	wire [13:0] address_b_14;
	if (ENDIANNESS=="LITTLE") begin
		assign address_b_14 = { address_b, 3'b000 };
	end else begin
		assign address_b_14 = { address_b[10:1], 1'd1-address_b[0], 3'b000 };
	end
	wire [3:0] write_enable_4;
	assign write_enable_4 = { write_enable_a, write_enable_a, write_enable_a, write_enable_a };
	wire [31:0] data_in_a_32;
	assign data_in_a_32 = { 16'd0, data_in_a };
	wire [31:0] data_out_a_32;
	assign data_out_a = data_out_a_32[15:0];
	wire [31:0] data_out_b_32;
	assign data_out_b = data_out_b_32[7:0];
	RAMB16BWER #(
		// DATA_WIDTH_A/DATA_WIDTH_B: 0, 1, 2, 4, 9, 18, or 36
		.DATA_WIDTH_A(18),
		.DATA_WIDTH_B(9),
		// DOA_REG/DOB_REG: Optional output register (0 or 1)
		.DOA_REG(0),
		.DOB_REG(0),
		// EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		.EN_RSTRAM_A("TRUE"),
		.EN_RSTRAM_B("TRUE"),
		// INIT_A/INIT_B: Initial values on output port
//		.INIT_A(36’h000000000),
//		.INIT_B(36’h000000000),
		// INIT_FILE: Optional file used to specify initial RAM contents
		//.INIT_FILE("NONE"),
		.INIT_FILE(INIT_FILENAME),
		// RSTTYPE: "SYNC" or "ASYNC"
		.RSTTYPE("SYNC"),
		// RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		.RST_PRIORITY_A("CE"),
		.RST_PRIORITY_B("CE"),
		// SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		.SIM_COLLISION_CHECK("ALL"),
		// SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		.SIM_DEVICE("SPARTAN6"),
		// SRVAL_A/SRVAL_B: Set/Reset value for RAM output
//		.SRVAL_A(36’h000000000),
//		.SRVAL_B(36’h000000000),
		// WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		.WRITE_MODE_A("WRITE_FIRST"),
		.WRITE_MODE_B("WRITE_FIRST")
	) RAMB16BWER_inst (
		// Port A Data: 32-bit (each) output: Port A data
		.DOA(data_out_a_32), // 32-bit output: A port data output
		.DOPA(), // 4-bit output: A port parity output
		// Port B Data: 32-bit (each) output: Port B data
		.DOB(data_out_b_32), // 32-bit output: B port data output
		.DOPB(), // 4-bit output: B port parity output
		// Port A Address/Control Signals: 14-bit (each) input: Port A address and control signals
		.ADDRA(address_a_14), // 14-bit input: A port address input
		.CLKA(clock_a), // 1-bit input: A port clock input
		.ENA(1'b1), // 1-bit input: A port enable input
		.REGCEA(1'b0), // 1-bit input: A port register clock enable input
		.RSTA(reset), // 1-bit input: A port register set/reset input
		.WEA(write_enable_4), // 4-bit input: Port A byte-wide write enable input
		// Port A Data: 32-bit (each) input: Port A data
		.DIA(data_in_a_32), // 32-bit input: A port data input
		.DIPA(4'h0), // 4-bit input: A port parity input
		// Port B Address/Control Signals: 14-bit (each) input: Port B address and control signals
		.ADDRB(address_b_14), // 14-bit input: B port address input
		.CLKB(clock_b), // 1-bit input: B port clock input
		.ENB(1'b1), // 1-bit input: B port enable input
		.REGCEB(1'b0), // 1-bit input: B port register clock enable input
		.RSTB(1'b0), // 1-bit input: B port register set/reset input
		.WEB(4'h0), // 4-bit input: Port B byte-wide write enable input
		// Port B Data: 32-bit (each) input: Port B data
		.DIB(32'd0), // 32-bit input: B port data input
		.DIPB(4'h0) // 4-bit input: B port parity input
	);
endmodule

`endif

