// last updated 2020-04-26 by mza

//(* keep_hierarchy = "yes" *)
//(* BMM_INFO = " " *)
//(* BMM_INFO = "ADDRESS_SPACE map_name RAMB16 [start:end] END_ADDRESS_MAP;" *)

module RAM_s6_16k_8bit #(
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
		RAM_s6_2k_8bit mem (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[i]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[i]), .read_enable(1'b1));
	end
//	RAM_s6_2k_8bit mem0 (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[0]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[0]), .read_enable(1'b1));
//	RAM_s6_2k_8bit mem1 (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[1]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[1]), .read_enable(1'b1));
//	RAM_s6_2k_8bit mem2 (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[2]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[2]), .read_enable(1'b1));
//	RAM_s6_2k_8bit mem3 (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[3]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[3]), .read_enable(1'b1));
//	RAM_s6_2k_8bit mem4 (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[4]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[4]), .read_enable(1'b1));
//	RAM_s6_2k_8bit mem5 (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[5]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[5]), .read_enable(1'b1));
//	RAM_s6_2k_8bit mem6 (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[6]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[6]), .read_enable(1'b1));
//	RAM_s6_2k_8bit mem7 (.write_clock(write_clock), .read_clock(read_clock), .reset(reset), .data_in(data_in), .data_out(data_out_array[7]), .write_address(write_address[10:0]), .read_address(read_address[10:0]), .write_enable(write_enable_array[7]), .read_enable(1'b1));
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
		// INITP_00 to INITP_07: Initial memory contents.
//		.INITP_00(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_01(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_02(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_03(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_04(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_05(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_06(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_07(256’h0000000000000000000000000000000000000000000000000000000000000000),
		// INIT_00 to INIT_3F: Initial memory contents.
//		.INIT_00(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_01(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_02(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_03(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_04(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_05(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_06(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_07(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_08(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_09(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0A(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0B(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0C(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0D(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0E(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0F(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_10(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_11(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_12(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_13(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_14(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_15(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_16(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_17(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_18(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_19(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1A(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1B(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1C(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1D(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1E(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1F(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_20(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_21(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_22(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_23(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_24(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_25(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_26(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_27(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_28(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_29(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_2A(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_2B(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_2C(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_2D(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_2E(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_2F(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_30(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_31(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_32(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_33(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_34(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_35(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_36(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_37(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_38(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_39(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_3A(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_3B(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_3C(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_3D(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_3E(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_3F(256’h0000000000000000000000000000000000000000000000000000000000000000),
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
		.ENA(write_enable), // 1-bit input: A port enable input
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
		// INITP_00 to INITP_03: Allows specification of the initial contents of the 1KB parity data memory array.
//		.INITP_00(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_01(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_02(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INITP_03(256’h0000000000000000000000000000000000000000000000000000000000000000),
		// INIT_00 to INIT_1F: Allows specification of the initial contents of the 8KB data memory array.
//		.INIT_00(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_01(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_02(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_03(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_04(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_05(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_06(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_07(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_08(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_09(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0A(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0B(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0C(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0D(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0E(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_0F(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_10(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_11(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_12(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_13(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_14(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_15(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_16(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_17(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_18(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_19(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1A(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1B(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1C(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1D(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1E(256’h0000000000000000000000000000000000000000000000000000000000000000),
//		.INIT_1F(256’h0000000000000000000000000000000000000000000000000000000000000000),
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

