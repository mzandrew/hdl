// to run on an althea
//`define TESTBENCH;
//`define xilinx

// written 2020-05-13 by mza
// based on mza-test041.spi-pollable-memory.althea.v
// last updated 2020-05-23 by mza

`include "lib/spi.v"
`include "lib/RAM8.v"
`include "lib/serdes_pll.v"
`include "lib/dcm.v"
//`include "lib/synchronizer.v"

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
	output other0,
	output other1,
	input rpi_spi_sclk,
	input rpi_spi_mosi,
	output rpi_spi_miso,
	input rpi_spi_ce0,
	input rpi_spi_ce1,
	input rpi_gpio5, rpi_gpio6_gpclk2,
	input rpi_gpio13, rpi_gpio19,
	output led_0, led_1, led_2, led_3,
	output led_4, led_5, led_6, led_7
);
	wire global_reset = rpi_gpio19;
	wire clock50;
//	if (1) begin
		reg [7:0] reset_counter_alt = 0;
		reg reset1_clock_alt = 1;
		wire clock_alt;
		IBUFG mybuf0 (.I(rpi_gpio6_gpclk2), .O(clock_alt));
		always @(posedge clock_alt) begin
			if (global_reset) begin
				reset_counter_alt <= 0;
				reset1_clock_alt <= 1;
			end else if (reset1_clock_alt) begin
				if (reset_counter_alt[7]) begin
					reset1_clock_alt <= 0;
				end else begin
					reset_counter_alt <= reset_counter_alt + 1'b1;
				end
			end
		end
		wire pll_locked_alt;
		wire clock50_raw;
		simpledcm_CLKGEN #(.multiply(50), .divide(10), .period(100.0)) mydcm (.clockin(clock_alt), .reset(reset1_clock_alt), .clockout(clock50_raw), .clockout180(), .locked(pll_locked_alt)); // 50->125
		BUFG mybuf1 (.I(clock50_raw), .O(clock50));
		IBUFGDS mybuf2 (.I(clock50_p), .IB(clock50_n), .O());
//	end else begin
//		IBUFGDS mybuf3 (.I(clock50_p), .IB(clock50_n), .O(clock50));
//	end
	// ----------------------------------------------------------------------
	reg reset2_clock50 = 1;
	reg [7:0] reset_counter = 0;
	always @(posedge clock50) begin
		if (global_reset) begin
			reset2_clock50 <= 1;
			reset_counter <= 0;
		end else if (reset2_clock50) begin
			if (reset_counter[7]) begin
				reset2_clock50 <= 0;
			end else begin
				reset_counter <= reset_counter + 1'b1;
			end
		end
	end
	// ----------------------------------------------------------------------
	wire pll_locked;
	wire rawclock125;
	wire clock125;
	BUFG mrt (.I(rawclock125), .O(clock125));
	if (0) begin
		simplepll_BASE #(.overall_divide(1), .multiply(10), .divide0(4), .phase0(0.0), .period(20.0)) kronos (.clockin(clock50), .reset(reset2_clock50), .clock0out(rawclock125), .clock1out(), .clock2out(), .clock3out(), .clock4out(), .clock5out(), .locked(pll_locked)); // 50->125
	end else if (0) begin
		simpledcm_SP #(.multiply(10), .divide(4), .alt_clockout_divide(2), .period(20.0)) mydcm (.clockin(clock50), .reset(reset2_clock50), .clockout(rawclock125), .clockout180(), .alt_clockout(), .locked(pll_locked)); // 50->125
	end else begin
		simpledcm_CLKGEN #(.multiply(10), .divide(4), .period(20.0)) mydcm (.clockin(clock50), .reset(reset2_clock50), .clockout(rawclock125), .clockout180(), .locked(pll_locked)); // 50->125
	end
	// ----------------------------------------------------------------------
	reg reset3_clock125 = 1;
	always @(posedge clock125) begin
		if (global_reset) begin
			reset3_clock125 <= 1;
		end else if (reset3_clock125) begin
			if (pll_locked) begin
				reset3_clock125 <= 0;
			end
		end
	end
	wire word_clock;
	wire clock_spi;
	assign clock_spi = word_clock;
	wire [7:0] oserdes_word_out;
	wire pll_oserdes_locked;
	reg reset4_word_clock = 1;
	always @(posedge word_clock) begin
		if (global_reset) begin
			reset4_word_clock <= 1;
		end else if (reset4_word_clock) begin
			if (pll_oserdes_locked) begin
				reset4_word_clock <= 0;
			end
		end
	end
	// ----------------------------------------------------------------------
	reg sync_read_address = 0;
	reg [15:0] read_address = 0;
	wire [31:0] start_read_address;
	wire [31:0] end_read_address;
	reg [15:0] last_read_address = 16'd4095;
	// ----------------------------------------------------------------------
	wire [31:0] idelay_up_amount;
	wire [31:0] idelay_down_amount;
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
	RAM_inferred_with_register_outputs #(.addr_width(4), .data_width(32)) myram (.reset(reset4_word_clock),
		.wclk(clock_spi), .waddr(address4_ce0), .din(data32_ce0), .write_en(transaction_valid_ce0),
		.rclk(word_clock), .raddr(address4_ce0), .dout(read_data32_ce0),
		.register0(start_read_address), .register1(end_read_address), .register2(idelay_up_amount), .register3(idelay_down_amount));
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
	RAM_s6_512_32bit_8bit mem (.reset(reset4_word_clock),
		.clock_a(clock_spi), .address_a(address9), .data_in_a(data32_0123), .write_enable_a(transaction_valid_ce1), .data_out_a(read_data32_0123),
		.clock_b(word_clock), .address_b(read_address11), .data_out_b(oserdes_word_out));
`elsif USE_BRAM_4K
	wire [11:0] address12 = address16[11:0];
	wire [13:0] read_address14 = read_address[13:0];
	RAM_s6_4k_32bit_8bit mem (.reset(reset4_word_clock),
		.clock_a(clock_spi), .address_a(address12), .data_in_a(data32_0123), .write_enable_a(transaction_valid_ce1), .data_out_a(read_data32_0123),
		.clock_b(word_clock), .address_b(read_address14), .data_out_b(oserdes_word_out));
`endif
	// ----------------------------------------------------------------------
	reg sync_out_raw = 0;
	reg [3:0] sync_out_stream = 0;
	always @(posedge word_clock) begin
		sync_out_raw <= 0;
		if (reset4_word_clock) begin
			read_address <= start_read_address[17:2];
			last_read_address <= end_read_address[17:2] - 1'b1;
		end else begin
			if (read_address==last_read_address || sync_read_address) begin
				read_address <= start_read_address[17:2];
				last_read_address <= end_read_address[17:2] - 1'b1;
				sync_out_raw <= 1;
			end else begin
				read_address <= read_address + 1'b1;
			end
		end
		sync_out_stream <= { sync_out_stream[2:0], sync_out_raw };
	end
	wire bit_clock;
	wire bit_strobe;
	wire other1_raw;
	if (0) begin
		ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL")) mylei (.clock_in(clock125), .reset(reset3_clock125), .word_clock_out(word_clock), .word_in(oserdes_word_out), .D_out(lemo), .locked(pll_oserdes_locked));
		assign other0 = 0;
		assign other1 = sync_out_stream[2];
	end else if (0) begin
		wire pll_oserdes_locked_1;
		wire pll_oserdes_locked_2;
		ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL")) mylei0 (.clock_in(clock125), .reset(reset3_clock125), .word_clock_out(word_clock), .word_in(oserdes_word_out), .D_out(lemo), .locked(pll_oserdes_locked_1));
		wire word_clock_1;
		reg [7:0] oserdes_word_out_1 = 0;
		reg [7:0] oserdes_word_out_2 = 0;
		ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL")) mylei1 (.clock_in(clock125), .reset(reset3_clock125), .word_clock_out(word_clock_1), .word_in(oserdes_word_out_2), .D_out(other0), .locked(pll_oserdes_locked_2));
		always @(posedge word_clock_1) begin
			oserdes_word_out_1 <= oserdes_word_out;
			oserdes_word_out_2 <= oserdes_word_out_1;
		end
		assign other1 = sync_out_stream[2];
		assign pll_oserdes_locked = pll_oserdes_locked_1 && pll_oserdes_locked_2;
	end else begin
		ocyrus_double8 #(.BIT_DEPTH(8), .PERIOD(8.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL")) mylei2 (.clock_in(clock125), .reset(reset3_clock125), .word_clock_out(word_clock), .word0_in(oserdes_word_out), .word1_in(oserdes_word_out), .D0_out(other0), .D1_out(other1_raw), .locked(pll_oserdes_locked), .bit_clock(bit_clock), .bit_strobe(bit_strobe));
		assign lemo = sync_out_stream[2];
	end
	reg [31:0] idelay_counter = 0;
	reg inc_not_dec = 0;
	reg strobe = 0;
	reg [2:0] cnt = 0 ;
	always @(posedge word_clock) begin
		strobe <= 0;
		if (reset4_word_clock) begin
			idelay_counter <= 0;
		end else begin
			if (idelay_counter==32'h12345678) begin
				inc_not_dec <= 1;
				if (0!=idelay_up_amount) begin
					strobe <= 1;
					cnt <= cnt + 1'b1;
				//idelay_counter <= idelay_up_amount;
				end
			end else if (idelay_counter==32'h56781234) begin
				inc_not_dec <= 0;
				if (0!=idelay_down_amount) begin
					strobe <= 1;
				end
				//idelay_counter <= idelay_down_amount;
			end
			idelay_counter <= idelay_counter + 1'b1;
		end
	end
	if (0) begin
		odelay_fixed #(.AMOUNT(0)) twoturntables (.bit_in(other1_raw), .bit_out(other1)); // 1264 ps
	end else if (0) begin
		odelay_fixed #(.AMOUNT(255)) andamicrophone (.bit_in(other1_raw), .bit_out(other1)); // 3303 ps
	end else begin
		assign other1 = other1_raw; // 330 ps
	end
//	idelay nirvana (.clock(word_clock), .reset(reset4_word_clock), .inc_not_dec(inc_not_dec), .strobe(strobe), .bit_clock(bit_clock), .bit_in(), .bit_out(), .initiate_cal(1'b0), .busy());
	// ----------------------------------------------------------------------
	if (0) begin
		wire [7:0] leds;
		assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = leds;
		assign leds = oserdes_word_out;
	end else begin
		assign led_7 = reset1_clock_alt;
		assign led_6 = reset2_clock50;
		assign led_5 = reset3_clock125;
		assign led_4 = reset4_word_clock;
		assign led_3 = ~rpi_spi_ce0;
		assign led_2 = ~rpi_spi_ce1;
		assign led_1 = rpi_gpio13;
		assign led_0 = rpi_gpio19;
	end
endmodule

module mza_test042_spi_pollable_memories_and_oserdes_function_generator_althea_top (
	input clock50_p, clock50_n,
	output lemo, // oserdes/trig output
	input b_n, // rpi_spi_mosi
	output b_p, // oserdes/trig output other0
	output a_n, // rpi_spi_miso
	input a_p, // rpi_spi_cs1
	input c_n, // rpi_spi_cs0
	input c_p, // rpi_spi_sclk
	input d_n, // rpi_gpio5
	input d_p, // rpi_gpio6_gpclk2
	input e_n, // rpi_gpio13
	input e_p, // rpi_gpio19
	output f_p, // oserdes/trig output other1
	output led_0, led_1, led_2, led_3, led_4, led_5, led_6, led_7
);
	top mytop (
		.clock50_p(clock50_p), .clock50_n(clock50_n),
		.lemo(lemo),
		.other0(b_p),
		.other1(f_p),
		.rpi_spi_mosi(b_n), .rpi_spi_miso(a_n), .rpi_spi_sclk(c_p), .rpi_spi_ce0(c_n), .rpi_spi_ce1(a_p),
		.rpi_gpio5(d_n), .rpi_gpio6_gpclk2(d_p), .rpi_gpio13(e_n), .rpi_gpio19(e_p),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

