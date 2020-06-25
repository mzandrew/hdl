// to run on an althea
//`define TESTBENCH;
//`define xilinx

// written 2020-05-13 by mza
// based on mza-test042.spi-pollable-memories-and-oserdes-function-generator.althea.v
// last updated 2020-06-25 by mza

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
	parameter WIDTH = 8,
	parameter TRANSACTIONS_PER_WORD = 2,
	parameter LOG2_OF_TRANSACTIONS_PER_WORD = $clog2(TRANSACTIONS_PER_WORD)
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
	output reg ack_valid = 0,
	output [7:0] leds
);
	reg checksum = 0;
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
	reg [1:0] wstate = 0;
	reg [LOG2_OF_TRANSACTIONS_PER_WORD-1:0] wword = TRANSACTIONS_PER_WORD-1; // most significant halfword first
	wire [TRANSACTIONS_PER_WORD*WIDTH-1:0] read_data_word;
	wire [WIDTH-1:0] read_data [TRANSACTIONS_PER_WORD-1:0];
	for (i=0; i<TRANSACTIONS_PER_WORD; i=i+1) begin : read_data_array
		assign read_data[i] = read_data_word[(i+1)*WIDTH-1:i*WIDTH];
	end
	reg [1:0] rstate = 0;
	reg [LOG2_OF_TRANSACTIONS_PER_WORD-1:0] rword = TRANSACTIONS_PER_WORD-1; // most significant halfword first
	reg [31:0] errors = 0;
	reg [WIDTH-1:0] pre_bus = 0;
	reg [0:0] astate = 0;
	localparam COUNTER50_BIT_PICKOFF = 3;
	reg [COUNTER50_BIT_PICKOFF:0] counter50 = 0;
	reg reset50 = 1;
	integer j;
	always @(posedge clock50) begin
		ack_valid <= 0;
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
			wword <= TRANSACTIONS_PER_WORD-1; // most significant halfword first
			rstate <= 0;
			rword <= TRANSACTIONS_PER_WORD-1; // most significant halfword first
			pre_bus <= 0;
			errors <= 0;
			checksum <= 0;
			astate <= 0;
		end else begin
			if (enable) begin
				ack_valid <= 1;
				if (read) begin // read mode
					if (rstate[1]==0) begin
						if (rstate[0]==0) begin
							rstate[0] <= 1;
							pre_bus <= read_data[rword];
						end
						if (rword==0) begin
							rstate[1] <= 1;
						end
					end
				end else begin // write mode
					if (register_select) begin
						if (wstate[1]==0) begin
							if (wstate[0]==0) begin
								wstate[0] <= 1;
								write_data[wword] <= bus;
							end
							if (wword==0) begin
								wstate[1] <= 1;
								write_strobe <= 1;
							end
						end
					end else begin // register_select=0
						if (astate[0]==0) begin
							astate[0] <= 1;
							address <= bus;
						end
					end
				end
			end else begin // enable=0
				if (wstate[1]) begin
					wstate <= 0;
					wword <= TRANSACTIONS_PER_WORD-1; // most significant halfword first
					//if (write_data_word==32'h31231507) begin
					if (write_data_word[15:0]==16'h1507) begin
						checksum <= 1;
					end else begin
						checksum <= 0;
					end
				end else if (wstate[0]) begin
					wstate[0] <= 0;
					wword <= wword - 1'b1;
				end
				if (rstate[1]) begin
					rstate <= 0;
					rword <= TRANSACTIONS_PER_WORD-1; // most significant halfword first
				end else if (rstate[0]) begin
					rstate[0] <= 0;
					rword <= rword - 1'b1;
				end
				if (astate[0]) begin
					astate[0] <= 0;
					if (wword!=TRANSACTIONS_PER_WORD-1) begin
						errors <= errors + 1'b1;
					end
					if (rword!=TRANSACTIONS_PER_WORD-1) begin
						errors <= errors + 1'b1;
					end
					wstate <= 0;
					wword <= TRANSACTIONS_PER_WORD-1; // most significant halfword first
					rstate <= 0;
					rword <= TRANSACTIONS_PER_WORD-1; // most significant halfword first
				end
			end
		end
	end
	bus_entry_3state #(.WIDTH(WIDTH)) my3sbe (.I(pre_bus), .O(bus), .T(read)); // we are slave
	assign bus = 'bz;
	RAM_inferred #(.addr_width(WIDTH), .data_width(TRANSACTIONS_PER_WORD*WIDTH)) myram (.reset(reset50),
		.wclk(clock50), .waddr(address), .din(write_data_word), .write_en(write_strobe),
		.rclk(clock50), .raddr(address), .dout(read_data_word));
	if (0) begin
		assign leds[7] = ack_valid;
		assign leds[6] = write_strobe;
		//assign leds[5] = checksum;
		assign leds[5] = |errors;
		assign leds[4] = reset;
		assign leds[3] = register_select;
		assign leds[2] = read;
		assign leds[1] = enable;
		assign leds[0] = reset50;
	end else begin
		//assign leds = address;
		//assign leds = write_data[1];
		assign leds = write_data[0];
	end
endmodule

module top_tb;
	localparam HALF_PERIOD_OF_MASTER = 1;
	localparam HALF_PERIOD_OF_SLAVE = 10;
	localparam NUMBER_OF_PERIODS_OF_MASTER_IN_A_DELAY = 1;
	localparam NUMBER_OF_PERIODS_OF_MASTER_WHILE_WAITING_FOR_ACK = 1000;
	reg clock = 0;
	localparam WIDTH = 8;
	localparam TRANSACTIONS_PER_WORD = 4;
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
	top #(.WIDTH(WIDTH), .TRANSACTIONS_PER_WORD(TRANSACTIONS_PER_WORD)) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10), .reset(reset),
		.lemo(lemo), .other0(other0), .other1(other1),
		.bus(bus), .register_select(register_select), .read(read), .enable(enable), .ack_valid(ack_valid),
		.leds(leds)
	);
	task automatic slave_clock_delay;
		input integer number_of_cycles;
		integer j;
		begin
			for (j=0; j<2*number_of_cycles; j=j+1) begin : delay_thing_s
				#HALF_PERIOD_OF_SLAVE;
			end
		end
	endtask
	task automatic master_clock_delay;
		input integer number_of_cycles;
		integer j;
		begin
			for (j=0; j<2*number_of_cycles; j=j+1) begin : delay_thing_m
				#HALF_PERIOD_OF_MASTER;
			end
		end
	endtask
	task automatic delay;
		master_clock_delay(NUMBER_OF_PERIODS_OF_MASTER_IN_A_DELAY);
	endtask
	task automatic pulse_enable;
		integer j;
		begin
			delay();
			pre_enable <= 1;
			for (j=0; j<2*NUMBER_OF_PERIODS_OF_MASTER_WHILE_WAITING_FOR_ACK; j=j+1) begin : delay_thing
				#HALF_PERIOD_OF_MASTER;
				if (ack_valid) begin
					pre_enable <= 0;
				end
			end
			if (pre_enable==1) begin
				//$display(“pre_enable is still 1”);
				$finish;
			end
		end
	endtask
	task automatic a16_d32_master_write_transaction;
		input [15:0] address16;
		input [31:0] data32;
		begin
			delay();
			// set the address
			pre_register_select <= 0;
			pre_read <= 0;
			pre_bus <= address16[WIDTH-1:0];
			pulse_enable();
			// write each part of data
			pre_register_select <= 1;
			pre_read <= 0;
			if (3<TRANSACTIONS_PER_WORD) begin
				pre_bus <= data32[4*WIDTH-1:3*WIDTH];
				pulse_enable();
			end
			if (2<TRANSACTIONS_PER_WORD) begin
				pre_bus <= data32[3*WIDTH-1:2*WIDTH];
				pulse_enable();
			end
			if (1<TRANSACTIONS_PER_WORD) begin
				pre_bus <= data32[2*WIDTH-1:WIDTH];
				pulse_enable();
			end
			pre_bus <= data32[WIDTH-1:0];
			pulse_enable();
		end
	endtask
	task automatic a16_master_read_transaction;
		input [15:0] address16;
		integer j;
		begin
			delay();
			// set the address
			pre_register_select <= 0;
			pre_read <= 0;
			pre_bus <= address16[WIDTH-1:0];
			pulse_enable();
			// read data
			pre_read <= 1;
			for (j=0; j<TRANSACTIONS_PER_WORD; j=j+1) begin : read_data_multiple_1
				pulse_enable();
			end
		end
	endtask
	task automatic master_readback_transaction;
		integer j;
		begin
			pre_read <= 1;
			for (j=0; j<TRANSACTIONS_PER_WORD; j=j+1) begin : read_data_multiple_2
				pulse_enable();
			end
			delay();
			pre_read <= 0;
		end
	endtask
	initial begin
		master_clock_delay(64);
		slave_clock_delay(64);
		a16_d32_master_write_transaction(.address16(16'hab4c), .data32(32'h3123_2a12));
		master_readback_transaction();
		a16_d32_master_write_transaction(.address16(16'hab4d), .data32(32'h3123_2b34));
		master_readback_transaction();
		a16_d32_master_write_transaction(.address16(16'hab4e), .data32(32'h3123_2c56));
		master_readback_transaction();
		a16_d32_master_write_transaction(.address16(16'hab4f), .data32(32'h3123_2d78));
		master_readback_transaction();
		master_clock_delay(64);
		slave_clock_delay(64);
		a16_master_read_transaction(.address16(16'hab4c));
		a16_master_read_transaction(.address16(16'hab4d));
		a16_master_read_transaction(.address16(16'hab4e));
		a16_master_read_transaction(.address16(16'hab4f));
		pre_read <= 0;
		master_clock_delay(64);
		slave_clock_delay(64);
		a16_d32_master_write_transaction(.address16(16'h1234), .data32(32'h3123_1507));
		a16_d32_master_write_transaction(.address16(16'h1234), .data32(32'h0000_1507));
		pre_register_select <= 0;
	end
	always @(posedge clock) begin
		register_select <= #1 pre_register_select;
		read <= #1 pre_read;
		enable <= #1 pre_enable;
	end
	always begin
		#HALF_PERIOD_OF_SLAVE;
		clock50_p <= ~clock50_p;
		clock50_n <= ~clock50_n;
	end
	always begin
		#HALF_PERIOD_OF_MASTER;
		clock <= ~clock;
	end
endmodule

module myalthea (
	input clock50_p, clock50_n,
	output lemo, // oserdes/trig output
	output b_p, // oserdes/trig output other0
	output f_p, // oserdes/trig output other1
	// other IOs:
	output m_p, // rpi_gpio2 sda
	output m_n, // rpi_gpio3 scl
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
	localparam TRANSACTIONS_PER_WORD = 2;
	wire register_select = e_n;
	assign m_n = register_select;
	wire read = l_p;
	wire enable = l_n;
	wire ack_valid;
	assign m_p = ack_valid;
	wire [7:0] leds;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = leds;
	//wire clock10 = j_p;
	wire clock10 = 0;
	top #(.WIDTH(WIDTH), .TRANSACTIONS_PER_WORD(TRANSACTIONS_PER_WORD)) althea (
		.clock50_p(clock50_p), .clock50_n(clock50_n), .clock10(clock10), .reset(e_p),
		.lemo(lemo), .other0(b_p), .other1(f_p),
		.bus({ c_p, b_n, a_n, c_n, a_p, d_p, d_n, j_p }), .register_select(register_select), .read(read), .enable(enable), .ack_valid(ack_valid),
		.leds(leds)
	);
endmodule

