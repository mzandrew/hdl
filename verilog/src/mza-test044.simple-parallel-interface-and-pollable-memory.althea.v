// to run on an althea
//`define TESTBENCH;
//`define xilinx

// written 2020-05-13 by mza
// based on mza-test042.spi-pollable-memories-and-oserdes-function-generator.althea.v
// last updated 2020-06-22 by mza

`define althea_revA
`include "lib/generic.v"
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
	parameter WIDTH = 7,
	parameter TRANSACTIONS_PER_WORD = 2
) (
	input clock50_p, clock50_n,
	input clock10,
	input reset,
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
	assign lemo = 0;
	assign other0 = 0;
	assign other1 = 0;
	wire clock50;
	IBUFGDS mybuf0 (.I(clock50_p), .IB(clock50_n), .O(clock50));
	reg write_strobe = 0;
	reg [WIDTH-1:0] address = 0;
	wire [TRANSACTIONS_PER_WORD*WIDTH-1:0] write_data_word;
	reg [WIDTH-1:0] write_data [TRANSACTIONS_PER_WORD-1:0];
	genvar i;
	for (i=0; i<TRANSACTIONS_PER_WORD; i=i+1) begin : write_data_array
		assign write_data_word[(i+1)*WIDTH-1:i*WIDTH] = write_data[i];
	end
	reg [2:0] wstate = 0;
	wire [TRANSACTIONS_PER_WORD*WIDTH-1:0] read_data_word;
	wire [WIDTH-1:0] read_data [TRANSACTIONS_PER_WORD-1:0];
	for (i=0; i<TRANSACTIONS_PER_WORD; i=i+1) begin : read_data_array
		assign read_data[i] = read_data_word[(i+1)*WIDTH-1:i*WIDTH];
	end
	reg [1:0] rstate = 0;
	reg [WIDTH-1:0] pre_bus = 0;
	localparam COUNTER50_BIT_PICKOFF = 3;
	reg [COUNTER50_BIT_PICKOFF:0] counter50 = 0;
	reg reset50 = 1;
	integer j;
	always @(posedge clock50) begin
		ack <= 0;
		write_strobe <= 0;
		if (reset) begin
			counter50 <= 0;
			reset50 <= 1;
		end else if (reset50) begin
			if (counter50[COUNTER50_BIT_PICKOFF]) begin
				reset50 <= 0;
			end
			counter50 <= counter50 + 1'b1;
			address <= 0;
			for (j=0; j<TRANSACTIONS_PER_WORD; j=j+1) begin : write_data_clear
				write_data[j] <= 0;
			end
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
							pre_bus <= read_data[1];
						end
					end else begin
						if (rstate[0]==0) begin
							rstate[0] <= 1;
							pre_bus <= read_data[0];
						end
					end
				end else begin // write mode
					if (register_select) begin
						if (wstate[2]==0) begin
							if (wstate[1]==0) begin
								if (wstate[0]==0) begin
									wstate[0] <= 1;
									write_data[1] <= bus; // most significant halfword first
								end
							end else begin
								if (wstate[0]==0) begin
									wstate <= 3'b101;
									write_data[0] <= bus;
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
		.wclk(clock50), .waddr(address), .din(write_data_word), .write_en(write_strobe),
		.rclk(clock50), .raddr(address), .dout(read_data_word));
	assign leds[7] = ack;
	assign leds[6] = write_strobe;
	assign leds[5] = 0;
	assign leds[4] = reset;
	assign leds[3] = register_select;
	assign leds[2] = read;
	assign leds[1] = enable;
	assign leds[0] = reset50;
endmodule

module top_tb;
	task automatic delay;
		#60;
	endtask
	localparam WIDTH = 8;
	reg clock50_p = 0;
	reg clock50_n = 1;
	reg clock10 = 0;
	reg reset = 0;
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
	top #(.WIDTH(WIDTH)) mytop (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10), .reset(reset),
		.lemo(lemo), .other0(other0), .other1(other1),
		.bus(bus), .register_select(register_select), .read(read), .enable(enable), .ack(ack),
		.leds(leds)
	);
	task automatic a16_d32_master_write_transaction;
		input [15:0] address16;
		input [31:0] data32;
		begin
			delay();
			// write the address
			pre_register_select <= 0;
			pre_read <= 0;
			pre_bus <= address16[WIDTH-1:0];
			pre_enable <= 1;
			delay();
			pre_enable <= 0;
			delay();
			// write the first part of data
			pre_register_select <= 1;
			pre_read <= 0;
			pre_bus <= data32[2*WIDTH-1:WIDTH];
			pre_enable <= 1;
			delay();
			pre_enable <= 0;
			delay();
			// write the second part of data
			pre_register_select <= 1;
			pre_read <= 0;
			pre_bus <= data32[WIDTH-1:0];
			pre_enable <= 1;
			delay();
			pre_enable <= 0;
			delay();
		end
	endtask
	task automatic a16_master_read_transaction;
		input [15:0] address16;
		begin
			delay();
			// write the address
			pre_register_select <= 0;
			pre_read <= 0;
			pre_bus <= address16[WIDTH-1:0];
			pre_enable <= 1;
			delay();
			pre_enable <= 0;
			delay();
			// read data
			pre_read <= 1;
			pre_enable <= 1;
			delay();
			pre_enable <= 0;
			delay();
			pre_enable <= 1;
			delay();
			pre_enable <= 0;
			delay();
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

module myalthea (
	input clock50_p, clock50_n,
	output lemo, // oserdes/trig output
	output b_p, // oserdes/trig output other0
	output f_p, // oserdes/trig output other1
	// other IOs:
	output m_p, // rpi_gpio2 sda
	input m_n, // rpi_gpio3 scl
	// 8 bit bus:
	inout j_p, // rpi_gpio4 gpclk0
	inout d_n, // rpi_gpio5
	inout d_p, // rpi_gpio6 gpclk2
	inout a_p, // rpi_gpio7 spi
	inout c_n, // rpi_gpio8 spi
	inout a_n, // rpi_gpio9 spi
	inout b_n, // rpi_gpio10 spi
	inout c_p, // rpi_gpio11 spi
	// other IOs:
	input e_n, // rpi_gpio13
	input l_p, // rpi_gpio14 tx
	input l_n, // rpi_gpio15 rd
	input e_p, // rpi_gpio19
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	localparam WIDTH = 8;
	wire register_select = e_n;
	wire read = l_p;
	wire enable = l_n;
	wire ack;
	assign m_p = ack;
	wire [7:0] leds;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = leds;
	//wire clock10 = j_p;
	wire clock10 = 0;
	top #(.WIDTH(WIDTH)) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10), .reset(e_p),
		.lemo(lemo), .other0(b_p), .other1(f_p),
		.bus({ j_p, d_n, d_p, a_p, c_n, a_n, b_n, c_p }), .register_select(register_select), .read(read), .enable(enable), .ack(ack),
		.leds(leds)
	);
endmodule

