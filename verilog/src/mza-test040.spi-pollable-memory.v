// to run on an icezero
//`define TESTBENCH;
//`define icezero;
//`define ice40;
//`define xilinx

// written 2020-05-07 by mza
// based on mza-test039.spi.v and mza-test036.function-generator.althea.v and mza-test017.serializer-ram.v
// last updated 2020-05-07 by mza

`include "lib/spi.v"

`ifdef xilinx
`else
`include "lib/easypll.v"
`endif

module RAM_ice40_256_32bit #(
) (
	input reset,
	input write_clock,
	input [7:0] write_address,
	input [31:0] write_data,
	input write_enable,
	input read_clock,
	input [7:0] read_address,
	output [31:0] read_data
);
	SB_RAM40_4K #( // see SBTICETechnologyLibrary201504.pdf
		.WRITE_MODE(0), // configured as 256x16
		.READ_MODE(0)   // configured as 256x16
	) ram40_4k_inst_1 (
		.WCLK(write_clock),
		.WADDR(write_address),
		.WDATA(write_data[31:16]),
		.WE(write_enable),
		.WCLKE(1),
		.MASK(16'b0),
		.RCLK(read_clock),
		.RADDR(read_address),
		.RDATA(read_data[31:16]),
		.RE(1),
		.RCLKE(1)
	);
	SB_RAM40_4K #( // see SBTICETechnologyLibrary201504.pdf
		.WRITE_MODE(0), // configured as 256x16
		.READ_MODE(0)   // configured as 256x16
	) ram40_4k_inst_0 (
		.WCLK(write_clock),
		.WADDR(write_address),
		.WDATA(write_data[15:0]),
		.WE(write_enable),
		.WCLKE(1),
		.MASK(16'b0),
		.RCLK(read_clock),
		.RADDR(read_address),
		.RDATA(read_data[15:0]),
		.RE(1),
		.RCLKE(1)
	);
endmodule

module RAM_ice40_256_16bit #(
) (
	input reset,
	input write_clock,
	input [7:0] write_address,
	input [15:0] write_data,
	input write_enable,
	input read_clock,
	input [7:0] read_address,
	output [15:0] read_data
);
	SB_RAM40_4K #( // see SBTICETechnologyLibrary201504.pdf
		.WRITE_MODE(0), // configured as 256x16
		.READ_MODE(0)   // configured as 256x16
	) ram40_4k_inst (
		.WCLK(write_clock),
		.WADDR(write_address),
		.WDATA(write_data),
		.WE(write_enable),
		.WCLKE(1),
		.MASK(16'b0),
		.RCLK(read_clock),
		.RADDR(read_address),
		.RDATA(read_data),
		.RE(1),
		.RCLKE(1)
	);
endmodule

module RAM_ice40_512_8bit #(
) (
	input reset,
	input write_clock,
	input [8:0] write_address,
	input [7:0] write_data,
	input write_enable,
	input read_clock,
	input [8:0] read_address,
	output [7:0] read_data
);
	SB_RAM40_4K #( // see SBTICETechnologyLibrary201504.pdf
		.WRITE_MODE(1), // configured as 512x8
		.READ_MODE(1)   // configured as 512x8
	) ram40_4k_inst (
		.WCLK(write_clock),
		.WADDR(write_address),
		.WDATA(write_data),
		.WE(write_enable),
		.WCLKE(1),
		.RCLK(read_clock),
		.RADDR(read_address),
		.RDATA(read_data),
		.RE(1),
		.RCLKE(1)
	);
endmodule

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

module top (
	input clock100,
	input rpi_spi_sclk,
	input rpi_spi_mosi,
	output rpi_spi_miso,
	input rpi_spi_ce0,
	input rpi_spi_ce1,
	output led1,
	output led2,
	output led3
);
	reg reset1 = 1;
	reg reset2 = 1;
	reg [7:0] reset_counter = 0;
	always @(posedge clock100) begin
		if (reset1) begin
			if (reset_counter[7]) begin
				reset1 <= 0;
			end else begin
				reset_counter <= reset_counter + 1'b1;
			end
		end else if (reset2) begin
			if (pll_locked) begin
				reset2 <= 0;
			end
		end
	end
	wire clock16;
	wire pll_locked;
`ifdef xilinx
	assign clock16 = clock100, pll_locked = 1;
`else
	easypll #(.DIVR(4'd3), .DIVF(7'd40), .DIVQ(3'd6)) mp (.clock_input(clock100), .reset_active_low(~reset1), .global_clock_output(clock16), .pll_is_locked(pll_locked));
`endif
//	wire [7:0] data_from_master;
//	wire [7:0] data_to_master;
//	wire data_valid;
	wire [7:0] command8;
	wire [15:0] address16;
	wire [31:0] data32;
//	wire [15:0] write_data16;
//	wire [15:0] read_data16;
	wire [7:0] address8 = address16[10:0];
	wire [31:0] read_data32;
//	reg write_enable = 0;
	wire transaction_valid;
//	SPI_slave_simple8 spi_s8 (.clock(clock100), .SCK(rpi_spi_sclk), .MOSI(rpi_spi_mosi), .MISO(rpi_spi_miso), .SSEL(rpi_spi_ce0), .data_to_master(data_to_master), .data_from_master(data_from_master), .data_valid(data_valid));
	SPI_slave_command8_address16_data32 spi_c8_a16_d32 (.clock(clock16), .SCK(rpi_spi_sclk), .MOSI(rpi_spi_mosi), .MISO(rpi_spi_miso), .SSEL(rpi_spi_ce1), .transaction_valid(transaction_valid), .command8(command8), .address16(address16), .data32(data32), .data32_to_master(read_data32));
`ifdef xilinx
	RAM_inferred #(.addr_width(8), .data_width(32)) myram (.reset(reset2), .din(data32), .write_en(transaction_valid), .waddr(address8), .wclk(clock16), .raddr(address8), .rclk(clock16), .dout(read_data32));
`else
	RAM_ice40_256_32bit myram (.reset(reset2),
		.write_clock(clock16), .write_address(address8), .write_data(data32), .write_enable(transaction_valid),
		.read_clock(clock16), .read_address(address8), .read_data(read_data32));
`endif
//	RAM_ice40_1k_16bit myram (.reset(reset2), .write_clock(clock100), .write_address(write_address10), .write_data(write_data16), .write_enable(write_enable), .read_clock(clock100), .read_address(read_address10), .read_data(read_data16));
//	reg [7:0] previous_data_from_master = 0;
//	reg which16 = 0;
//	always @(posedge clock100) begin
//		case (which16)
//			2'b00:   begin read_data32[31:16] <= read_data16; end
//			default: begin read_data32[15:0]  <= read_data16; end
//		endcase
//		read_address10 <= { address16[8:0], which16 };
//		which16 <= ~which16;
//		if (transaction_valid) begin
//			write_enable <= 1;
//		end
//	end
//	assign data_to_master = previous_data_from_master;
//	assign led1 = reset1;
//	assign led2 = reset2;
	wire [2:0] leds = { led1, led2, led3 };
	//assign leds = data_from_master[2:0];
	assign leds = data32[2:0];
//	assign pmod4_5 = rpi_spi_sclk;
//	assign pmod4_6 = rpi_spi_mosi;
//	assign pmod4_7 = rpi_spi_ce0;
//	assign pmod4_8 = rpi_spi_ce1;
//	assign rpi_spi_miso = 0;
endmodule

module top_tb;
	reg SCK = 0;
	reg MOSI = 0;
	reg SSEL = 1;
	reg [7:0] i = 0;
	reg [7:0] j = 0;
	task automatic spi_c8_a16_d32_master_transaction;
		input [7:0] command8;
		input [15:0] address16;
		input [31:0] data32;
		begin
			#300;
			SSEL <= 0;
			for (i=8; i>0; i=i-1) begin : command
				MOSI <= command8[i-1];
				#100;
				SCK <= 1;
				#100;
				SCK <= 0;
			end
			for (i=16; i>0; i=i-1) begin : address
				MOSI <= address16[i-1];
				#100;
				SCK <= 1;
				#100;
				SCK <= 0;
			end
			for (i=32; i>0; i=i-1) begin : data
				MOSI <= data32[i-1];
				#100;
				SCK <= 1;
				#100;
				SCK <= 0;
			end
			MOSI <= 0;
			#100;
			SSEL <= 1;
		end
	endtask
	reg clock100 = 0;
	reg rpi_spi_ce0 = 1;
	wire MISO;
	wire led1, led2, led3;
	top mytop (.clock100(clock100), .rpi_spi_sclk(SCK), .rpi_spi_mosi(MOSI), .rpi_spi_miso(MISO), .rpi_spi_ce0(rpi_spi_ce0), .rpi_spi_ce1(SSEL), .led1(led1), .led2(led2), .led3(led3));
//	reg [7:0] command8 = 8'h01;
//	reg [15:0] address16 = 16'h0045;
//	reg [31:0] data32 = 32'h6789abcd;
	initial begin
		SCK <= 0;
		MOSI <= 0;
		SSEL <= 1;
		spi_c8_a16_d32_master_transaction(8'h01, 16'h0001, 32'h01234567);
		spi_c8_a16_d32_master_transaction(8'h01, 16'h0001, 32'h01234567);
		spi_c8_a16_d32_master_transaction(8'h01, 16'h0101, 32'h89abcdef);
		spi_c8_a16_d32_master_transaction(8'h01, 16'h0101, 32'h89abcdef);
		spi_c8_a16_d32_master_transaction(8'h01, 16'h0001, 32'h01234567);
//		for (j=0; j<3; j=j+1) begin : twice
//		end
		#200;
		$finish;
	end
	always begin
		#10;
		clock100 <= ~clock100;
	end
endmodule

