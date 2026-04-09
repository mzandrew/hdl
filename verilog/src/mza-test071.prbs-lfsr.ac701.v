`timescale 1ns / 1ps

// written 2025-03-04 by mza
// last updated 2025-03-21 by mza

// cd /opt/Xilinx/Vivado/2023.2/data/xicom/cable_drivers/lin64/install_script/install_drivers; sudo ./install_drivers

`include "lib/generic.v"
`include "lib/plldcm.v"
`include "lib/prbs.v"
`include "lib/serdes_pll.v"

module PRBS_LFSR #(
	parameter OSERDES_WIDTH = 8,
	parameter PRBSLFSR_WIDTH = OSERDES_WIDTH + OSERDES_WIDTH,
	parameter COUNTER_PICKOFF_RESET1 = 14,
	parameter COUNTER_PICKOFF_RESET2 = COUNTER_PICKOFF_RESET1 + 1,
	parameter COUNTER_PICKOFF_RESET3 = COUNTER_PICKOFF_RESET2 + 1,
	parameter COUNTER_PICKOFF_RESET4 = COUNTER_PICKOFF_RESET3 + 1
) (
	input SYSCLK_P, SYSCLK_N, // 200 MHz
	output USER_SMA_CLOCK_P, USER_SMA_CLOCK_N,
	output USER_SMA_GPIO_P, USER_SMA_GPIO_N,
	output GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0
);
	wire sysclk;
	IBUFDS iclk (.I(SYSCLK_P), .IB(SYSCLK_N), .O(sysclk));
	wire raw_bit_clock, bit_clock, word_clock, sysclk_pll_locked;
	reg reset1_sysclk = 1'b1, reset2_sysclk = 1'b1, reset3_sysclk = 1'b1, reset4_sysclk = 1'b1;
	reg reset2_copy1_on_raw_bit_clock = 1'b1, reset3_copy1_on_raw_bit_clock = 1'b1, reset4_copy1_on_word_clock = 1'b1;
	reg reset2_copy2_on_raw_bit_clock = 1'b1, reset3_copy2_on_raw_bit_clock = 1'b1, reset4_copy2_on_word_clock = 1'b1;
	reg [COUNTER_PICKOFF_RESET4:0] counter = 0;
	always @(posedge sysclk) begin
		counter <= counter + 1'b1;
		if (counter[COUNTER_PICKOFF_RESET1]) begin reset1_sysclk <= 0; end
		if (counter[COUNTER_PICKOFF_RESET2]) begin reset2_sysclk <= 0; end
		if (counter[COUNTER_PICKOFF_RESET3]) begin reset3_sysclk <= 0; end
		if (counter[COUNTER_PICKOFF_RESET4]) begin reset4_sysclk <= 0; end
	end
	always @(posedge raw_bit_clock) begin
		reset2_copy2_on_raw_bit_clock <= reset2_copy1_on_raw_bit_clock;
		reset2_copy1_on_raw_bit_clock <= reset2_sysclk;
		reset3_copy2_on_raw_bit_clock <= reset3_copy1_on_raw_bit_clock;
		reset3_copy1_on_raw_bit_clock <= reset3_sysclk;
	end
	always @(posedge word_clock) begin
		reset4_copy2_on_word_clock <= reset4_copy1_on_word_clock;
		reset4_copy1_on_word_clock <= reset4_sysclk;
	end
	MMCM_advanced #(
		.CLOCK1_PERIOD_NS(5.0), .D(4), .M(25), // Fvco = [600, 1440] MHz
		.CLKOUT0_DIVIDE(2), // 625 MHz (DDR yields 1250 MHz)
		.CLKOUT1_DIVIDE(1), //
		.CLKOUT2_DIVIDE(1), //
		.CLKOUT3_DIVIDE(1), //
		.CLKOUT4_DIVIDE(1), //
		.CLKOUT5_DIVIDE(1), //
		.CLKOUT6_DIVIDE(1)  //
			) mymmcm0 (
		.clock_in(sysclk), .reset(reset1_sysclk), .locked(sysclk_pll_locked),
		.clock0_out_p(raw_bit_clock), .clock0_out_n(), .clock1_out_p(), .clock1_out_n(),
		.clock2_out_p(), .clock2_out_n(), .clock3_out_p(), .clock3_out_n(),
		.clock4_out(), .clock5_out(), .clock6_out());
	if (0) begin
		reg [26:0] counter = 0;
		always @(posedge word_clock) begin
			counter <= counter + 1'b1;
		end
		OBUF blah_6 (.I(counter[0]), .O(USER_SMA_CLOCK_P));
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = counter[26:23];
		OBUF blah_p (.I(counter[2]), .O(USER_SMA_GPIO_P));
		OBUF blah_n (.I(counter[1]), .O(USER_SMA_GPIO_N));
	end else if (0) begin
		wire [PRBSLFSR_WIDTH-1:0] rand;
		prbs_wide #(.OUTPUT_WIDTH(PRBSLFSR_WIDTH)) pw (.clock(word_clock), .reset(reset4_copy2_on_word_clock), .rand(rand));
		OBUF blah_7 (.I(rand[7]), .O(USER_SMA_GPIO_P));
		OBUF blah_6 (.I(rand[6]), .O(USER_SMA_GPIO_N));
		OBUF blah_5 (.I(rand[5]), .O(USER_SMA_CLOCK_P));
		OBUF blah_4 (.I(rand[4]), .O(USER_SMA_CLOCK_N));
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = rand[3:0];
	end else if (1) begin
		BUFMRCE #(.CE_TYPE("ASYNC")) mr (.I(raw_bit_clock), .CE(~reset3_copy2_on_raw_bit_clock), .O(bit_clock));
		wire [PRBSLFSR_WIDTH-1:0] rand;
		prbs_wide #(.OUTPUT_WIDTH(PRBSLFSR_WIDTH)) pw (.clock(word_clock), .reset(reset4_copy2_on_word_clock), .rand(rand));
		wire word_clock_copy;
		BUFG wcc (.I(word_clock), .O(word_clock_copy));
		myoddr oddr_p (.clock(word_clock_copy), .out(USER_SMA_GPIO_P));
		myoddr oddr_n (.clock(word_clock_copy), .out(USER_SMA_GPIO_N));
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = rand[3:0];
		ocyrus_7series #(.DATA_WIDTH(OSERDES_WIDTH), .DDRSDR("DDR")) o7s_p (.bit_clock(bit_clock), .word_clock(word_clock), .reset(reset2_copy2_on_raw_bit_clock), .input_word(rand[7:0]), .output_bit(USER_SMA_CLOCK_P));
		ocyrus_7series #(.DATA_WIDTH(OSERDES_WIDTH), .DDRSDR("DDR")) o7s_n (.bit_clock(bit_clock), .word_clock(), .reset(reset2_copy2_on_raw_bit_clock), .input_word(rand[15:8]), .output_bit(USER_SMA_CLOCK_N));
	end else begin
		wire [31:0] rand32;
		prbs #(.WIDTH(32), .TAPA(28), .TAPB(31)) lfsr32 (.clock(clock), .reset(reset3), .word(rand32));
		assign { USER_SMA_GPIO_P, USER_SMA_GPIO_N, USER_SMA_CLOCK_P, USER_SMA_CLOCK_N, GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = rand32[7:0];
	end
endmodule

