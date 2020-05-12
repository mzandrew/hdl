// to run on an althea
//`define TESTBENCH;
//`define xilinx

// written 2020-05-07 by mza
// based on mza-test040.spi-pollable-memory.v and modified to work on an althea
// last updated 2020-05-11 by mza

`include "lib/spi.v"
`include "lib/RAM8.v"

//`define USE_SLOW_CLOCK
//`define USE_INFERRED_RAM_16
//`define USE_BRAM_256
`define USE_BRAM_512
//`define USE_BRAM_1K
//`define USE_BRAM_2K

`ifdef USE_SLOW_CLOCK
`include "lib/easypll.v"
`endif

//`ifdef xilinx
//`else
//`endif

module top (
	input clock50_p, clock50_n,
	input rpi_spi_sclk,
	input rpi_spi_mosi,
	output rpi_spi_miso,
	input rpi_spi_ce0,
	input rpi_spi_ce1,
	output led_0, led_1, led_2, led_3,
	output led_4, led_5, led_6, led_7
);
	wire clock50;
	IBUFGDS mybuf (.I(clock50_p), .IB(clock50_n), .O(clock50));
	reg reset1 = 1;
	wire clock_ram;
	wire clock_spi;
`ifdef USE_SLOW_CLOCK
	wire clock16;
	reg reset2 = 1;
	wire pll_locked;
	easypll #(.DIVR(4'd3), .DIVF(7'd40), .DIVQ(3'd6)) mp (.clock_input(clock50), .reset_active_low(~reset1), .global_clock_output(clock16), .pll_is_locked(pll_locked));
	assign clock_ram = clock16;
	assign clock_spi = clock16;
`else
	assign clock_ram = clock50;
	assign clock_spi = clock50;
`endif
	reg [7:0] reset_counter = 0;
	always @(posedge clock50) begin
		if (reset1) begin
			if (reset_counter[7]) begin
				reset1 <= 0;
			end else begin
				reset_counter <= reset_counter + 1'b1;
			end
`ifdef USE_SLOW_CLOCK
		end else if (reset2) begin
			if (pll_locked) begin
				reset2 <= 0;
			end
`endif
		end
	end
//`ifdef xilinx
//	assign clock16 = clock50, pll_locked = 1;
//	assign clock16 = clock50, pll_locked = 1;
//`endif
//	wire [7:0] data_from_master;
//	wire [7:0] data_to_master;
//	wire data_valid;
	wire [7:0] command8;
	wire [15:0] address16;
	wire [31:0] data32;
//	wire [15:0] write_data16;
//	wire [15:0] read_data16;
	wire [31:0] read_data32;
//	reg write_enable = 0;
	wire transaction_valid;
//	SPI_slave_simple8 spi_s8 (.clock(clock_spi), .SCK(rpi_spi_sclk), .MOSI(rpi_spi_mosi), .MISO(rpi_spi_miso), .SSEL(rpi_spi_ce0), .data_to_master(data_to_master), .data_from_master(data_from_master), .data_valid(data_valid));
	SPI_slave_command8_address16_data32 spi_c8_a16_d32 (.clock(clock_spi),
		.SCK(rpi_spi_sclk), .MOSI(rpi_spi_mosi), .MISO(rpi_spi_miso), .SSEL(rpi_spi_ce1),
		.transaction_valid(transaction_valid), .command8(command8), .address16(address16), .data32(data32), .data32_to_master(read_data32));
`ifdef USE_INFERRED_RAM_16
	wire [3:0] address4 = address16[3:0];
	RAM_inferred #(.addr_width(4), .data_width(32)) myram (.reset(reset1),
		.wclk(clock_ram), .waddr(address4), .din(data32), .write_en(transaction_valid),
		.rclk(clock_ram), .raddr(address4), .dout(read_data32));
`elsif USE_BRAM_512
	wire [8:0] address9 = address16[8:0];
	RAM_s6_512_32bit mem (.reset(reset1),
		.write_clock(clock_ram), .write_address(address9), .data_in(data32), .write_enable(transaction_valid),
		.read_clock(clock_ram), .read_address(address9), .data_out(read_data32), .read_enable(1'b1));
`endif
	//wire [7:0] leds = { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 };
	//assign leds = data32[7:0];
	assign led_0 = 0;
	assign led_1 = 0;
	assign led_2 = 0;
	assign led_3 = 0;
	assign led_4 = 0;
	assign led_5 = 0;
	assign led_6 = 0;
	assign led_7 = 0;
endmodule

module mza_test041_spi_pollable_memory_althea_top (
	input clock50_p, clock50_n,
	output lemo,
	input a_p,
	input c_n,
	input c_p,
	output d_n,
	input d_p,
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	assign lemo = 0;
	top mytop (
		.clock50_p(clock50_p), .clock50_n(clock50_n),
//		.lemo(lemo),
		.rpi_spi_mosi(d_p), .rpi_spi_miso(d_n), .rpi_spi_sclk(c_p), .rpi_spi_ce0(c_n), .rpi_spi_ce1(a_p),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

