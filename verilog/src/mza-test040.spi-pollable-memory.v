// to run on an icezero

// written 2020-05-07 by mza
// based on mza-test039.spi.v and mza-test036.function-generator.althea.v and mza-test017.serializer-ram.v
// last updated 2020-05-07 by mza

`include "lib/easypll.v"
`include "lib/spi.v"

module RAM_ice40_1k_32bit #(
) (
	input reset,
	input write_clock,
	input [10:0] write_address,
	input [31:0] write_data,
	input write_enable,
	input read_clock,
	input [10:0] read_address,
	output [31:0] read_data
);
	SB_RAM40_4K #( // see SBTICETechnologyLibrary201504.pdf
		.WRITE_MODE(0), // configured as 1kx16
		.READ_MODE(0)   // configured as 1kx16
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
		.WRITE_MODE(0), // configured as 1kx16
		.READ_MODE(0)   // configured as 1kx16
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

module RAM_ice40_1k_16bit #(
) (
	input reset,
	input write_clock,
	input [10:0] write_address,
	input [15:0] write_data,
	input write_enable,
	input read_clock,
	input [10:0] read_address,
	output [15:0] read_data
);
	SB_RAM40_4K #( // see SBTICETechnologyLibrary201504.pdf
		.WRITE_MODE(0), // configured as 1kx16
		.READ_MODE(0)   // configured as 1kx16
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

module top #(
	parameter DATA_BUS_WIDTH = 8,
	parameter ADDRESS_BUS_DEPTH = 14
) (
	input clock100,
	input rpi_spi_sclk,
	input rpi_spi_mosi,
	output rpi_spi_miso,
	input rpi_spi_ce0,
	input rpi_spi_ce1,
//	output pmod4_5,
//	output pmod4_6,
//	output pmod4_7,
//	output pmod4_8,
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
	easypll #(.DIVR(4'd3), .DIVF(7'd40), .DIVQ(3'd6)) mp (.clock_input(clock100), .reset_active_low(~reset1), .global_clock_output(clock16), .pll_is_locked(pll_locked));
//	wire [7:0] data_from_master;
//	wire [7:0] data_to_master;
//	wire data_valid;
	wire [7:0] command8;
	wire [15:0] address16;
	wire [31:0] data32;
//	wire [15:0] write_data16;
//	wire [15:0] read_data16;
	wire [10:0] address11 = address16[10:0];
	wire [31:0] read_data32;
//	reg write_enable = 0;
	wire transaction_valid;
//	SPI_slave_simple8 spi_s8 (.clock(clock100), .SCK(rpi_spi_sclk), .MOSI(rpi_spi_mosi), .MISO(rpi_spi_miso), .SSEL(rpi_spi_ce0), .data_to_master(data_to_master), .data_from_master(data_from_master), .data_valid(data_valid));
	SPI_slave_command8_address16_data32 spi_c8_a16_d32 (.clock(clock16), .SCK(rpi_spi_sclk), .MOSI(rpi_spi_mosi), .MISO(rpi_spi_miso), .SSEL(rpi_spi_ce1), .transaction_valid(transaction_valid), .command8(command8), .address16(address16), .data32(data32), .data32_to_master(read_data32));
	RAM_ice40_1k_32bit myram (.reset(reset2),
		.write_clock(clock16), .write_address(address11), .write_data(data32), .write_enable(transaction_valid),
		.read_clock(clock16), .read_address(address11), .read_data(read_data32));
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
	wire [ADDRESS_BUS_DEPTH-1:0] write_address;
	wire write_enable;
	wire [DATA_BUS_WIDTH-1:0] data;
endmodule

