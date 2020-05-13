// to run on an althea
//`define TESTBENCH;
//`define xilinx

// written 2020-05-13 by mza
// based on mza-test041.spi-pollable-memory.althea.v
// last updated 2020-05-13 by mza

`include "lib/spi.v"
`include "lib/RAM8.v"
`include "lib/serdes_pll.v"
`include "lib/dcm.v"

//`define USE_SLOW_CLOCK
//`define USE_INFERRED_RAM_16
//`define USE_BRAM_512
`define USE_BRAM_4K

//`ifdef xilinx
//`else
//`endif

module top (
	input clock50_p, clock50_n,
	output lemo,
	input rpi_spi_sclk,
	input rpi_spi_mosi,
	output rpi_spi_miso,
	input rpi_spi_ce0,
	input rpi_spi_ce1,
	output led_0, led_1, led_2, led_3,
	output led_4, led_5, led_6, led_7
);
	reg reset1 = 1;
	reg reset2 = 1;
	reg reset3 = 1;
	wire clock50;
	IBUFGDS mybuf (.I(clock50_p), .IB(clock50_n), .O(clock50));
	wire rawclock125;
	wire pll_locked;
	simplepll_BASE #(.overall_divide(1), .multiply(10), .divide0(4), .phase0(0.0), .period(20.0)) kronos (.clockin(clock50), .reset(reset1), .clock0out(rawclock125), .clock1out(), .clock2out(), .clock3out(), .clock4out(), .clock5out(), .locked(pll_locked)); // 50->125
	wire clock125;
	BUFG mrt (.I(rawclock125), .O(clock125));
	// ----------------------------------------------------------------------
	wire word_clock;
	wire [7:0] oserdes_word_out;
	wire pll_oserdes_locked;
	wire clock_ram;
	wire clock_spi;
	assign clock_ram = word_clock;
	assign clock_spi = word_clock;
	reg [7:0] reset_counter = 0;
	always @(posedge clock50) begin
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
		end else if (reset3) begin
			if (pll_oserdes_locked) begin
				reset3 <= 0;
			end
		end
	end
	// ----------------------------------------------------------------------
	wire miso_ce0;
	wire miso_ce1;
	//assign rpi_spi_miso = rpi_spi_ce1 ? miso_ce0 : miso_ce1;
	assign rpi_spi_miso = rpi_spi_ce0 ? miso_ce1 : miso_ce0;
	// ----------------------------------------------------------------------
	wire [7:0] command8_ce0;
	wire [15:0] address16_ce0;
	wire [31:0] data32_ce0;
	wire [31:0] read_data32_ce0;
	wire transaction_valid_ce0;
	SPI_slave_command8_address16_data32 spi_ce0 (.clock(clock_spi),
		.SCK(rpi_spi_sclk), .MOSI(rpi_spi_mosi), .MISO(miso_ce0), .SSEL(rpi_spi_ce0),
		.transaction_valid(transaction_valid_ce0), .command8(command8_ce0), .address16(address16_ce0), .data32(data32_ce0), .data32_to_master(read_data32_ce0));
	wire [3:0] address4_ce0 = address16_ce0[3:0];
	RAM_inferred #(.addr_width(4), .data_width(32)) myram (.reset(reset3),
		.wclk(clock_ram), .waddr(address4_ce0), .din(data32_ce0), .write_en(transaction_valid_ce0),
		.rclk(clock_ram), .raddr(address4_ce0), .dout(read_data32_ce0));
	// ----------------------------------------------------------------------
	wire [7:0] command8;
	wire [15:0] address16;
	wire [31:0] data32_0123;
	wire [31:0] data32_3210;
	assign data32_0123[7:0]   = data32_3210[31:24];
	assign data32_0123[15:8]  = data32_3210[23:16];
	assign data32_0123[23:16] = data32_3210[15:8];
	assign data32_0123[31:24] = data32_3210[7:0];
	wire [31:0] read_data32_0123;
	wire [31:0] read_data32_3210;
	assign read_data32_3210[7:0]   = read_data32_0123[31:24];
	assign read_data32_3210[15:8]  = read_data32_0123[23:16];
	assign read_data32_3210[23:16] = read_data32_0123[15:8];
	assign read_data32_3210[31:24] = read_data32_0123[7:0];
	wire transaction_valid_ce1;
	SPI_slave_command8_address16_data32 spi_ce1 (.clock(clock_spi),
		.SCK(rpi_spi_sclk), .MOSI(rpi_spi_mosi), .MISO(miso_ce1), .SSEL(rpi_spi_ce1),
		.transaction_valid(transaction_valid_ce1), .command8(command8), .address16(address16), .data32(data32_3210), .data32_to_master(read_data32_3210));
`ifdef USE_BRAM_512
	wire [8:0] address9 = address16[8:0];
	wire [10:0] read_address11 = read_address[10:0];
	RAM_s6_512_32bit_8bit mem (.reset(reset3),
		.clock_a(clock_ram), .address_a(address9), .data_in_a(data32_0123), .write_enable_a(transaction_valid_ce1), .data_out_a(read_data32_0123),
		.clock_b(clock_ram), .address_b(read_address11), .data_out_b(oserdes_word_out));
`elsif USE_BRAM_4K
	wire [11:0] address12 = address16[11:0];
	wire [13:0] read_address14 = read_address[13:0];
	RAM_s6_4k_32bit_8bit mem (.reset(reset3),
		.clock_a(clock_ram), .address_a(address12), .data_in_a(data32_0123), .write_enable_a(transaction_valid_ce1), .data_out_a(read_data32_0123),
		.clock_b(clock_ram), .address_b(read_address14), .data_out_b(oserdes_word_out));
`endif
	// ----------------------------------------------------------------------
	reg [15:0] read_address = 0;
	always @(posedge word_clock) begin
		if (reset3) begin
			read_address <= 0;
		end else begin
			read_address <= read_address + 1'b1;
		end
	end
	ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL")) mylei (.clock_in(clock125), .reset(reset2), .word_clock_out(word_clock), .word_in(oserdes_word_out), .D_out(lemo), .locked(pll_oserdes_locked));
	// ----------------------------------------------------------------------
	if (0) begin
		wire [7:0] leds;
		assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = leds;
		assign leds = oserdes_word_out;
	end else begin
		assign led_7 = reset1;
		assign led_6 = reset2;
		assign led_5 = reset3;
		assign led_4 = ~rpi_spi_ce0;
		assign led_3 = ~rpi_spi_ce1;
		assign led_2 = 0;
		assign led_1 = 0;
		assign led_0 = 0;
		//assign led_2 = data32_ce0[2];
		//assign led_1 = data32_ce0[1];
		//assign led_0 = data32_ce0[0];
	end
endmodule

module mza_test042_spi_pollable_memories_and_oserdes_function_generator_althea_top (
	input clock50_p, clock50_n,
	output lemo,
	input a_p,
	input c_n,
	input c_p,
	output d_n,
	input d_p,
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	top mytop (
		.clock50_p(clock50_p), .clock50_n(clock50_n),
		.lemo(lemo),
		.rpi_spi_mosi(d_p), .rpi_spi_miso(d_n), .rpi_spi_sclk(c_p), .rpi_spi_ce0(c_n), .rpi_spi_ce1(a_p),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

