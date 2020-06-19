// to run on an althea
//`define TESTBENCH;
//`define xilinx

// written 2020-05-13 by mza
// based on mza-test042.spi-pollable-memories-and-oserdes-function-generator.althea.v
// last updated 2020-06-19 by mza

`define althea_revA
//`include "lib/generic.v"
`include "lib/RAM8.v"
//`include "lib/spi.v"
//`include "lib/serdes_pll.v"
//`include "lib/dcm.v"
//`include "lib/reset.v"
//`include "lib/frequency_counter.v"
//`include "lib/axi4lite.v"
//`include "lib/segmented_display_driver.v"
//`include "lib/synchronizer.v"

//`define USE_INFERRED_RAM_16
//`define USE_BRAM_512
//`define USE_BRAM_4K

module top (
	input clock50_p, clock50_n,
	output lemo,
	output other0,
	output other1,
	inout [6:0] bus,
	input read, // 0=write; 1=read
	input register_select, // 0=address; 1=data
	input enable, // 1=active
	output reg ack = 0,
	output reg valid = 0,
	output [7:0] leds
);
	wire clock50;
	IBUFGDS mybuf0 (.I(clock50_p), .IB(clock50_n), .O(clock50));
	reg ale_mode = 0;
	reg write_mode = 0;
	reg read_mode = 0;
	reg [6:0] address = 0;
	reg [6:0] write_data = 0;
	wire [6:0] read_data;
	reg [6:0] pre_bus = 0;
	localparam COUNTER50_BIT_PICKOFF = 3;
	reg [COUNTER50_BIT_PICKOFF:0] counter50 = 0;
	reg reset50 = 1;
	always @(posedge clock50) begin
		valid <= 0;
		ack <= 0;
		read_mode <= 0;
		write_mode <= 0;
		ale_mode <= 0;
		if (reset50) begin
			if (counter50[COUNTER50_BIT_PICKOFF]) begin
				reset50 <= 0;
			end
			counter50 <= counter50 + 1'b1;
			address <= 0;
			write_data <= 0;
			pre_bus <= 0;
		end else begin
			if (enable) begin
				if (read) begin // read mode
					read_mode <= 1;
					pre_bus <= read_data;
					valid <= 1;
				end else begin // write mode
					if (register_select) begin
						write_mode <= 1;
						write_data <= bus;
					end else begin
						ale_mode <= 1;
						address <= bus;
					end
					ack <= 1;
				end
			end
		end
	end
//	bus_entry_3state #(.WIDTH(7)) my3sbe (.I(pre_bus), .O(bus), .T(read_mode)); // we are slave
	bus_entry_3state #(.WIDTH(7)) my3sbe (.I(pre_bus), .O(bus), .T(read)); // we are slave
//	bus_entry_3state #(.WIDTH(7)) my3sbe (.I(pre_bus), .O(bus), .T(0)); // we are slave
	assign bus = 7'bz;
	RAM_inferred #(.addr_width(7), .data_width(7)) myram (.reset(reset50),
		.wclk(clock50), .waddr(address), .din(write_data), .write_en(write_mode),
		.rclk(clock50), .raddr(address), .dout(read_data));
	assign leds[7] = ack;
	assign leds[6] = valid;
	assign leds[5] = read_mode;
	assign leds[4] = write_mode;
	assign leds[3] = ale_mode;
	assign leds[2] = 0;
	assign leds[1] = 0;
	assign leds[0] = reset50;
endmodule

module top_tb;
	reg clock50_p = 0;
	reg clock50_n = 1;
	wire lemo, other0, other1;
	reg [6:0] pre_bus = 0;
	wire [6:0] bus;
	wire [7:0] leds;
	reg register_select = 0;
	reg enable = 0;
	reg read = 0;
	wire valid;
	bus_entry_3state #(.WIDTH(7)) my3sbe (.I(pre_bus), .O(bus), .T(~read)); // we are master
	top mytop (
		.clock50_p(clock50_p), .clock50_n(clock50_n),
		.lemo(lemo), .other0(other0), .other1(other1),
		.bus(bus), .read(read), .register_select(register_select), .enable(enable), .valid(valid), .ack(ack),
		.leds(leds)
	);
	initial begin
		#300;
		// write address
		register_select <= 0;
		read <= 0;
		pre_bus <= 7'h11;
		enable <= 1;
		#40;
		enable <= 0;
		#100;
		// write data
		register_select <= 1;
		read <= 0;
		pre_bus <= 7'h22;
		enable <= 1;
		#40;
		enable <= 0;
		#100;
		// try reading
		read <= 1;
		enable <= 1;
		#40;
		enable <= 0;
	end
	always begin
		#10;
		clock50_p <= ~clock50_p;
		clock50_n <= ~clock50_n;
	end
endmodule

//module mza_test042_spi_pollable_memories_and_oserdes_function_generator_althea_top (
module myalthea (
	input clock50_p, clock50_n,
	output lemo, // oserdes/trig output
	output b_p, // oserdes/trig output other0
	output f_p, // oserdes/trig output other1
//	output _, // rpi_gpio2
//	output _, // rpi_gpio3
//	input _, // rpi_gpio4
	input d_n, // rpi_gpio5
	input d_p, // rpi_gpio6_gpclk2
	input a_p, // rpi_gpio7
	input c_n, // rpi_gpio8
	input a_n, // rpi_gpio9
	input b_n, // rpi_gpio10
	input c_p, // rpi_gpio11
// rpi_gpio12
	input e_n, // rpi_gpio13
	input e_p, // rpi_gpio19
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	wire [6:0] bus = { d_n, d_p, a_p, c_n, a_n, b_n, c_p };
	wire [7:0] leds;
	wire ale = e_n;
	wire write = e_p;
	wire read = 0;
	wire valid;
	wire ack;
//	assign _ = ack;
//	assign _ = valid;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = leds;
	top althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n),
		.lemo(lemo), .other0(b_p), .other1(f_p),
		.bus(bus), .ale(ale), .read(read), .valid(valid), .ack(ack),
		.leds(leds)
	);
endmodule

