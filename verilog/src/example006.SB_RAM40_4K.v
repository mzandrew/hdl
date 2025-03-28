// from SBTICETechnologyLibrary201504.pdf with some tweaks
// last updated 2025-01-09 by mza

`define icestick

module top(
	input CLK,
	input DTRn, RTSn, RX, IR_RX,
	output DCDn, DSRn, CTSn, TX, IR_TX, IR_SD,
	output J1_3, J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10,
	output J2_1, J2_2, J2_3, J2_4, J2_7, J2_8, J2_9, J2_10,
	output J3_3, J3_4, J3_5, J3_6, J3_7, J3_8, J3_9, J3_10,
	output LED5, LED4, LED3, LED2, LED1
);
	assign TX = RX; assign DCDn = 1'b1; assign DSRn = 1'b1; assign CTSn = 1'b1;
	assign IR_TX = IR_RX; assign IR_SD = 1'b1; // IR_SD = shut down
	assign J1_4 = 1'b0; assign J1_5 = 1'b0; assign J1_6 = 1'b0; assign J1_7 = 1'b0; assign J1_8 = 1'b0; assign J1_9 = 1'b0; assign J1_10 = 1'b0;
	assign J2_1 = 1'b0; assign J2_2 = 1'b0; assign J2_3 = 1'b0; assign J2_4 = 1'b0; assign J2_7 = 1'b0; assign J2_8 = 1'b0; assign J2_9 = 1'b0; assign J2_10 = 1'b0;
	assign J3_3 = 1'b0; assign J3_4 = 1'b0; assign J3_5 = 1'b0; assign J3_6 = 1'b0; assign J3_7 = 1'b0; assign J3_8 = 1'b0; assign J3_9 = 1'b0; assign J3_10 = 1'b0;
	assign LED5 = 1'b0; assign LED4 = 1'b0; assign LED3 = 1'b0; assign LED2 = 1'b0; assign LED1 = 1'b0;
	reg [15:0] read_data;
	reg [10:0] read_address = 8'h45;
	wire read_clock;
	reg read_clock_enable = 1;
	reg read_enable = 1;
	reg [10:0] write_address = 8'h99;
	wire write_clock;
	reg write_clock_enable = 1;
	reg [15:0] write_data = 16'ha50f;
	reg write_enable = 1;
	reg [15:0] bitmask = 16'h0000;
	// mode(0)=16bit, mode(1)=8bit
	SB_RAM40_4K #(.WRITE_MODE(1), .READ_MODE(1)) ram40_4k_inst (
//		.MASK(bitmask),
		.WADDR(write_address),
		.WDATA(write_data),
		.WE(write_enable),
		.WCLKE(write_clock_enable),
		.WCLK(write_clock),
		.RADDR(read_address),
		.RDATA(read_data),
		.RE(read_enable),
		.RCLKE(read_clock_enable),
		.RCLK(read_clock)
	);
	//defparam ram40_4k_inst.INIT_0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	defparam ram40_4k_inst.INIT_0 = {32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000 };
	defparam ram40_4k_inst.INIT_1 = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	defparam ram40_4k_inst.INIT_2 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	defparam ram40_4k_inst.INIT_3 = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	defparam ram40_4k_inst.INIT_4 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	defparam ram40_4k_inst.INIT_5 = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	defparam ram40_4k_inst.INIT_6 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	defparam ram40_4k_inst.INIT_7 = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	defparam ram40_4k_inst.INIT_8 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	defparam ram40_4k_inst.INIT_9 = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	defparam ram40_4k_inst.INIT_A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	defparam ram40_4k_inst.INIT_B = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	defparam ram40_4k_inst.INIT_C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	defparam ram40_4k_inst.INIT_D = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	defparam ram40_4k_inst.INIT_E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	defparam ram40_4k_inst.INIT_F = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	assign read_clock = CLK;
	assign write_clock = CLK;
	assign J1_3 = read_data[0];
endmodule // top

