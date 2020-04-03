// last updated 2020-04-03 by mza

// RAMB16BWER 16k-bit dual-port memory (instantiation example from spartan6_hdl.pdf from xilinx)
module RAM_s6_2k_8bit (
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
		.INIT_FILE("NONE"),
		// RSTTYPE: "SYNC" or "ASYNC"
		.RSTTYPE("SYNC"),
		// RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		.RST_PRIORITY_A("CE"),
		.RST_PRIORITY_B("CE"),
		// SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		.SIM_COLLISION_CHECK("ALL"),
		// SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		.SIM_DEVICE("SPARTAN3ADSP"),
		// SRVAL_A/SRVAL_B: Set/Reset value for RAM output
//		.SRVAL_A(36’h000000000),
//		.SRVAL_B(36’h000000000),
		// WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		.WRITE_MODE_A("READ_FIRST"),
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

