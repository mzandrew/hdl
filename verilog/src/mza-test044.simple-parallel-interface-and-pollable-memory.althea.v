// to run on an althea
//`define TESTBENCH;
//`define xilinx

// written 2020-05-13 by mza
// based on mza-test042.spi-pollable-memories-and-oserdes-function-generator.althea.v
// last updated 2020-06-20 by mza

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

module top #(
	parameter WIDTH = 7
) (
	input clock50_p, clock50_n,
	output lemo,
	output other0,
	output other1,
	inout [WIDTH-1:0] bus,
	input read, // 0=write; 1=read
	input register_select, // 0=address; 1=data
	input enable, // 1=active; 0=inactive
	output reg ack = 0,
	output [7:0] leds
);
	wire clock50;
	IBUFGDS mybuf0 (.I(clock50_p), .IB(clock50_n), .O(clock50));
	reg write_strobe = 0;
	reg [WIDTH-1:0] address = 0;
	reg [WIDTH-1:0] write_data0 = 0;
	reg [WIDTH-1:0] write_data1 = 0;
	wire [2*WIDTH-1:0] write_data;
	assign write_data = { write_data1, write_data0 };
	reg [2:0] wstate = 0;
	wire [2*WIDTH-1:0] read_data;
	wire [WIDTH-1:0] read_data1 = read_data[2*WIDTH-1:WIDTH];
	wire [WIDTH-1:0] read_data0 = read_data[WIDTH-1:0];
	reg [1:0] rstate = 0;
	reg [WIDTH-1:0] pre_bus = 0;
	localparam COUNTER50_BIT_PICKOFF = 3;
	reg [COUNTER50_BIT_PICKOFF:0] counter50 = 0;
	reg reset50 = 1;
	always @(posedge clock50) begin
		ack <= 0;
		write_strobe <= 0;
		if (reset50) begin
			if (counter50[COUNTER50_BIT_PICKOFF]) begin
				reset50 <= 0;
			end
			counter50 <= counter50 + 1'b1;
			address <= 0;
			write_data0 <= 0;
			write_data1 <= 0;
			wstate <= 0;
			rstate <= 0;
			pre_bus <= 0;
		end else begin
			if (enable) begin
				ack <= 1;
				if (read) begin // read mode
					if (rstate[1]==0) begin
						if (rstate[0]==0) begin
							rstate[0] <= 1;
							pre_bus <= read_data1;
						end
					end else begin
						if (rstate[0]==0) begin
							rstate[0] <= 1;
							pre_bus <= read_data0;
						end
					end
				end else begin // write mode
					if (register_select) begin
						if (wstate[2]==0) begin
							if (wstate[1]==0) begin
								if (wstate[0]==0) begin
									wstate[0] <= 1;
									write_data1 <= bus; // most significant halfword first
								end
							end else begin
								if (wstate[0]==0) begin
									wstate <= 3'b101;
									write_data0 <= bus;
								end
							end
						end else begin
							if (wstate[1:0]==2'b01) begin
								wstate[1] <= 1;
								write_strobe <= 1;
							end
						end
					end else begin // register_select=0
						address <= bus;
						rstate <= 0;
						wstate <= 0;
					end
				end
			end else begin // enable=0
				if (wstate[1:0]==2'b01) begin
					wstate[1:0] <= 2'b10;
				end else if (wstate==3'b111) begin
					wstate <= 0;
				end
				if (rstate[1:0]==2'b01) begin
					rstate[1:0] <= 2'b10;
				end else if (rstate==2'b11) begin
					rstate <= 0;
				end
			end
		end
	end
	bus_entry_3state #(.WIDTH(WIDTH)) my3sbe (.I(pre_bus), .O(bus), .T(read)); // we are slave
	assign bus = 'bz;
	RAM_inferred #(.addr_width(WIDTH), .data_width(2*WIDTH)) myram (.reset(reset50),
		.wclk(clock50), .waddr(address), .din(write_data), .write_en(write_strobe),
		.rclk(clock50), .raddr(address), .dout(read_data));
	assign leds[7] = ack;
	assign leds[6] = write_strobe;
	assign leds[5] = enable;
	assign leds[4] = register_select;
	assign leds[3] = read;
	assign leds[2] = 0;
	assign leds[1] = 0;
	assign leds[0] = reset50;
endmodule

module top_tb;
	localparam WIDTH = 7;
	reg clock50_p = 0;
	reg clock50_n = 1;
	wire lemo, other0, other1;
	wire [7:0] leds;
	reg pre_register_select = 0;
	reg register_select = 0;
	reg pre_read = 0;
	reg read = 0;
	reg [WIDTH-1:0] pre_bus = 0;
	wire [WIDTH-1:0] bus;
	reg pre_enable = 0;
	reg enable = 0;
	bus_entry_3state #(.WIDTH(WIDTH)) my3sbe (.I(pre_bus), .O(bus), .T(~read)); // we are master
	top mytop (
		.clock50_p(clock50_p), .clock50_n(clock50_n),
		.lemo(lemo), .other0(other0), .other1(other1),
		.bus(bus), .read(read), .register_select(register_select), .enable(enable), .ack(ack),
		.leds(leds)
	);
	task automatic a16_d32_master_write_transaction;
		input [15:0] address16;
		input [31:0] data32;
		begin
			#40;
			// write the address
			pre_register_select <= 0;
			pre_read <= 0;
			pre_bus <= address16[WIDTH-1:0];
			pre_enable <= 1;
			#40;
			pre_enable <= 0;
			#40;
			// write the first part of data
			pre_register_select <= 1;
			pre_read <= 0;
			pre_bus <= data32[WIDTH-1:0];
			pre_enable <= 1;
			#40;
			pre_enable <= 0;
			#40;
			// write the second part of data
			pre_register_select <= 1;
			pre_read <= 0;
			pre_bus <= data32[2*WIDTH-1:WIDTH];
			pre_enable <= 1;
			#40;
			pre_enable <= 0;
			#40;
		end
	endtask
	task automatic a16_master_read_transaction;
		input [15:0] address16;
		begin
			#40;
			// write the address
			pre_register_select <= 0;
			pre_read <= 0;
			pre_bus <= address16[WIDTH-1:0];
			pre_enable <= 1;
			#40;
			pre_enable <= 0;
			#40;
			// read data
			pre_read <= 1;
			pre_enable <= 1;
			#40;
			pre_enable <= 0;
			#40;
			pre_enable <= 1;
			#40;
			pre_enable <= 0;
			#40;
		end
	endtask
	initial begin
		#300;
		a16_d32_master_write_transaction(.address16(16'hab4c), .data32(32'h01232a12));
		a16_d32_master_write_transaction(.address16(16'hab4d), .data32(32'h01232b34));
		a16_d32_master_write_transaction(.address16(16'hab4e), .data32(32'h01232c56));
		a16_d32_master_write_transaction(.address16(16'hab4f), .data32(32'h01232d78));
		#100;
		a16_master_read_transaction(.address16(16'hab4c));
		a16_master_read_transaction(.address16(16'hab4d));
		a16_master_read_transaction(.address16(16'hab4e));
		a16_master_read_transaction(.address16(16'hab4f));
		#100;
		pre_read <= 0;
	end
	always @(posedge clock50_p) begin
		register_select <= pre_register_select;
		read <= pre_read;
		enable <= pre_enable;
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
	localparam WIDTH = 7;
	wire [WIDTH-1:0] bus = { d_n, d_p, a_p, c_n, a_n, b_n, c_p };
	wire [7:0] leds;
	wire ale = e_n;
	wire write = e_p;
	wire read = 0;
	wire ack;
//	assign _ = ack;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = leds;
	top #(.WIDTH(WIDTH)) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n),
		.lemo(lemo), .other0(b_p), .other1(f_p),
		.bus(bus), .ale(ale), .read(read), .ack(ack),
		.leds(leds)
	);
endmodule

